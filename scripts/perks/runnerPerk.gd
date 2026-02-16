extends PerkBase

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard):
	var runnerValueTotal = 0
	
	for runner in thisHand:
		if runner.cardKey == "Runner":
			runnerValueTotal += runner.value
	
	if runnerValueTotal != 0:
		thisCard.modify_value(runnerValueTotal)
