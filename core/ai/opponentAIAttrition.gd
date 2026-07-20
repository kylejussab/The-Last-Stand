extends OpponentAI
class_name OpponentAIAttrition

const MEMORY_LENGTH = 4
const DEFAULT_TARGET = 4
const RISKY_CARDS = ["Molotov", "TrapMine", "ShotgunShells", "SmokeBomb", "Brick", "Bottle"]
const DEFENSIVE_CARDS = ["Retreat", "Resilience"]

var playerValueHistory: Array = []

func _init():
	playstyleName = "Attrition"

func record_player_play(card) -> void:
	playerValueHistory.append(card.value)
	if playerValueHistory.size() > MEMORY_LENGTH:
		playerValueHistory.pop_front()

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
	
	var targetValue: int
	if playerPlayedCard != null:
		targetValue = playerPlayedCard.value
	else:
		targetValue = _estimate_player_value()
	
	var bestCharacter = _find_minimum_winning_card(characters, supports, targetValue)
	if randf() < 0.85:
		return bestCharacter
	
	var others = characters.filter(func(c): return c != bestCharacter)
	if others.is_empty():
		return bestCharacter
	return others[randi() % others.size()]

func _estimate_player_value() -> int:
	if playerValueHistory.is_empty():
		return DEFAULT_TARGET
	var total = 0
	for v in playerValueHistory:
		total += v
	return int(total / float(playerValueHistory.size()))

func _find_minimum_winning_card(characters: Array, supports: Array, targetValue: int) -> Node2D:
	var bestCharacter = characters[0]
	var bestMargin = INF
	var bestFallbackCharacter = characters[0]
	var bestFallbackValue = -1
	
	for character in characters:
		var bestComboValue = character.value
		for support in supports:
			var comboValue = character.value + support.value
			if comboValue > bestComboValue:
				bestComboValue = comboValue
		
		var margin = bestComboValue - targetValue
		
		if margin > 0 and margin < bestMargin:
			bestMargin = margin
			bestCharacter = character
		elif margin <= 0 and bestComboValue > bestFallbackValue:
			bestFallbackValue = bestComboValue
			bestFallbackCharacter = character
	
	if bestMargin == INF:
		return bestFallbackCharacter
	
	return bestCharacter

func choose_support_card(opponent_hand, opponent_character, player_character, _opponent_health = 99, _player_health = 99):
	var currentDiff = opponent_character.value - player_character.value
	
	var eligible = []
	for support in opponent_hand:
		if support.type == "Support" and support.canBePlayed:
			eligible.append(support)
	
	if eligible.is_empty():
		return null
	
	if currentDiff > 0:
		return null
	
	# Losing or tied: look for the smallest support that flips the round into a win, rather than the biggest one available.
	var candidates = []
	for support in eligible:
		if support.cardKey in DEFENSIVE_CARDS:
			continue
		
		var score = float(support.value)
		if support.cardKey in RISKY_CARDS:
			score *= 0.6 # crude guesswork discount
		
		var resultingMargin = currentDiff + score
		if resultingMargin > 0:
			candidates.append({"support": support, "margin": resultingMargin})
	
	if not candidates.is_empty():
		candidates.sort_custom(func(a, b): return a.margin < b.margin)
		return candidates[0].support
	
	# Can't flip it to a win: Attrition cares a lot about not taking damage
	for support in eligible:
		if support.cardKey == "Retreat":
			return support
	
	for support in eligible:
		if support.cardKey == "Resilience":
			return support
	
	return null
