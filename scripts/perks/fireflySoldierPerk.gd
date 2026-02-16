extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard):
	var isMarleneHere = false
	
	for marlene in thisHand:
		if marlene.cardKey == "Marlene":
			isMarleneHere = true
			break
	
	if isMarleneHere:
		thisCard.modify_value(6)
