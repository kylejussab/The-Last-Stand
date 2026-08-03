extends AllegianceHandler

const NEXT_STAGE = {
	"Runner": "Stalker",
	"Stalker": "Clicker",
	"Clicker": "Shambler",
	"Shambler": "Bloater",
	"Bloater": "RatKing",
}

func on_character_played(card: Node2D, hand: Array, _opponentCard: Node2D, isPlayer: bool) -> void:
	if not isPlayer:
		return
	if card.faction != "Infected":
		return
	if not NEXT_STAGE.has(card.cardKey):
		return
	
	var nextStageKey = NEXT_STAGE[card.cardKey]
	var target = hand.filter(func(c): return is_instance_valid(c) and c.cardKey == nextStageKey)
	
	if target.is_empty():
		return
	
	var targetCard = target[0]
	
	battle.battleEngine.log_action("System. Mutation Chain activated. " + targetCard.nameText + " gained 3 from the infection progressing.")
	
	targetCard.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Mutation Chain.png")
	targetCard.get_node("AnimationPlayer").play("modifierIndicator")
	await targetCard.get_node("AnimationPlayer").animation_finished
	targetCard.modify_value(3)
