extends Node
var timing: String = "inHand"

func apply_in_hand_perk(thisSupportCard, wonRound: bool) -> int:
	if wonRound:
		thisSupportCard.modify_value(1)
		return 1
	return 0
