extends PerkBase

var card
var value

func _init() -> void:
	timing = "calculationRound"


func apply_after_calculation_perk(thisCard, _thisHand, thisTotal, otherTotal):
	if thisTotal > otherTotal:
		card = thisCard
		card.perkValueAtRoundEnd = 2

func _when_animation_starts(name: String):
	if name == "showPerk":
		updateCardValue()

func updateCardValue():
	card.get_node("value").text = str(value)
