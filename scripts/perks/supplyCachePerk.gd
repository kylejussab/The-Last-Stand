extends PerkBase

var card
var value

func _init() -> void:
	timing = "endRound"

func apply_end_perk(_thisCharacterCard, thisSupportCard, _otherCharacterCard, _otherSupportCard, thisHand):
	if thisSupportCard && thisSupportCard.cardKey == "SupplyCache":
		card = thisHand[randi() % thisHand.size()]
		
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
