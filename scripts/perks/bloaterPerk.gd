extends PerkBase

var card
var value

func _init() -> void:
	timing = "calculationRound"


func apply_after_calculation_perk(thisCard, _thisHand, thisTotal, otherTotal):
	if otherTotal - thisTotal >= 2:
		card = thisCard
		card.perkValueAtRoundEnd = 4

func _when_animation_starts(name: String):
	if name == "showPerk":
		updateCardValue()

func updateCardValue():
	card.get_node("value").text = str(value)
