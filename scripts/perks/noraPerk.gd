extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, _thisHand, otherCard):
	if otherCard.role.contains("Crafty") and otherCard.cardKey != "Ellie":
		thisCard.modify_value(1)
