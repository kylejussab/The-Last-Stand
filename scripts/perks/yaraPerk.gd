extends EndRoundPerk

func _init() -> void:
	timing = "lateEndRound"

func calculate_end_perk_value(_thisCharacterCard, _thisSupportCard, otherCharacterCard, _otherSupportCard, _thisHand) -> int:
	if otherCharacterCard != null:
		
		if otherCharacterCard.value >= 8:
			return 3
			
	return 0
