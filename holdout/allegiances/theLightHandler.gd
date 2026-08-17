extends AllegianceHandler

const BONUS = 2

func on_character_played(card: Node2D, hand: Array, _otherCard: Node2D) -> void:
	if card.faction != "Firefly":
		return
	
	var eligible = hand.filter(func(c): return is_instance_valid(c) and c.type == "Character")
	if eligible.is_empty():
		return
	
	battle.battleEngine.log_action("System. The Light activated. " + card.nameText + " gave +" + str(BONUS) + " to all characters in hand.")
	
	await (Engine.get_main_loop() as SceneTree).create_timer(0.5).timeout
	
	for target in eligible:
		_animate_and_boost(target)

func _animate_and_boost(target: Node2D) -> void:
	target.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/The Light.png")
	target.get_node("AnimationPlayer").queue("modifierIndicator")
	await battle._await_card_animation(target, "modifierIndicator")
	target.modify_value(BONUS)
