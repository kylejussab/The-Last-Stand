extends OpponentAI
class_name OpponentAIBalanced

func _init():
	playstyleName = "Balanced"

func play_character_card(opponentHand, _playerHand):
	var characters: Array = []
	var supports: Array = []
	
	for card in opponentHand:
		if card.type == "Character":
			characters.append(card)
		elif card.type == "Support":
			supports.append(card)
			
	var bestCharacter = characters[0] if characters.size() > 0 else null
	var maxComboValue = -1
	
	for character in characters:
		var currentComboValue = character.value
		var bestSupportValue = 0
		
		for support in supports:
			if _is_matching_type(support, character):
				if support.value > bestSupportValue:
					bestSupportValue = support.value
					
		currentComboValue += bestSupportValue
		
		if currentComboValue > maxComboValue:
			maxComboValue = currentComboValue
			bestCharacter = character
	
	# 85% chance: play the character that sets up the best combo
	if randf() < 0.85:
		return bestCharacter
		
	# 30% chance: choose a random non-optimal character
	var others = characters.filter(func(c): return c != bestCharacter)
	
	if others.size() == 0:
		return bestCharacter
		
	return others[randi() % others.size()]

func choose_support_card(opponentHand, opponentCharacter, _playerCharacter):
	var bestSupport = null
	var highestValue = -1
	
	for support in opponentHand:
		if support.type == "Support" and support.canBePlayed:
			if _is_matching_type(support, opponentCharacter):
				if support.value > highestValue:
					highestValue = support.value
					bestSupport = support
				
	return bestSupport

func _is_matching_type(supportCard, characterCard) -> bool:
	var supportRoles = supportCard.role.split("/")
	var characterRoles = characterCard.role.split("/")
	
	for supportRole in supportRoles:
		for characterRole in characterRoles:
			if supportRole != "" and supportRole == characterRole:
				return true
				
	return false
