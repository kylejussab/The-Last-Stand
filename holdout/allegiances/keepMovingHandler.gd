extends AllegianceHandler

var jacksonStreak: int = 0

func on_character_played(card: Node2D, _hand: Array, _otherCard: Node2D) -> void:
	if card.faction != "Jackson":
		jacksonStreak = 0
		return
	
	var bonus = jacksonStreak
	jacksonStreak += 1
	
	if bonus <= 0:
		return
	
	battle.battleEngine.log_action("System. Keep Moving activated. " + card.nameText + " gained +" + str(bonus) + " from consecutive Jackson plays.")
	
	await (Engine.get_main_loop() as SceneTree).create_timer(0.75).timeout
	
	card.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Keep Moving.png")
	card.get_node("AnimationPlayer").play("modifierIndicator")
	await card.get_node("AnimationPlayer").animation_finished
	card.modify_value(bonus)

func get_save_dict() -> Dictionary:
	return {"jacksonStreak": jacksonStreak}

func load_save_dict(data: Dictionary) -> void:
	jacksonStreak = int(data.get("jacksonStreak", 0))
