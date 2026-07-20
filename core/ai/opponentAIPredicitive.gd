extends OpponentAI
class_name OpponentAIPredictive

const MEMORY_LENGTH = 6
const RECENT_WEIGHT = 2.0
const RISKY_CARDS = ["Molotov", "TrapMine", "ShotgunShells", "SmokeBomb", "Brick", "Bottle"]
const DEFENSIVE_CARDS = ["Retreat", "Resilience"]

var playHistory: Array = []

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

func play_character_card(opponentHand, _playerHand, playerPlayedCard = null, _playerHealth = 99, _opponentHealth = 99):
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
		bestCharacter = _counter_card(characters, supports, opponentHand, playerPlayedCard)
	elif not deckPool.is_empty():
		var prediction = _predict_player_card(opponentHand)
		bestCharacter = _counter_card(characters, supports, opponentHand, prediction)
	else:
		bestCharacter = _play_balanced(characters, supports)
	
	if randf() < 0.92:
		return bestCharacter
	
	var others = characters.filter(func(c): return c != bestCharacter)
	if others.is_empty():
		return bestCharacter
	return others[randi() % others.size()]

func _get_live_pool(opponentHand: Array) -> Dictionary:
	var pool = deckPool.duplicate()
	
	for key in playerPlayedKeys:
		if pool.has(key):
			pool[key] -= 1
			if pool[key] <= 0:
				pool.erase(key)
	
	for key in opponentPlayedKeys:
		if pool.has(key):
			pool[key] -= 1
			if pool[key] <= 0:
				pool.erase(key)
	
	for card in opponentHand:
		if pool.has(card.cardKey):
			pool[card.cardKey] -= 1
			if pool[card.cardKey] <= 0:
				pool.erase(card.cardKey)
	
	return pool

func _predict_player_card(opponentHand: Array) -> PredictedCard:
	var livePool = _get_live_pool(opponentHand)
	
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
	
	var bestCardData = null
	var bestScore = -1.0
	
	for cardKey in livePool:
		if not Database.CHARACTERS.has(cardKey):
			continue
		
		var cardData = Database.CHARACTERS[cardKey]
		var faction = cardData[2]
		var role = cardData[3]
		
		var score = float(livePool[cardKey])
		
		if not factionWeights.is_empty():
			score *= (1.0 + factionWeights.get(faction, 0.0))
		
		if not roleWeights.is_empty():
			for r in role.split("/"):
				if r != "":
					score *= (1.0 + roleWeights.get(r, 0.0) * 0.5)
		
		if score > bestScore:
			bestScore = score
			bestCardData = cardData
	
	var prediction = PredictedCard.new()
	
	if bestCardData == null:
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
		var bestSupportScore = 0.0
		for support in supports:
			var score = float(support.value)
			if support.cardKey in RISKY_CARDS:
				score *= 0.6
			if score > bestSupportScore:
				bestSupportScore = score
		
		var comboValue = character.value + bestSupportScore
		if comboValue > maxComboValue:
			maxComboValue = comboValue
			bestCharacter = character
	
	return bestCharacter

func reset_elimination() -> void:
	playerPlayedKeys.clear()
	opponentPlayedKeys.clear()

func choose_support_card(opponent_hand, opponent_character, player_character, opponent_health = 99, _player_health = 99):
	var currentDiff = opponent_character.value - player_character.value
	
	var eligible = []
	for support in opponent_hand:
		if support.type == "Support" and support.canBePlayed:
			eligible.append(support)
	
	if eligible.is_empty():
		return null
	
	if currentDiff >= 4:
		return null
	
	if currentDiff <= -4 and opponent_health <= 25:
		for support in eligible:
			if support.cardKey in DEFENSIVE_CARDS:
				return support
	
	var bestSupport = null
	var bestBlendedScore = -INF
	
	for support in eligible:
		if support.cardKey in DEFENSIVE_CARDS:
			continue
		
		var ceiling = _calculate_max_support_value(support, opponent_character)
		
		var discounted = float(support.value)
		if support.cardKey in RISKY_CARDS:
			discounted *= 0.6
		
		var matchupWeight = 1.0
		if currentDiff < 0:
			matchupWeight = 1.2
		
		var blended = ((ceiling + discounted) / 2.0) * matchupWeight
		
		if blended > bestBlendedScore:
			bestBlendedScore = blended
			bestSupport = support
	
	if bestSupport == null or bestBlendedScore < 1.5:
		return null
	
	return bestSupport

func _calculate_max_support_value(support, character) -> float:
	match support.cardKey:
		"Silencer":
			var bonus = 2 if character.role.contains("Crafty") or character.role.contains("Defensive") else 0
			return support.value + bonus
		"Retreat":
			return 6
		"Resilience":
			return support.value + 3
		_:
			return support.value

class PredictedCard extends RefCounted:
	var faction: String = ""
	var role: String = ""
	var value: int = 0
	var type: String = "Character"
