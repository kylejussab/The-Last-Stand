extends PerkBase

var card
var value

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, _thisHand, otherCard):
	if otherCard.role.contains("Crafty"):
		card = thisCard
		
		card.get_node("AnimationPlayer").animation_started.connect(_when_animation_starts)
		
		# Special Case
		if otherCard.cardKey != "EllieRare":
			value = int(card.get_node("value").text)
			value += 1
			
			card.value += 1
			card.get_node("perk").text = "+1"
		else:
			value = int(card.get_node("value").text)
			card.get_node("perk").text = "+0"
		
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
