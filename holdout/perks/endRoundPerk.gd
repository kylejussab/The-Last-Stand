extends PerkBase
class_name EndRoundPerk

func _init() -> void:
	timing = "endRound"

func calculate_end_perk_value(_thisCharacterCard, _thisSupportCard, _otherCharacterCard, _otherSupportCard, _thisHand) -> int:
	return 0

func apply_end_perk(thisCharacterCard, thisSupportCard, otherCharacterCard, otherSupportCard, thisHand) -> int:
	var toAdd = calculate_end_perk_value(thisCharacterCard, thisSupportCard, otherCharacterCard, otherSupportCard, thisHand)
	if toAdd != 0:
		if thisCharacterCard.isDoctrineBackfired:
			otherCharacterCard.modify_value(toAdd)
		else:
			thisCharacterCard.modify_value(toAdd)
	return toAdd

func would_perk_trigger(thisCharacterCard, thisSupportCard, otherCharacterCard, otherSupportCard, thisHand) -> bool:
	return calculate_end_perk_value(thisCharacterCard, thisSupportCard, otherCharacterCard, otherSupportCard, thisHand) > 0
