extends Node2D

const PLAYER_CARD_SCENE_PATH = "res://core/cards/card.tscn"
const OPPONENT_CARD_SCENE_PATH = "res://core/cards/opponentCard.tscn"
const CARD_DRAW_SPEED = 0.2

const CHARACTER_DECK_POSITION = Vector2(135, 796)

var isHovered: bool = false

var deck: Array

var cardDatabaseReference

func _ready() -> void:
	$RichTextLabel.text = str(deck.size())
	cardDatabaseReference = preload("res://core/database.gd")

func draw_card() -> Tween:
	var cardDrawn = deck[0]
	deck.erase(cardDrawn)
	
	$RichTextLabel.text = str(deck.size())
	
	var newCard = _create_card_instance(cardDrawn, PLAYER_CARD_SCENE_PATH, true)
	
	var tween = $"../playerHand".add_card_to_hand(newCard, CARD_DRAW_SPEED)
	
	newCard.get_node("AnimationPlayer").play("cardFlip")
	AudioManager.play_random_card_draw()
	
	return tween

func draw_opponent_card():
	var cardDrawn = deck[0]
	deck.erase(cardDrawn)
	
	$RichTextLabel.text = str(deck.size())
	
	var newCard = _create_card_instance(cardDrawn, OPPONENT_CARD_SCENE_PATH)
	
	$"../opponentHand".add_card_to_hand(newCard, CARD_DRAW_SPEED)
	AudioManager.play_random_card_draw()
	
	# This if statement hides and shows the cards (In place for now, for debugging)
	if %battleManager.showOpponentsCards:
		newCard.get_node("AnimationPlayer").play("cardFlip")
	else:
		newCard.get_node("image").visible = false

func reshuffle_from_discards(discardedCards):
	var processedNodes = []

	for card in discardedCards:
		if not is_instance_valid(card):
			continue
		
		if card in processedNodes:
			continue
		
		processedNodes.append(card)
		
		if card.gotInfected and card.permanentInfection:
			HoldoutStats.add_permanent_mark("infected", card.cardKey, true)
		
		deck.append(card.cardKey)
		
		AudioManager.play_random_card_draw()
		await move_card_back_to_deck(card)
		
		if is_instance_valid(card):
			card.queue_free()
		
	deck.shuffle()
	
	z_index = 100
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property($image, "scale", Vector2(0.288, 0.288), 0.15)
	await tween.finished
	
	AudioManager.play_random_card_shuffle()
	
	await get_tree().create_timer(0.2).timeout
	var tween_back = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween_back.tween_property($image, "scale", Vector2(0.188, 0.188), 0.2)
	z_index = -2
	
	$RichTextLabel.text = str(deck.size())

func move_card_back_to_deck(card):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", CHARACTER_DECK_POSITION, 0.1)
	await tween.finished

# Privates
func _create_card_instance(cardKey: String, scenePath: String, isPlayer: bool = false) -> Node2D:
	var cardScene = load(scenePath)
	var newCard = cardScene.instantiate()
	
	newCard.cardKey = cardKey
	newCard.position = CHARACTER_DECK_POSITION
	newCard.name = "Card"
	newCard.canBePlayed = true

	var data = cardDatabaseReference.CHARACTERS[cardKey]
	newCard.value = data[0]
	newCard.type = data[1]
	newCard.faction = data[2]
	newCard.role = data[3]
	newCard.nameText = data[4]
	
	if data.size() > 5:
		newCard.perkDescription = data[5]
	
	if %battleManager.battleEngine.has_modifier(Database.Modifier.LOUD_NOISE) and "Stealthy" in newCard.role and isPlayer:
		var roles = Array(newCard.role.split("/"))
		
		roles.erase("Stealthy")
		
		if not roles.has("Aggressive"):
			roles.append("Aggressive")
		
		roles.sort()
		newCard.role = "/".join(roles)
		newCard.value += 2
	
	if %battleManager.battleEngine.has_modifier(Database.Modifier.BAITED_DEFENSE) and "Defensive" in newCard.role and isPlayer:
		newCard.value = 4
	if%battleManager.battleEngine.has_modifier(Database.Modifier.LONE_WOLF) and isPlayer:
		newCard.value *= 1.5
	
	newCard.get_node("value").text = str(newCard.value)
	newCard.get_node("name").text = newCard.nameText
	
	newCard.get_node("imageBack").texture = load("res://core/cards/art/CardBackBlank.png")
	
	if cardDatabaseReference.HOLDOUT_PERKS.has(cardKey):
		newCard.perk = load(cardDatabaseReference.HOLDOUT_PERKS[cardKey]).new()
	
	var iconsNode = newCard.get_node("icons")
	var factionPath = "res://core/cards/icons/" + newCard.faction + ".png" 
	iconsNode.get_node("faction").texture = load(factionPath)
	
	var perkList = newCard.role.split("/") if newCard.role else []
	var activePerks = []
	for perk in perkList:
		if perk != "": activePerks.append(perk)
	
	var perkSprites = [iconsNode.get_node("perk1"), iconsNode.get_node("perk2")]
	
	if activePerks.is_empty() or activePerks.size() == 5:
		for sprite in perkSprites: sprite.visible = false
	else:
		for i in range(perkSprites.size()):
			if i < activePerks.size():
				perkSprites[i].visible = true
				perkSprites[i].texture = load("res://core/cards/icons/" + activePerks[i] + ".png")
			else:
				perkSprites[i].visible = false
	
	newCard.update_visuals()
	
	if HoldoutStats.consume_permanent_mark("infected", cardKey):
		newCard.set_infected(true, false, true)
	
	$"../cardManager".add_child(newCard)
	return newCard

func spawn_top_card_node() -> Node2D:
	if deck.is_empty():
		return null
	
	var cardDrawn = deck[0]
	deck.erase(cardDrawn)
	
	$RichTextLabel.text = str(deck.size())
	
	var newCard = _create_card_instance(cardDrawn, PLAYER_CARD_SCENE_PATH, true)
	
	newCard.get_node("AnimationPlayer").play("cardFlip")
	AudioManager.play_random_card_draw()
	
	return newCard

func apply_card_accessibility_changes():
	var card_manager = $"../cardManager"
	if not card_manager: return

	for card in card_manager.get_children():
		if card.has_method("update_visuals"):
			card.update_visuals()

func _on_mouse_entered():
	if !%battleManager.lockPlayerInput and (!%viewDeckUI.isViewDeckActive and !%viewDeckUI.isViewHistoryActive):
		AudioManager.play_card_hover()
		isHovered = true
		
		$mainText.hide()
		$hoverText.show()
		
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)

func _on_mouse_exited():
	if !%battleManager.lockPlayerInput and (!%viewDeckUI.isViewDeckActive and !%viewDeckUI.isViewHistoryActive):
		isHovered = false
		
		$hoverText.hide()
		$mainText.show()
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
		
		AudioManager.play_card_hover()

func _on_mouse_pressed(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and !%battleManager.lockPlayerInput and event.pressed:
		%viewDeckUI.isViewDeckActive = true
		%viewDeckUI.open_deck_view(self)

func force_reset_visuals():
	isHovered = false
	$hoverText.hide()
	$mainText.show()
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
