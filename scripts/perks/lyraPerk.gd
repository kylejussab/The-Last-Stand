extends PerkBase

func _init() -> void:
	timing = "endRound"

func apply_end_perk(thisCharacterCard, _thisSupportCard, _otherCharacterCard, otherSupportCard, _thisHand):
	if otherSupportCard == null:
		thisCharacterCard.modify_value(2)

func would_perk_trigger(_thisCharacterCard, _thisSupportCard, _otherCharacterCard, otherSupportCard, _thisHand) -> bool:
	return otherSupportCard == null
