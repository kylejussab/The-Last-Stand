extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:	
	for buddy in thisHand:
		if buddy.cardKey == "Ellie" or buddy.cardKey == "Dina":
			return 3
	
	return 0
