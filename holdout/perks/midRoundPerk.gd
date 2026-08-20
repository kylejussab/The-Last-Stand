extends PerkBase
class_name MidRoundPerk

func _init() -> void:
	timing = "midRound"

func calculate_perk_value(_thisCard, _thisHand, _otherCard) -> int:
	return 0

func apply_mid_perk(thisCard, thisHand, otherCard) -> Variant:
	var toAdd = calculate_perk_value(thisCard, thisHand, otherCard)
	if toAdd != 0:
		if thisCard.isDoctrineBackfired:
			otherCard.modify_value(toAdd)
		else:
			thisCard.modify_value(toAdd)
	return toAdd

func would_perk_trigger(thisCard, thisHand, otherCard) -> bool:
	return calculate_perk_value(thisCard, thisHand, otherCard) > 0
