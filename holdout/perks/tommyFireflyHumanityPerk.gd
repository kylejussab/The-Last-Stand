extends MidRoundPerk
func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:
	if forceTrigger:
		return 3
	var toAdd = 0
	for ally in thisHand:
		if ally.matches_faction("Firefly"):
			toAdd += 1
	return toAdd
