extends MidRoundPerk
func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:
	if forceTrigger:
		return 5
	var hasEllie: bool = false
	var hasStealthy: bool = false
	for ally in thisHand:
		if ally.is_named_companion("Ellie"):
			hasEllie = true
		if ally.role.contains("Stealthy") and ally.type == "Character":
			hasStealthy = true
	if hasEllie:
		return 3
	elif not hasStealthy:
		return 2
	return 0
