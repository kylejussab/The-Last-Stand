extends Resource
class_name PerkBase

var timing : String = "mid_round"  # options: mid_round, end_round, support_play, round_start

func apply_mid_perk(_thisCard, _thisHand, _otherCard):
	# Overriden by child classes
	pass

func apply_end_perk(_thisCharacterCard, _thisSupportCard, _otherCharacterCard, _otherSupportCard, _thisHand):
	# Overriden by child classes
	pass

func apply_after_calculation_perk(_thisCard, _thisHand, _thisTotal, _otherTotal):
	# Overriden by child classes
	pass
