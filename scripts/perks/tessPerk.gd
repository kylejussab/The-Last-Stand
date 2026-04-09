extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard):	
	for joel in thisHand:
		if joel.cardKey == "JoelSmuggler":
			thisCard.modify_value(4)
			joel.modify_value(2)
			break
