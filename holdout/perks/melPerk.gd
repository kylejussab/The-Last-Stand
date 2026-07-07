extends AfterCalculationPerk

func calculate_after_calculation_perk_value(_thisCard, thisHand, thisTotal, otherTotal) -> int:
	if otherTotal > thisTotal:
		for card in thisHand:
			if card.type == "Character":
				return 2
	return 0

func apply_after_calculation_perk(thisCard, thisHand, thisTotal, otherTotal) -> Variant:
	if thisTotal > otherTotal:
		var updatedHand = []
	
		for item in thisHand:
			if item != thisCard and item.type == "Character":
				updatedHand.append(item)
		
		updatedHand.pick_random().modify_value(2)
		return [2, "a random in-hand card"]
	
	return 0
