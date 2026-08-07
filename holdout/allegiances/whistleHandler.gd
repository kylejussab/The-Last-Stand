extends AllegianceHandler

var pendingDrawFaction: String = ""

func on_round_resolved(winningCard: Node2D, _winningHand: Array, _losingCard: Node2D, _losingHand: Array, isPlayerWinner: bool, _damage: int) -> void:
	if isPlayerWinner and winningCard.faction == "Seraphite":
		pendingDrawFaction = "Seraphite"
		battle.battleEngine.log_action("System. Whistle activated. Your next character draw will be a Seraphite.")

func get_forced_draw_faction() -> String:
	return pendingDrawFaction

func clear_forced_draw() -> void:
	pendingDrawFaction = ""

func get_save_dict() -> Dictionary:
	return {"pendingDrawFaction": pendingDrawFaction}

func load_save_dict(data: Dictionary) -> void:
	pendingDrawFaction = data.get("pendingDrawFaction", "")
