extends MidRoundPerk
func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:
	for marlene in thisHand:
		if marlene.is_named_companion("Marlene"):
			return 6
			
	return 0
