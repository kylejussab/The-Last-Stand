extends PerkBase
class_name AfterCalculationPerk

func _init() -> void:
	timing = "calculationRound"

func calculate_after_calculation_perk_value(_thisCard, _thisHand, _thisTotal, _otherTotal) -> int:
	return 0

func apply_after_calculation_perk(thisCard, thisHand, thisTotal, otherTotal) -> Variant:
	var toAdd = calculate_after_calculation_perk_value(thisCard, thisHand, thisTotal, otherTotal)
	if toAdd != 0:
		thisCard.perkValueAtRoundEnd = toAdd
	return toAdd

func would_perk_trigger(thisCard, thisHand, thisTotal, otherTotal) -> bool:
	return calculate_after_calculation_perk_value(thisCard, thisHand, thisTotal, otherTotal) > 0
