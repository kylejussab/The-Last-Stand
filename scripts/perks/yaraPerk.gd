extends PerkBase

var card
var value

func _init() -> void:
	timing = "calculationRound"


func apply_after_calculation_perk(_thisCard, thisHand, thisTotal, otherTotal):
	for lev in thisHand:
		if thisTotal > otherTotal:
			if lev.cardKey == "LevRare":
				card = lev
				
				card.get_node("AnimationPlayer").animation_started.connect(_when_animation_starts)
				
				value = int(card.get_node("value").text)
				value += 2
				
				card.get_node("perk").text = "+2"
				card.get_node("AnimationPlayer").queue("showPerk")

func _when_animation_starts(name: String):
	if name == "showPerk":
		updateCardValue()

func updateCardValue():
	card.get_node("value").text = str(value)
