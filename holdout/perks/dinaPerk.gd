extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, otherCard) -> int:
	var toAdd = 0
	
	if otherCard != null:
		if otherCard.role.contains("Defensive"):
			toAdd += 4
	
	for ally in thisHand:
		if ally.cardKey == "Ellie" or ally.cardKey == "Jessie":
			toAdd += 2
			break
	
	return toAdd
