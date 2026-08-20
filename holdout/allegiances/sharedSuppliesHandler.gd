extends AllegianceHandler

func on_support_played(card: Node2D, characterCard: Node2D, hand: Array, isPlayer: bool) -> void:
	if not isPlayer:
		return
	if not is_instance_valid(characterCard) or characterCard.faction != "Jackson":
		return
	if card.parity != "Positive":
		return
	
	var eligible = hand.filter(func(c): return is_instance_valid(c))
	if eligible.is_empty():
		return
	
	battle.battleEngine.log_action("System. Shared Supplies activated. A random card in hand gained +2.")
	
	var target = eligible[randi() % eligible.size()]
	_animate_and_boost(target)

func _animate_and_boost(target: Node2D) -> void:
	await (Engine.get_main_loop() as SceneTree).create_timer(0.5).timeout
	
	target.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Shared Supplies.png")
	target.get_node("AnimationPlayer").play("modifierIndicator")
	await target.get_node("AnimationPlayer").animation_finished
	target.modify_value(2)
