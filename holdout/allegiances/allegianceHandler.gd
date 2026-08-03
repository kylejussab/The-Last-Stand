class_name AllegianceHandler
extends RefCounted

var battle: Node # reference to holdoutBattle.gd, set on creation

func setup(battleRef: Node) -> void:
	battle = battleRef

func on_character_played(_card: Node2D, _hand: Array, _opponentCard: Node2D, _isPlayer: bool) -> void:
	pass

func on_support_played(_card: Node2D, _characterCard: Node2D, _hand: Array, _isPlayer: bool) -> void:
	pass

func on_round_resolved(_winningCard: Node2D, _winningHand: Array, _losingCard: Node2D, _losingHand: Array, _isPlayerWinner: bool, _damage: int) -> void:
	if false: # Used to ignore warnings on scripts that await this funciton
		await (Engine.get_main_loop() as SceneTree).process_frame
		
	pass

func on_round_cleanup(_playerHand: Array, _opponentHand: Array) -> void:
	pass

func on_deck_build(_characterDeck: Array, _supportDeck: Array) -> void:
	pass

func get_save_dict() -> Dictionary:
	return {}

func load_save_dict(_data: Dictionary) -> void:
	pass
