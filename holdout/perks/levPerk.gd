extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:
	var toAdd = 0
	
	var hasAlly: bool = false
	var hasSeraphite: bool = false
	
	for ally in thisHand:
		if ally.cardKey == "Yara" or ally.cardKey == "Abby":
			hasAlly = true
		if ally.faction == "Seraphite":
			hasSeraphite = true
			
	if hasAlly:
		toAdd += 5
	
	if not hasSeraphite:
		toAdd += 3
	
	return toAdd
