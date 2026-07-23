extends MidRoundPerk

func calculate_perk_value(_thisCard, _thisHand, otherCard) -> int:
	var toAdd = 0
	
	if otherCard != null:
		if otherCard.role.contains("Aggressive"):
			toAdd = 1
	
	return toAdd

func apply_mid_perk(_thisCard, _thisHand, otherCard) -> Variant:
	if otherCard.role.contains("Aggressive"):
		otherCard.modify_value(-1)
		return [-1, "opponent"]
	
	return 0
