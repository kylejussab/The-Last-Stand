extends MidRoundPerk

func calculate_perk_value(_thisCard, _thisHand, otherCard) -> int:
	if otherCard != null:
		if otherCard.faction == "Firefly":
			return 2
	
	return 0
