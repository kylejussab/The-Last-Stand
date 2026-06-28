extends OpponentAI
class_name OpponentAICalculator

func _init():
	playstyleName = "Calculator"

func play_character_card(opponentHand, _playerHand):
	var characters: Array = []
	var supports: Array = []
	
	for card in opponentHand:
		if card.type == "Character":
			characters.append(card)
		elif card.type == "Support":
			supports.append(card)
			
	var bestCharacter = characters[0] if characters.size() > 0 else null
	var maxCalculatedValue = -1
	
	for character in characters:
		var potentialValue = character.value
		
		if character.perk != null:
			match character.perk.timing:
				"midRound":
					potentialValue += character.perk.calculate_perk_value(character, opponentHand, null)
					
				"endRound", "lateEndRound":
					var bestEndBonus = 0
					var noSupportBonus = character.perk.calculate_end_perk_value(character, null, null, null, opponentHand)
					if noSupportBonus > bestEndBonus:
						bestEndBonus = noSupportBonus
					for support in supports:
						var bonus = character.perk.calculate_end_perk_value(character, support, null, null, opponentHand)
						if bonus > bestEndBonus:
							bestEndBonus = bonus
					potentialValue += bestEndBonus
					
				"calculationRound":
					potentialValue += character.perk.calculate_after_calculation_perk_value(character, opponentHand, 0, 1)
					
		if potentialValue > maxCalculatedValue:
			maxCalculatedValue = potentialValue
			bestCharacter = character
			
	if randf() < 1.1:
		return bestCharacter
		
	var others = characters.filter(func(c): return c != bestCharacter)
	
	if others.size() == 0:
		return bestCharacter
		
	return others[randi() % others.size()]

func choose_support_card(opponentHand, _opponentCharacter, _playerCharacter):
	var bestSupport = null
	var highestValue = -1
	
	for support in opponentHand:
		if support.type == "Support" and support.canBePlayed:
			if support.value > highestValue:
				highestValue = support.value
				bestSupport = support
			
	return bestSupport
