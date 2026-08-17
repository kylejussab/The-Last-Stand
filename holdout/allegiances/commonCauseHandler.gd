extends AllegianceHandler

const PLAY_BONUS_PER_FIREFLY = 1
const WIN_BONUS = 2

func on_character_played(card: Node2D, hand: Array, _otherCard: Node2D) -> void:
	if card.faction != "Firefly":
		return
	
	var fireflyCount = 0
	for c in hand:
		if is_instance_valid(c) and c.type == "Character" and c.faction == "Firefly":
			fireflyCount += 1
	
	if fireflyCount <= 0:
		return
	
	var bonus = fireflyCount * PLAY_BONUS_PER_FIREFLY
	
	battle.battleEngine.log_action("System. Common Cause activated. " + card.nameText + " gained +" + str(bonus) + " for " + str(fireflyCount) + " Firefly in hand.")
	
	await (Engine.get_main_loop() as SceneTree).create_timer(0.5).timeout
	
	card.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Common Cause.png")
	card.get_node("AnimationPlayer").queue("modifierIndicator")
	await battle._await_card_animation(card, "modifierIndicator")
	card.modify_value(bonus)

func on_round_resolved(winningCard: Node2D, winningHand: Array, _losingCard: Node2D, _losingHand: Array, isPlayerWinner: bool, _damage: int) -> void:
	if not isPlayerWinner:
		return
	
	if not is_instance_valid(winningCard) or winningCard.faction != "Firefly":
		return
	
	var eligible = winningHand.filter(func(c): return is_instance_valid(c) and c.type == "Character" and c.faction == "Firefly")
	if eligible.is_empty():
		return
	
	battle.battleEngine.log_action("System. Common Cause activated. Winning with " + winningCard.nameText + " granted +" + str(WIN_BONUS) + " to your Fireflies in hand.")
	
	await (Engine.get_main_loop() as SceneTree).create_timer(0.5).timeout
	
	for target in eligible:
		await _animate_and_boost(target)

func _animate_and_boost(target: Node2D) -> void:
	target.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Common Cause.png")
	target.get_node("AnimationPlayer").queue("modifierIndicator")
	await battle._await_card_animation(target, "modifierIndicator")
	target.modify_value(WIN_BONUS)
