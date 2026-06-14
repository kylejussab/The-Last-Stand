extends PerkBase

func _init() -> void:
	timing = "endRound"

func apply_end_perk(_thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, thisHand):
	if thisSupportCard && thisSupportCard.cardKey == "SupplyCache":
		var updatedHand = []
		
		for item in thisHand:
			if item != thisSupportCard and item.cardKey != "SupplyCache":
				updatedHand.append(item)
		
		updatedHand.pick_random().modify_value(2)
		return [2, "a random in-hand card"]
	
	return 0
