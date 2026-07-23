extends MidRoundPerk

func calculate_perk_value(_thisCard, _thisHand, otherCard) -> int:
	var toAdd = 0
	
	if otherCard != null:
		if otherCard.role.contains("Aggressive"):
			toAdd += 2
		
		if otherCard.type == "Character" and otherCard.faction == "Infected":
			toAdd += 1
			
	return toAdd
