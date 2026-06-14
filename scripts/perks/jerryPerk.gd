extends PerkBase

func _init() -> void:
	timing = "calculationRound"

func apply_after_calculation_perk(_thisCard, thisHand, thisTotal, otherTotal):
	if otherTotal > thisTotal:
		for firefly in thisHand:
			if firefly.type == "Character" && firefly.faction == "Firefly":
				firefly.modify_value(2)
				return [2, "an in-hand Firefly"]
	
	return 0
