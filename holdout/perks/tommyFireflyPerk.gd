extends MidRoundPerk
func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:
	if forceTrigger:
		return 3
	for firefly in thisHand:
		if firefly.type == "Character" && firefly.matches_faction("Firefly"):
			return 0
	return 3
