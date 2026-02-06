extends PerkBase

var card
var value

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard):
	var seraphiteTotal = 0
	card = thisCard
	
	for seraphite in thisHand:
		if seraphite.type == "Character" && seraphite.faction == "Seraphite":
			seraphiteTotal += 1
	
	if seraphiteTotal != 0:
		card.get_node("AnimationPlayer").animation_started.connect(_when_animation_starts)
		
		value = int(card.get_node("value").text)
		value += seraphiteTotal
		
		card.value += seraphiteTotal
		card.get_node("perk").text = "+" + str(seraphiteTotal)
		card.get_node("AnimationPlayer").queue("showPerk")
		card.get_node("value").text = str(value)

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
