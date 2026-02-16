extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard):	
	for ellie in thisHand:
		if ellie.cardKey == "Ellie":
			thisCard.modify_value(3)
