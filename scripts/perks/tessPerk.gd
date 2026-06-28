extends MidRoundPerk

func calculate_perk_value(_thisCard, thisHand, _otherCard) -> int:	
	for joel in thisHand:
		if joel.cardKey == "JoelSmuggler":
			return 6
			
	return 0

func apply_mid_perk(thisCard, thisHand, _otherCard):	
	for joel in thisHand:
		if joel.cardKey == "JoelSmuggler":
			thisCard.modify_value(4)
			joel.modify_value(2)
			
			return [[4, "self"], [2, "an in-hand card"]]
	
	return 0
