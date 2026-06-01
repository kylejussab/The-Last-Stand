extends PerkBase

func _init() -> void:
	timing = "calculationRound"

func apply_after_calculation_perk(thisCard, _thisHand, thisTotal, otherTotal):
	if otherTotal - thisTotal >= 2:
		thisCard.perkValueAtRoundEnd = 4
	
	return 0
