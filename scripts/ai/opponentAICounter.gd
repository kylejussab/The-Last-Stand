extends OpponentAI
class_name OpponentAICounter

func _init():
	playstyleName = "Counter"

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
		bestCharacter = _play_counter(characters, supports, opponentHand, playerPlayedCard)
	else:
		bestCharacter = _play_diverse(characters)
	
	if randf() < 1.1:
		return bestCharacter
	
	var others = characters.filter(func(c): return c != bestCharacter)
	if others.is_empty():
		return bestCharacter
	return others[randi() % others.size()]

func _play_counter(characters, supports, opponentHand, playerCard):
	var bestCharacter = characters[0]
	var maxCounterScore = -1
	
	for character in characters:
		var counterScore = character.value
		
		if character.perk != null:
			match character.perk.timing:
				"midRound":
					counterScore += character.perk.calculate_perk_value(character, opponentHand, playerCard)
				"endRound", "lateEndRound":
					var bestEndBonus = character.perk.calculate_end_perk_value(character, null, playerCard, null, opponentHand)
					for support in supports:
						var bonus = character.perk.calculate_end_perk_value(character, support, playerCard, null, opponentHand)
						if bonus > bestEndBonus:
							bestEndBonus = bonus
					counterScore += bestEndBonus
				"calculationRound":
					counterScore += character.perk.calculate_after_calculation_perk_value(character, opponentHand, 0, 1)
		
		if counterScore > maxCounterScore:
			maxCounterScore = counterScore
			bestCharacter = character
	
	return bestCharacter

func _play_diverse(characters):
	# Play the most "replaceable" card — the one that shares the most
	# faction/role coverage with remaining cards, preserving future counter options
	var bestCharacter = characters[0]
	var maxReplaceability = -1
	
	for character in characters:
		var replaceability = 0
		var characterRoles = character.role.split("/")
		
		for other in characters:
			if other == character:
				continue
			if other.faction == character.faction:
				replaceability += 1
			for role in characterRoles:
				if role in other.role.split("/"):
					replaceability += 1
		
		if replaceability > maxReplaceability:
			maxReplaceability = replaceability
			bestCharacter = character
	
	return bestCharacter

func choose_support_card(opponentHand, _opponentCharacter, _playerCharacter):
	var bestSupport = null
	var highestValue = -1
	
	for support in opponentHand:
		if support.type == "Support" and support.canBePlayed:
			if support.value > highestValue:
				highestValue = support.value
				bestSupport = support
	
	return bestSupport
