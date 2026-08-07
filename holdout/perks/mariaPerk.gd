extends MidRoundPerk
func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:
	for ally in thisHand:
		if ally.is_named_companion("Tommy") or ally.is_named_companion("TommyFirefly") or ally.is_named_companion("TommyFireflyHumanity"):
			return 2
	
	return 0
