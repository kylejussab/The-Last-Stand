extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, _thisHand, otherCard):
	if otherCard.role.contains("Aggressive") or otherCard.role.contains("Defensive"):
		var difference = otherCard.value - thisCard.value
		
		thisCard.modify_value(difference + 2)
