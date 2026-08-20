extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, otherCard) -> int:
	var toAdd = 0
	
	for infected in thisHand:
		if infected.type == "Character" && infected.matches_faction("Infected"):
			toAdd += 1
	
	if otherCard != null:
		if otherCard.faction == "Infected":
			toAdd += 2
			
	return toAdd
