extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:
	var foundAggressiveCharacter: bool = false
	
	for ally in thisHand:
		if ally.type == "Character":
			if ally.role.contains("Aggressive"):
				foundAggressiveCharacter = true
				break
			
	if not foundAggressiveCharacter:
		return 3
	
	return 0
