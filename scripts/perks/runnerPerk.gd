extends PerkBase

var card
var value

func _init() -> void:
	timing = "midRound"

func apply_mid_perk(thisCard, thisHand, _otherCard):
	var infectedTotal = 0
	card = thisCard
	
	for infected in thisHand:
		if infected.type == "Character" && infected.faction == "Infected":
			infectedTotal += 1
	
	if infectedTotal != 0:
		card.get_node("AnimationPlayer").animation_started.connect(_when_animation_starts)
		
		value = int(card.get_node("value").text)
		value += infectedTotal
			
		card.get_node("perk").text = "+" + str(infectedTotal)
		card.get_node("AnimationPlayer").queue("showPerk")
		card.get_node("value").text = str(value)


func _when_animation_starts(name: String):
	if name == "showPerk":
		updateCardValue()

func updateCardValue():
	card.get_node("value").text = str(value)
