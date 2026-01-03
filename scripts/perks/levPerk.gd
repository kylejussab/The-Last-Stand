extends PerkBase

var card
var value

func _init() -> void:
	timing = "calculationRound"

func apply_after_calculation_perk(thisCard, _thisHand, thisTotal, otherTotal):
	if thisTotal == otherTotal:
		card = thisCard
		
		card.get_node("AnimationPlayer").animation_started.connect(_when_animation_starts)
		
		value = int(card.get_node("value").text)
		value += 5
		
		card.get_node("perk").text = "+5"
		card.get_node("AnimationPlayer").queue("showPerk")
		
		card.perkValueAtRoundEnd = 5

func _when_animation_starts(name: String):
	if name == "showPerk":
		updateCardValue()

func updateCardValue():
	card.get_node("value").text = str(value)
