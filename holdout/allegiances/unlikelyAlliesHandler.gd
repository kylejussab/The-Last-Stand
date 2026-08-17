extends AllegianceHandler
const BONUS = 3

var hasTriggered: bool = false
var chosenFaction: String = ""

func on_character_played(card: Node2D, hand: Array, _otherCard: Node2D) -> void:
	if hasTriggered:
		return
	if card.faction != "Firefly":
		return
	
	battle.lockPlayerInput = true
	var selected = await battle.get_node("%factionHandSelector").prompt_faction_selection(hand)
	battle.lockPlayerInput = false
	
	if selected == "":
		return
	
	hasTriggered = true
	chosenFaction = selected
	
	battle.battleEngine.log_action("System. Unlikely Allies activated. " + card.nameText + " chose " + chosenFaction + ", granting +" + str(BONUS) + " to those cards for the rest of this battle.")
	
	var eligible = hand.filter(func(c): return is_instance_valid(c) and c.type == "Character" and c.faction == chosenFaction)
	for target in eligible:
		_animate_and_boost(target)

func get_spawn_bonus(faction: String) -> int:
	if hasTriggered and faction == chosenFaction:
		return BONUS
	return 0

func _animate_and_boost(target: Node2D) -> void:
	target.get_node("ModifierIndicator").texture = load("res://holdout/allegiances/icons/Unlikely Allies.png")
	target.get_node("AnimationPlayer").queue("modifierIndicator")
	await battle._await_card_animation(target, "modifierIndicator")
	target.modify_value(BONUS)

func get_save_dict() -> Dictionary:
	return {"hasTriggered": hasTriggered, "chosenFaction": chosenFaction}

func load_save_dict(data: Dictionary) -> void:
	hasTriggered = data.get("hasTriggered", false)
	chosenFaction = data.get("chosenFaction", "")
