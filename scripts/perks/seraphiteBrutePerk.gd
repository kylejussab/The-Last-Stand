extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, _thisHand, otherCard) -> void:
	if otherCard.value <= 3:
		thisCard.modify_value(2)

func would_perk_trigger(_thisCard, _thisHand, otherCard) -> bool:
	if otherCard.value <= 3:
		return true
		
	return false
