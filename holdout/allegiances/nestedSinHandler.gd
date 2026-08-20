class_name NestedSinHandler
extends AllegianceHandler

const BONUS_AMOUNT = 4

func on_character_played(card: Node2D, hand: Array, _opponentCard: Node2D) -> void:
	if card.faction != "Seraphite":
		return
	
	var handHasOtherFaction = false
	for c in hand:
		if is_instance_valid(c) and c.type == "Character" and c.faction != "Seraphite":
			handHasOtherFaction = true
			break
	
	if handHasOtherFaction:
		return
	
	await (Engine.get_main_loop() as SceneTree).create_timer(0.75).timeout
	card.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Nested Sin.png")
	card.get_node("AnimationPlayer").play("modifierIndicator")
	await card.get_node("AnimationPlayer").animation_finished
	
	card.modify_value(BONUS_AMOUNT)
	battle.battleEngine.log_action("System. Nested Sin activated. " + card.nameText + " gained " + str(BONUS_AMOUNT) + " from playing alongside an all-Seraphite hand.")
