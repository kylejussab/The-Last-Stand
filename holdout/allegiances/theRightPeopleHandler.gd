extends AllegianceHandler

const BONUS = 3

func on_character_played(card: Node2D, hand: Array, _otherCard: Node2D) -> void:
	if card.faction != "Firefly":
		return
	
	battle.lockPlayerInput = true
	var chosenFaction = await battle.get_node("%factionHandSelector").prompt_faction_selection(hand)
	battle.lockPlayerInput = false
	if chosenFaction == "":
		return
	
	var eligible = hand.filter(func(c): return is_instance_valid(c) and c.type == "Character" and c.faction == chosenFaction)
	if eligible.is_empty():
		return
	
	battle.battleEngine.log_action("System. The Right People activated. " + card.nameText + " chose " + chosenFaction + ", granting +" + str(BONUS) + " to those cards in hand.")
	
	for target in eligible:
		_animate_and_boost(target)

func _animate_and_boost(target: Node2D) -> void:
	target.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/The Right People.png")
	target.get_node("AnimationPlayer").queue("modifierIndicator")
	await battle._await_card_animation(target, "modifierIndicator")
	target.modify_value(BONUS)
