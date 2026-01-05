extends PerkBase

var card
var value

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(_thisCard, _thisHand, otherCard):
	if otherCard.role.contains("Survivor"):
		card = otherCard
		
		card.get_node("AnimationPlayer").animation_started.connect(_when_animation_starts)
		
		value = int(card.get_node("value").text)
		value -= 4
		
		card.get_node("perk").text = "-4"
		card.get_node("AnimationPlayer").queue("showPerk")

func _when_animation_starts(name: String):
	if name == "showPerk":
		updateCardValue()

func updateCardValue():
	var label = card.get_node("value")
	var startValue = int(label.text)
	
	var tween = card.create_tween()
	
	tween.tween_method(
		func(val: int): label.text = str(val),
		startValue,
		value,
		0.5
	)
