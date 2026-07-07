extends AfterCalculationPerk

func calculate_after_calculation_perk_value(_thisCard, _thisHand, thisTotal, otherTotal) -> int:
	if thisTotal > otherTotal:
		return 2
		
	return 0
