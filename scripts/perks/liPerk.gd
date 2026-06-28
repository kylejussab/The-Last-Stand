extends AfterCalculationPerk

func calculate_after_calculation_perk_value(_thisCard, thisHand, thisTotal, otherTotal) -> int:
	if otherTotal > thisTotal:
		for card in thisHand:
			if card.type == "Character":
				return 1
	return 0

func apply_after_calculation_perk(_thisCard, thisHand, thisTotal, otherTotal) -> Variant:
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
