extends PerkBase

func _init() -> void:
	timing = "calculationRound"

func apply_after_calculation_perk(_thisCard, thisHand, thisTotal, otherTotal):
	for lev in thisHand:
		if thisTotal > otherTotal:
			if lev.cardKey == "Lev":
				lev.modify_value(2)
				break
