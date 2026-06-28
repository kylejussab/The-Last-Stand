extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:
	var toAdd = 0
	
	for infected in thisHand:
		if infected.type == "Character" && infected.faction == "Infected":
			toAdd += 2
			
	return toAdd
