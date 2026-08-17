extends MidRoundPerk
func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:
	if forceTrigger:
		return 3
	var toAdd = 0
	for firefly in thisHand:
		if firefly.type == "Character" && firefly.matches_faction("Firefly"):
			toAdd += 3
			break
	return toAdd
