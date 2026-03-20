extends PerkBase

func _init() -> void:
	timing = "lateEndRound"

func apply_end_perk(thisCharacterCard, _thisSupportCard, otherCharacterCard, _otherSupportCard, _thisHand):
	if otherCharacterCard.value >= 8:
		thisCharacterCard.modify_value(3)

func would_perk_trigger(_thisCharacterCard, _thisSupportCard, otherCharacterCard, _otherSupportCard, _thisHand) -> bool:
	return otherCharacterCard.value >= 8
