extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, otherCard) -> int:
	var toAdd = 0
	
	if otherCard != null:
		if otherCard.role.contains("Stealthy"):
			toAdd += 3
		
	for ally in thisHand:
		if ally.faction == "WLF":
			toAdd += 1
			
	return toAdd
