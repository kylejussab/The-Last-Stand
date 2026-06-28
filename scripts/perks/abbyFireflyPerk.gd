extends MidRoundPerk

func calculate_perk_value(_thisCard, _thisHand, otherCard) -> int:
	if otherCard != null:
		if otherCard.value == 4:
			return 1
	return 0
