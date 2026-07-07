extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, otherCard) -> int:
	var toAdd = 0
	
	for ally in thisHand:
		if ally.cardKey == "Ellie" or ally.cardKey == "Tommy" or ally.cardKey == "TommyFirefly":
			toAdd += 4
			break
	
	if otherCard != null:
		if otherCard.role.contains("/"):
			toAdd += 2
			
	return toAdd
