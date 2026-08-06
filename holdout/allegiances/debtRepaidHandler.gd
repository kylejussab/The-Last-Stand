extends AllegianceHandler

func on_character_played(card: Node2D, hand: Array, otherCard: Node2D) -> void:
	if card.faction != "Jackson":
		return
	if not card.perk or not card.perk.has_method("get_companion_bonus"):
		return
	
	var result = card.perk.get_companion_bonus(card, hand, otherCard)
	var amount: int = result.get("amount", 0)
	var companions: Array = result.get("companions", [])
	
	if amount == 0 or companions.is_empty():
		return
	
	var jacksonCompanions = companions.filter(func(c): return is_instance_valid(c) and c.faction == "Jackson")
	if jacksonCompanions.is_empty():
		return
	
	battle.battleEngine.log_action("System. Debt Repaid activated. " + card.nameText + "'s companions in hand gained " + str(amount) + ".")
	
	for companion in jacksonCompanions:
		_animate_and_boost(companion, amount)

func _animate_and_boost(target: Node2D, amount: int) -> void:
	await (Engine.get_main_loop() as SceneTree).create_timer(1.0).timeout
	
	target.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Debt Repaid.png")
	target.get_node("AnimationPlayer").play("modifierIndicator")
	await target.get_node("AnimationPlayer").animation_finished
	target.modify_value(amount)
