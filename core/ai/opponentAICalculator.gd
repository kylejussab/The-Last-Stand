extends OpponentAI
class_name OpponentAICalculator

func _init():
	playstyleName = "Calculator"

func play_character_card(opponentHand, _playerHand, _playerPlayedCard = null, _playerHealth = 99, _opponentHealth = 99):
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
			
	if randf() < 0.85:
		return bestCharacter
		
	var others = characters.filter(func(c): return c != bestCharacter)
	
	if others.size() == 0:
		return bestCharacter
		
	return others[randi() % others.size()]

func choose_support_card(opponent_hand, opponent_character, _player_character, _opponent_health = 99, _player_health = 99):
	var eligible = []
	for support in opponent_hand:
		if support.type == "Support" and support.canBePlayed:
			eligible.append(support)
	
	if eligible.is_empty():
		return null
	
	var bestSupport = null
	var bestTheoreticalValue = -1
	
	for support in eligible:
		var theoreticalValue = _calculate_max_support_value(support, opponent_character)
		
		if theoreticalValue > bestTheoreticalValue:
			bestTheoreticalValue = theoreticalValue
			bestSupport = support
	
	return bestSupport

func _calculate_max_support_value(support, character) -> float:
	match support.cardKey:
		"Silencer":
			var bonus = 2 if character.role.contains("Crafty") or character.role.contains("Defensive") else 0
			return support.value + bonus
		
		"Retreat":
			# Theoretical ceiling here is "all damage taken this round," which
			# Calculator can't actually know in advance — treat as a flat, generous assumption
			return 6
		
		"Resilience":
			return support.value + 3 # assumes it'll matter on a meaningful loss
		
		_:
			return support.value
