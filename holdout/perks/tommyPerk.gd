extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:
	var toAdd = 0
	
	for ally in thisHand:
		if ally.faction == "Jackson":
			toAdd += 1
			
	return toAdd
