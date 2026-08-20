extends AllegianceHandler

const BONUS = 3

func on_character_played(card: Node2D, hand: Array, _otherCard: Node2D) -> void:
	if card.faction != "Jackson":
		return
	
	var eligible = hand.filter(func(c): return is_instance_valid(c) and c.type == "Character" and c.faction == "Jackson")
	if eligible.is_empty():
		return
	
	battle.battleEngine.log_action("System. Found Family activated. Your Jackson characters in hand gained +" + str(BONUS) + ".")
	
	await (Engine.get_main_loop() as SceneTree).create_timer(0.5).timeout
	
	for target in eligible:
		_animate_and_boost(target)

func _animate_and_boost(target: Node2D) -> void:
	target.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Found Family.png")
	target.get_node("AnimationPlayer").play("modifierIndicator")
	await target.get_node("AnimationPlayer").animation_finished
	target.modify_value(BONUS)
