extends MidRoundPerk

func calculate_perk_value(_thisCard, _thisHand, otherCard) -> int:
	if otherCard != null:
		if otherCard.role.contains("Crafty") and otherCard.cardKey != "Ellie":
			return 1
	
	return 0
