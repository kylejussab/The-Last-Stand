extends Node
var timing: String = "inHand"

func apply_in_hand_perk(thisSupportCard, _wonRound: bool) -> int:
	thisSupportCard.modify_value(1)
	return 1
