extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard) -> int:
	var isBuddyHere = false
	
	for buddy in thisHand:
		if buddy.cardKey == "Ellie" or buddy.cardKey == "Dina":
			isBuddyHere = true
			break
	
	if isBuddyHere:
		thisCard.modify_value(3)
		return 3
	
	return 0
