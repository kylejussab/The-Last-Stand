extends AllegianceHandler

var infectedCards: Array = []

func on_round_resolved(winningCard: Node2D, winningHand: Array, _losingCard: Node2D, _losingHand: Array, isPlayerWinner: bool, _damage: int) -> void:
	if not isPlayerWinner:
		return
	if winningCard.faction != "Infected":
		return
	
	var eligible = winningHand.filter(func(c): return is_instance_valid(c) and c._can_be_infected() and not c.gotInfected)
	if eligible.is_empty():
		return
	
	var target = eligible[randi() % eligible.size()]
	target.set_infected(true)


func get_save_dict() -> Dictionary:
	var keys = []
	for card in infectedCards:
		if is_instance_valid(card):
			keys.append(card.get_instance_id())
	return {"infectedInstanceIds": keys}
