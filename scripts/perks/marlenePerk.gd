extends MidRoundPerk

func calculate_perk_value(_thisCard, _thisHand, otherCard) -> int:	
	if otherCard != null:
		if otherCard.role.contains("Survivor") or otherCard.role.contains("Stealthy"):
			return 1
	
	return 0
