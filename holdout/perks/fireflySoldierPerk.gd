extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:
	for marlene in thisHand:
		if marlene.cardKey == "Marlene":
			return 6
			
	return 0
