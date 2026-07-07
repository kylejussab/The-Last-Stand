extends OpponentAI
class_name OpponentAIMomentum

const MEMORY_LENGTH = 3

var recentResults: Array = []

func _init():
	playstyleName = "Momentum"

func record_round_result(won: bool) -> void:
	recentResults.append(won)
	if recentResults.size() > MEMORY_LENGTH:
		recentResults.pop_front()

func play_character_card(opponentHand, _playerHand, _playerPlayedCard = null):
	var characters: Array = []
	var supports: Array = []
	
	for card in opponentHand:
		if card.type == "Character":
			characters.append(card)
		elif card.type == "Support":
			supports.append(card)
	
	if characters.is_empty():
		return null
	
	var winStreak = recentResults.size() == MEMORY_LENGTH and recentResults.all(func(r): return r == true)
	var loseStreak = recentResults.size() == MEMORY_LENGTH and recentResults.all(func(r): return r == false)
	
	var bestCharacter: Node2D
	
	if winStreak:
		# On a roll — play aggressively to press the advantage
		bestCharacter = _play_aggressive(characters)
	elif loseStreak:
		# Struggling — play for the best combo to stabilise
		bestCharacter = _play_calculated(characters, supports, opponentHand)
	else:
		# Neutral — balanced is the safe default
		bestCharacter = _play_balanced(characters, supports)
	
	if randf() < 0.85:
		return bestCharacter
	
	var others = characters.filter(func(c): return c != bestCharacter)
	if others.is_empty():
		return bestCharacter
	return others[randi() % others.size()]

func _play_aggressive(characters: Array) -> Node2D:
	var best = characters[0]
	for character in characters:
		if character.value > best.value:
			best = character
	return best

func _play_balanced(characters: Array, supports: Array) -> Node2D:
	var bestCharacter = characters[0]
	var maxComboValue = -1
	
	for character in characters:
		var comboValue = character.value
		var bestSupportValue = 0
		for support in supports:
			if _is_matching_type(support, character) and support.value > bestSupportValue:
				bestSupportValue = support.value
		comboValue += bestSupportValue
		if comboValue > maxComboValue:
			maxComboValue = comboValue
			bestCharacter = character
	
	return bestCharacter

func _play_calculated(characters: Array, supports: Array, opponentHand: Array) -> Node2D:
	# On a lose streak, factor in perks as well as support combos
	# to find the highest possible theoretical value
	var bestCharacter = characters[0]
	var maxPotentialValue = -1

	for character in characters:
		var potentialValue = character.value
		
		var bestSupportValue = 0
		for support in supports:
			if _is_matching_type(support, character) and support.value > bestSupportValue:
				bestSupportValue = support.value
		potentialValue += bestSupportValue
		
		if character.perk != null:
			match character.perk.timing:
				"midRound":
					potentialValue += character.perk.calculate_perk_value(character, opponentHand, null)
				"endRound", "lateEndRound":
					var bestEndBonus = character.perk.calculate_end_perk_value(character, null, null, null, opponentHand)
					for support in supports:
						var bonus = character.perk.calculate_end_perk_value(character, support, null, null, opponentHand)
						if bonus > bestEndBonus:
							bestEndBonus = bonus
					potentialValue += bestEndBonus
				"calculationRound":
					potentialValue += character.perk.calculate_after_calculation_perk_value(character, opponentHand, 0, 1)
		
		if potentialValue > maxPotentialValue:
			maxPotentialValue = potentialValue
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

func choose_support_card(opponentHand, _opponentCharacter, _playerCharacter):
	var bestSupport = null
	var highestValue = -1
	for support in opponentHand:
		if support.type == "Support" and support.canBePlayed:
			if support.value > highestValue:
				highestValue = support.value
				bestSupport = support
	return bestSupport
