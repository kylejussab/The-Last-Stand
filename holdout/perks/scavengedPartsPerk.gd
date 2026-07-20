extends Node
var timing: String = "onPlay"

func apply_on_play_perk(_thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, thisHand, _forceNoBackfire: bool = false) -> Dictionary:
	var eligible = []
	for card in thisHand:
		if is_instance_valid(card) and card.type == "Support" and card != thisSupportCard:
			eligible.append(card)
	
	if eligible.is_empty():
		return {"handled": false, "log": 0}
	
	var target = eligible[randi() % eligible.size()]
	target.modify_value(2)
	return {"handled": false, "log": [[2, "self"]]}
