extends PerkBase

func _init() -> void:
	timing = "calculationRound"

func apply_after_calculation_perk(thisCard, thisHand, thisTotal, otherTotal):
	if thisTotal > otherTotal:
		var updatedHand = []
	
		for item in thisHand:
			if item != thisCard and item.type == "Character":
				updatedHand.append(item)
		
		updatedHand.pick_random().modify_value(2)
		return [2, "a random in-hand card"]
	
	return 0
