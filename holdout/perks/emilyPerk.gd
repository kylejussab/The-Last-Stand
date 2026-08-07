extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:
	var toAdd = 0
	
	for seraphite in thisHand:
		if seraphite.type == "Character" && seraphite.matches_faction("Seraphite"):
			toAdd += 1
			
	return toAdd
