extends MidRoundPerk

func calculate_perk_value(_thisCard, _thisHand, otherCard) -> int:	
	if otherCard != null:
		if otherCard.role.contains("Aggressive") or otherCard.role.contains("Defensive") or otherCard.role.contains("Survivor"):
			return 2
			
	return 0
