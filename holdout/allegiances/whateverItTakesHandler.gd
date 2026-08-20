extends AllegianceHandler

func on_character_played(card: Node2D, hand: Array, _otherCard: Node2D) -> void:
	if card.faction != "Firefly":
		return
	
	battle.lockPlayerInput = true
	var chosenFaction = await battle.get_node("%factionHandSelector").prompt_faction_selection(hand)
	battle.lockPlayerInput = false
	
	if chosenFaction == "":
		return
	
	var eligible = hand.filter(func(c): return is_instance_valid(c) and c != card and c.type == "Character" and c.faction == chosenFaction and c.perk != null)
	if eligible.is_empty():
		return
	
	var donor = eligible[randi() % eligible.size()]
	
	if not Database.HOLDOUT_PERKS.has(donor.cardKey):
		return
	
	card.borrowedPerk = load(Database.HOLDOUT_PERKS[donor.cardKey]).new()
	
	battle.battleEngine.log_action("System. Whatever It Takes activated. " + card.nameText + " borrowed " + donor.nameText + "'s perk.")
	
	_play_transfer_indicator(card)
	_play_transfer_indicator(donor)

func _play_transfer_indicator(target: Node2D) -> void:
	target.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Whatever It Takes.png")
	target.get_node("AnimationPlayer").queue("modifierIndicator")
	await battle._await_card_animation(target, "modifierIndicator")
