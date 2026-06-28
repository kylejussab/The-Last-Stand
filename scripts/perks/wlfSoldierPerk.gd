extends MidRoundPerk

func calculate_perk_value(_thisCard, _thisHand, otherCard) -> int:
	if otherCard != null:
		if otherCard.role.contains("Survivor"):
			return 3
			
	return 0

func apply_mid_perk(_thisCard, _thisHand, otherCard):
	if otherCard.role.contains("Survivor"):
		otherCard.modify_value(-3)
		return [-3, "opponent"]
	
	return 0
