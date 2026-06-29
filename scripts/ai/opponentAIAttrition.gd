extends OpponentAI
class_name OpponentAIAttrition

const MEMORY_LENGTH = 4
const DEFAULT_TARGET = 4

var playerValueHistory: Array = []

func _init():
	playstyleName = "Attrition"

func record_player_play(card) -> void:
	playerValueHistory.append(card.value)
	if playerValueHistory.size() > MEMORY_LENGTH:
		playerValueHistory.pop_front()

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
		# Find the best support combo available for this character
		var bestComboValue = character.value
		for support in supports:
			if _is_matching_type(support, character):
				var comboValue = character.value + support.value
				if comboValue > bestComboValue:
					bestComboValue = comboValue
		
		var margin = bestComboValue - targetValue
		
		if margin > 0 and margin < bestMargin:
			# Wins by less than current best — this is preferred
			bestMargin = margin
			bestCharacter = character
		elif margin <= 0 and bestComboValue > bestFallbackValue:
			# Can't win — track highest value as fallback
			bestFallbackValue = bestComboValue
			bestFallbackCharacter = character
	
	# If nothing beats the target, play the highest available rather than
	# wasting a minimum-margin card on a losing round
	if bestMargin == INF:
		return bestFallbackCharacter
	
	return bestCharacter

func _is_matching_type(supportCard, characterCard) -> bool:
	var supportRoles = supportCard.role.split("/")
	var characterRoles = characterCard.role.split("/")
	for supportRole in supportRoles:
		for characterRole in characterRoles:
			if supportRole != "" and supportRole == characterRole:
				return true
	return false

func choose_support_card(opponentHand, _opponentCharacter, _playerCharacter):
	var bestSupport = null
	var highestValue = -1
	for support in opponentHand:
		if support.type == "Support" and support.canBePlayed:
			if support.value > highestValue:
				highestValue = support.value
				bestSupport = support
	return bestSupport
