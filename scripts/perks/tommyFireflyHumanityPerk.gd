extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard) -> void:
	var fireflyCount: int = 0
	
	for ally in thisHand:
		if ally.faction == "Firefly":
			fireflyCount += 1
			
	if fireflyCount > 0:
		thisCard.modify_value(fireflyCount)

func would_perk_trigger(_thisCard, thisHand, _otherCard) -> bool:
	for ally in thisHand:
		if ally.faction == "Firefly":
			return true
			
	return false
