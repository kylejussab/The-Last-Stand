extends PerkBase

func _init() -> void:
	timing = "endRound"

func apply_end_perk(thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, _thisHand):
	if thisSupportCard and (thisSupportCard.cardKey == "Brick" or thisSupportCard.cardKey == "Bottle"):
		thisCharacterCard.modify_value(4)
