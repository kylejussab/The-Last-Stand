extends AfterCalculationPerk

func calculate_after_calculation_perk_value(_thisCard, _thisHand, thisTotal, otherTotal) -> int:
	if otherTotal - thisTotal >= 2:
		return 4
		
	return 0

func apply_after_calculation_perk(thisCard, _thisHand, thisTotal, otherTotal):
	if otherTotal - thisTotal >= 2:
		thisCard.perkValueAtRoundEnd = 4
	
	return 0
