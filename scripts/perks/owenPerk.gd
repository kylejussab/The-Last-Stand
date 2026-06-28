extends AfterCalculationPerk

func calculate_after_calculation_perk_value(_thisCard, _thisHand, thisTotal, otherTotal) -> int:
	if thisTotal < otherTotal:
		return 1  # tells the gameplaying AIs that this perk has value in this situation
	return 0

func apply_after_calculation_perk(_thisCard, _thisHand, _thisTotal, _otherTotal) -> int:
	return 0
