extends PerkBase

func _init() -> void:
	timing = "calculationRound"

func apply_after_calculation_perk(thisCard, _thisHand, thisTotal, otherTotal):
	if thisTotal == otherTotal:
		thisCard.modify_value(5)
