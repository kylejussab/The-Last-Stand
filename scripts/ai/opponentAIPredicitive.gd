extends OpponentAI
class_name OpponentAIPredictive

const MEMORY_LENGTH = 6
const RECENT_WEIGHT = 2.0

# Pattern learning — limited memory
var playHistory: Array = []

# Elimination tracking — full memory, never truncated
var deckPool: Dictionary = {}
var playerPlayedKeys: Array = []
var opponentPlayedKeys: Array = []

func _init():
	playstyleName = "Predictive"

func initialize_deck(deck: Array) -> void:
	deckPool.clear()
	playerPlayedKeys.clear()
	opponentPlayedKeys.clear()
	playHistory.clear()
	
	for cardKey in deck:
		if not deckPool.has(cardKey):
			deckPool[cardKey] = 0
		deckPool[cardKey] += 1

func record_player_play(card) -> void:
	playerPlayedKeys.append(card.cardKey)
	
	playHistory.append({
		"cardKey": card.cardKey,
		"faction": card.faction,
		"role": card.role,
		"value": card.value
	})
	if playHistory.size() > MEMORY_LENGTH:
		playHistory.pop_front()

func record_opponent_play(card) -> void:
	opponentPlayedKeys.append(card.cardKey)

func play_character_card(opponentHand, _playerHand, playerPlayedCard = null):
	var characters: Array = []
	var supports: Array = []
	
	for card in opponentHand:
		if card.type == "Character":
			characters.append(card)
		elif card.type == "Support":
			supports.append(card)
	
	if characters.is_empty():
		return null
	
	var bestCharacter: Node2D
	
	if playerPlayedCard != null:
		# Playing second — counter the real card directly, no prediction needed
		bestCharacter = _counter_card(characters, supports, opponentHand, playerPlayedCard)
	elif not deckPool.is_empty():
		# Playing first — predict from live pool weighted by pattern history
		var prediction = _predict_player_card(opponentHand)
		bestCharacter = _counter_card(characters, supports, opponentHand, prediction)
	else:
		# No deck knowledge yet fall back to balanced
		bestCharacter = _play_balanced(characters, supports)
	
	if randf() < 0.92:
		return bestCharacter
	
	var others = characters.filter(func(c): return c != bestCharacter)
	if others.is_empty():
		return bestCharacter
	return others[randi() % others.size()]

func _get_live_pool(opponentHand: Array) -> Dictionary:
	var pool = deckPool.duplicate()
	
	# Remove every card the player has played — definitively gone
	for key in playerPlayedKeys:
		if pool.has(key):
			pool[key] -= 1
			if pool[key] <= 0:
				pool.erase(key)
	
	# Remove every card the opponent has played — also gone
	for key in opponentPlayedKeys:
		if pool.has(key):
			pool[key] -= 1
			if pool[key] <= 0:
				pool.erase(key)
	
	# Remove cards currently in the opponent's hand —
	# these can't simultaneously be in the player's hand
	for card in opponentHand:
		if pool.has(card.cardKey):
			pool[card.cardKey] -= 1
			if pool[card.cardKey] <= 0:
				pool.erase(card.cardKey)
	
	return pool

func _predict_player_card(opponentHand: Array) -> PredictedCard:
	var livePool = _get_live_pool(opponentHand)
	
	# Build pattern weights from limited play history
	var factionWeights: Dictionary = {}
	var roleWeights: Dictionary = {}
	
	for i in range(playHistory.size()):
		var weight = 1.0 + (float(i) / float(playHistory.size())) * (RECENT_WEIGHT - 1.0)
		var entry = playHistory[i]
		
		if not factionWeights.has(entry["faction"]):
			factionWeights[entry["faction"]] = 0.0
		factionWeights[entry["faction"]] += weight
		
		for role in entry["role"].split("/"):
			if role != "":
				if not roleWeights.has(role):
					roleWeights[role] = 0.0
				roleWeights[role] += weight
	
	# Score every card still plausibly in the player's hand
	var bestCardData = null
	var bestScore = -1.0
	
	for cardKey in livePool:
		if not Database.CHARACTERS.has(cardKey):
			continue
		
		var cardData = Database.CHARACTERS[cardKey]
		var faction = cardData[2]
		var role = cardData[3]
		
		# Base score: how many copies remain — more copies means more likely
		var score = float(livePool[cardKey])
		
		# Multiply by faction affinity from pattern history
		if not factionWeights.is_empty():
			score *= (1.0 + factionWeights.get(faction, 0.0))
		
		# Multiply by role affinity — roles weighted at half to avoid over-fitting
		if not roleWeights.is_empty():
			for r in role.split("/"):
				if r != "":
					score *= (1.0 + roleWeights.get(r, 0.0) * 0.5)
		
		if score > bestScore:
			bestScore = score
			bestCardData = cardData
	
	var prediction = PredictedCard.new()
	
	if bestCardData == null:
		# Pool exhausted or lookup failed — predict a generic mid-value card
		prediction.faction = ""
		prediction.role = ""
		prediction.value = 4
	else:
		prediction.faction = bestCardData[2]
		prediction.role = bestCardData[3]
		prediction.value = bestCardData[0]
	
	return prediction

func _counter_card(characters, supports, opponentHand, targetCard):
	var bestCharacter = characters[0]
	var maxCounterScore = -1
	
	for character in characters:
		var counterScore = character.value
		
		if character.perk != null:
			match character.perk.timing:
				"midRound":
					counterScore += character.perk.calculate_perk_value(character, opponentHand, targetCard)
				"endRound", "lateEndRound":
					var bestEndBonus = character.perk.calculate_end_perk_value(character, null, targetCard, null, opponentHand)
					for support in supports:
						var bonus = character.perk.calculate_end_perk_value(character, support, targetCard, null, opponentHand)
						if bonus > bestEndBonus:
							bestEndBonus = bonus
					counterScore += bestEndBonus
				"calculationRound":
					counterScore += character.perk.calculate_after_calculation_perk_value(character, opponentHand, 0, 1)
		
		if counterScore > maxCounterScore:
			maxCounterScore = counterScore
			bestCharacter = character
	
	return bestCharacter

func _play_balanced(characters, supports):
	var bestCharacter = characters[0]
	var maxComboValue = -1
	
	for character in characters:
		var comboValue = character.value
		var bestSupportValue = 0
		
		for support in supports:
			if _is_matching_type(support, character):
				if support.value > bestSupportValue:
					bestSupportValue = support.value
		
		comboValue += bestSupportValue
		
		if comboValue > maxComboValue:
			maxComboValue = comboValue
			bestCharacter = character
	
	return bestCharacter

func _is_matching_type(supportCard, characterCard) -> bool:
	var supportRoles = supportCard.role.split("/")
	var characterRoles = characterCard.role.split("/")
	
	for supportRole in supportRoles:
		for characterRole in characterRoles:
			if supportRole != "" and supportRole == characterRole:
				return true
	return false

func reset_elimination() -> void:
	playerPlayedKeys.clear()
	opponentPlayedKeys.clear()

func choose_support_card(opponentHand, _opponentCharacter, _playerCharacter):
	var bestSupport = null
	var highestValue = -1
	
	for support in opponentHand:
		if support.type == "Support" and support.canBePlayed:
			if support.value > highestValue:
				highestValue = support.value
				bestSupport = support
	
	return bestSupport

class PredictedCard extends RefCounted:
	var faction: String = ""
	var role: String = ""
	var value: int = 0
	var type: String = "Character"
	
