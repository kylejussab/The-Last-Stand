extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, otherCard) -> int:
	var toAdd = 0
	
	if otherCard != null:
		if otherCard.faction == "Infected":
			toAdd += 3
	
	for ally in thisHand:
		if ally.matches_faction("WLF"):
			toAdd += 1
	
	return toAdd
