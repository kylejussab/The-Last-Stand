extends AfterCalculationPerk

func calculate_after_calculation_perk_value(_thisCard, _thisHand, thisTotal, otherTotal) -> int:
	if thisTotal > otherTotal:
		return 4
		
	return 0
