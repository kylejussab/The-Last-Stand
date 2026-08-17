extends AfterCalculationPerk
func calculate_after_calculation_perk_value(_thisCard, thisHand, thisTotal, otherTotal) -> int:
	if forceTrigger:
		for firefly in thisHand:
			if firefly.type == "Character" && firefly.faction == "Firefly":
				return 2
		return 0
	if otherTotal > thisTotal:
		for firefly in thisHand:
			if firefly.type == "Character" && firefly.faction == "Firefly":
				return 2
	return 0
func apply_after_calculation_perk(_thisCard, thisHand, thisTotal, otherTotal) -> Variant:
	if forceTrigger:
		for firefly in thisHand:
			if firefly.type == "Character" && firefly.faction == "Firefly":
				firefly.modify_value(2)
				return [2, "an in-hand Firefly"]
		return 0
	if otherTotal > thisTotal:
		for firefly in thisHand:
			if firefly.type == "Character" && firefly.faction == "Firefly":
				firefly.modify_value(2)
				return [2, "an in-hand Firefly"]
	return 0
