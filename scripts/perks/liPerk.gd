extends PerkBase

func _init() -> void:
	timing = "calculationRound"

func apply_after_calculation_perk(_thisCard, thisHand, thisTotal, otherTotal):
	if otherTotal > thisTotal:
		var characters = []
		
		for card in thisHand:
			if card.type == "Character":
				characters.append(card)
		
		if characters.size() > 0:
			var target = characters.pick_random()
			target.modify_value(1)
			return [1, "a random in-hand card"]
	
	return 0

func would_perk_trigger(_thisCard, _thisHand, thisTotal, otherTotal) -> bool:
	return otherTotal > thisTotal
