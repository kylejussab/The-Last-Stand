extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard) -> int:
	for ally in thisHand:
		if ally.cardKey == "Tommy" or ally.cardKey == "TommyFirefly" or ally.cardKey == "TommyFireflyHumanity":
			thisCard.modify_value(2)
			return 2
	
	return 0

func would_perk_trigger(_thisCard, thisHand, _otherCard) -> bool:
	for ally in thisHand:
		if ally.cardKey == "Tommy" or ally.cardKey == "TommyFirefly" or ally.cardKey == "TommyFireflyHumanity":
			return true
			
	return false
