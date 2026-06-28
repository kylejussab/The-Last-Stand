extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:
	var toAdd = 0
	
	for firefly in thisHand:
		if firefly.type == "Character" && firefly.faction == "Firefly":
			toAdd += 1
			break
			
	return toAdd
