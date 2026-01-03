extends PerkBase

var card
var value

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard):
	thisCard.get_node("AnimationPlayer").animation_started.connect(_when_animation_starts)
	
	for ellie in thisHand:
		if ellie.cardKey == "Ellie":
			card = thisCard
			
			value = int(card.get_node("value").text)
			value += 4
			
			card.get_node("perk").text = "+4"
			card.get_node("AnimationPlayer").queue("showPerk")

func _when_animation_starts(name: String):
	if name == "showPerk":
		updateCardValue()

func updateCardValue():
	card.get_node("value").text = str(value)
