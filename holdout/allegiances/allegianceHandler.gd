class_name AllegianceHandler
extends RefCounted

var battle: Node # reference to holdoutBattle.gd, set on creation

func setup(battleRef: Node) -> void:
	battle = battleRef

func on_character_played(_card: Node2D, _hand: Array, _opponentCard: Node2D) -> void:
	if false: # Used to ignore warnings on scripts that await this funciton
		await (Engine.get_main_loop() as SceneTree).process_frame
	
	pass

func on_support_played(_card: Node2D, _characterCard: Node2D, _hand: Array, _isPlayer: bool) -> void:
	if false: # Used to ignore warnings on scripts that await this funciton
		await (Engine.get_main_loop() as SceneTree).process_frame
		
	pass

func on_both_characters_played(_playerCard: Node2D, _playerHand: Array, _opponentCard: Node2D) -> void:
	if false: # Used to ignore warnings on scripts that await this funciton
		await (Engine.get_main_loop() as SceneTree).process_frame
	pass

func on_round_resolved(_winningCard: Node2D, _winningHand: Array, _losingCard: Node2D, _losingHand: Array, _isPlayerWinner: bool, _damage: int) -> void:
	if false: # Used to ignore warnings on scripts that await this funciton
		await (Engine.get_main_loop() as SceneTree).process_frame
		
	pass

func on_round_end(_playerCharacterCard: Node2D, _playerHand: Array, _opponentCharacterCard: Node2D, _opponentHand: Array) -> Dictionary:
	if false: # Used to ignore warnings on scripts that await this funciton
		await (Engine.get_main_loop() as SceneTree).process_frame
	return {}

func on_round_cleanup(_playerHand: Array, _opponentHand: Array) -> void:
	pass

func on_deck_build(_characterDeck: Array, _supportDeck: Array) -> void:
	pass

func prevents_backfire(_characterCard: Node2D) -> bool:
	return false

func get_forced_draw_faction() -> String:
	return ""

func clear_forced_draw() -> void:
	pass

func get_spawn_bonus(_faction: String) -> int:
	return 0

func _try_hunt(winningCard: Node2D, losingCard: Node2D, anyFactionExceptWLF: bool = false) -> bool:
	if winningCard.faction != "WLF":
		return false
	
	if anyFactionExceptWLF:
		if losingCard.faction == "WLF":
			return false
	else:
		if losingCard.faction != "Seraphite" and losingCard.faction != "Infected":
			return false
	
	var alreadyHunted = HoldoutStats.is_hunted(losingCard.cardKey)
	HoldoutStats.mark_hunted(losingCard.cardKey)
	
	return not alreadyHunted

func _play_hunt_effects(cardKey: String, losingCard: Node2D) -> void:
	if is_instance_valid(losingCard) and losingCard.cardKey == cardKey:
		_play_single_hunt_effect(losingCard)
	
	for c in battle.playerHand:
		if is_instance_valid(c) and c.cardKey == cardKey and not c.isHunted:
			_play_single_hunt_effect(c)
	
	for c in battle.opponentHand:
		if is_instance_valid(c) and c.cardKey == cardKey and not c.isHunted:
			c.isHunted = true
			c.modify_value(-2)
			c.get_node("icons/hunted").modulate.a = 1

func _play_single_hunt_effect(card: Node2D) -> void:
	card.isHunted = true
	card.get_node("AnimationPlayer").queue("hunt")
	
	await battle.get_tree().create_timer(0.85).timeout
	
	if is_instance_valid(card):
		AudioManager.play_mark()

func get_save_dict() -> Dictionary:
	return {}

func load_save_dict(_data: Dictionary) -> void:
	pass
