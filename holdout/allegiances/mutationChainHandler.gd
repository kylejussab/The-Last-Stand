extends AllegianceHandler

const CHAIN_ORDER = ["Runner", "Stalker", "Clicker", "Shambler", "Bloater", "RatKing"]

func on_character_played(card: Node2D, hand: Array, _opponentCard: Node2D) -> void:
	if card.faction != "Infected":
		return
	
	var playedIndex = CHAIN_ORDER.find(card.cardKey)
	if playedIndex == -1:
		return
	
	var targets = hand.filter(func(c):
		return is_instance_valid(c) and CHAIN_ORDER.find(c.cardKey) != -1 and CHAIN_ORDER.find(c.cardKey) < playedIndex
	)
	
	if targets.is_empty():
		return
	
	battle.battleEngine.log_action("System. Mutation Chain activated. Weaker Infected in hand gained 3 from the infection progressing.")
	
	for targetCard in targets:
		_animate_and_boost(targetCard)

func _animate_and_boost(targetCard: Node2D) -> void:
	targetCard.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Mutation Chain.png")
	targetCard.get_node("AnimationPlayer").play("modifierIndicator")
	await targetCard.get_node("AnimationPlayer").animation_finished
	targetCard.modify_value(3)
