extends PerkBase

var card
var value

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, _thisHand, otherCard):
	var toAdd = 0
	
	if otherCard.role.contains("Aggressive"):
		toAdd += 2
	
	if otherCard.type == "Character" && otherCard.faction == "Infected":
		toAdd += 1
	
	if toAdd != 0:
		card = thisCard
		
		card.get_node("AnimationPlayer").animation_started.connect(_when_animation_starts)
		
		card.value += toAdd
		
		value = int(card.get_node("value").text) + toAdd
		
		card.get_node("perk").text = "+" + str(toAdd)
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
