extends AllegianceHandler

func on_round_resolved(winningCard: Node2D, winningHand: Array, _losingCard: Node2D, _losingHand: Array, isPlayerWinner: bool, _damage: int) -> void:
	if not isPlayerWinner:
		return
	if winningCard.faction != "Infected":
		return
	
	var eligible = winningHand.filter(func(c): return is_instance_valid(c) and c._can_be_infected() and not c.gotInfected)
	if eligible.is_empty():
		return
	
	var target = eligible[randi() % eligible.size()]
	battle.battleEngine.log_action("System. Violent Outbreak activated. " + target.nameText + " has been permanently infected for the remainder of the run.")
	target.set_infected(true, true, true)
	HoldoutStats.register_new_master_mark("infected", target.cardKey)
