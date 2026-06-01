extends PerkBase

func _init() -> void:
	timing = "endRound"

func apply_end_perk(thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, _thisHand) -> int:
	if thisSupportCard and thisSupportCard.cardKey == "TrapMine":
		thisCharacterCard.modify_value(4)
		return 4
	return 0
