extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, otherCard) -> int:
	var toAdd = 0
	
	for ally in thisHand:
		if ally.role.contains("Stealthy") and ally.type == "Character":
			toAdd += 1
	
	if otherCard != null:
		if otherCard.type == "Character":
			if otherCard.role.contains("Aggressive") or otherCard.role.contains("Stealthy"):
				toAdd += 2
			
	return toAdd
