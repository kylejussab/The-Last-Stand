extends PerkBase

func _init() -> void:
	timing = "calculationRound"

func apply_after_calculation_perk(_thisCard, _thisHand, thisTotal, otherTotal):
	if thisTotal < otherTotal:
		pass # Handled by battle manager, perk involves mitigating overall damage
