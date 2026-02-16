extends PerkBase

func _init() -> void:
	timing = "endRound"

func apply_end_perk(thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, thisHand):
	if thisSupportCard && thisSupportCard.cardKey == "SupplyCache":
		var updatedHand = []
		
		for item in thisHand:
			if item != thisSupportCard and item != thisCharacterCard:
				updatedHand.append(item)
		
		updatedHand.pick_random().modify_value(2)
