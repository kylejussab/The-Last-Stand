extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard) -> int:
	var jacksonCount: int = 0
	
	for ally in thisHand:
		if ally.faction == "Jackson":
			jacksonCount += 1
			
	if jacksonCount > 0:
		thisCard.modify_value(jacksonCount)
	
	return jacksonCount

func would_perk_trigger(_thisCard, thisHand, _otherCard) -> bool:
	for ally in thisHand:
		if ally.faction == "Jackson":
			return true
			
	return false
