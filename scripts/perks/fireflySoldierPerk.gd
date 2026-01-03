extends PerkBase

var card
var value

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard):
	var isMarleneHere = false
	
	for marlene in thisHand:
		if marlene.cardKey == "Marlene":
			isMarleneHere = true
			break
	
	if isMarleneHere:
		card = thisCard
		
		card.get_node("AnimationPlayer").animation_started.connect(_when_animation_starts)
		
		value = int(card.get_node("value").text)
		value += 6
		
		card.get_node("perk").text = "+6"
		card.get_node("AnimationPlayer").queue("showPerk")

func _when_animation_starts(name: String):
	if name == "showPerk":
		updateCardValue()

func updateCardValue():
	card.get_node("value").text = str(value)
