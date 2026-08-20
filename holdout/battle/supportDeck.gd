extends Node2D

const PLAYER_CARD_SCENE_PATH = "res://core/cards/card.tscn"
const OPPONENT_CARD_SCENE_PATH = "res://core/cards/opponentCard.tscn"
const CARD_DRAW_SPEED = 0.2

const SUPPORT_DECK_POSITION = Vector2(135, 548)

var isHovered: bool = false

var deck: Array

var cardDatabaseReference

func _ready() -> void:
	$RichTextLabel.text = str(deck.size())
	cardDatabaseReference = preload("res://core/database.gd")

func draw_card():
	var cardDrawn = deck[0]
	deck.erase(cardDrawn)
	
	$RichTextLabel.text = str(deck.size())
	
	var newCard = _create_card_instance(cardDrawn, PLAYER_CARD_SCENE_PATH, true)
	
	$"../playerHand".add_card_to_hand(newCard, CARD_DRAW_SPEED)
	
	newCard.get_node("AnimationPlayer").play("cardFlip")
	AudioManager.play_random_card_draw()

func draw_opponent_card():
	var cardDrawn = deck[0]
	deck.erase(cardDrawn)
	
	$RichTextLabel.text = str(deck.size())
	
	var newCard = _create_card_instance(cardDrawn, OPPONENT_CARD_SCENE_PATH, false)
	
	$"../opponentHand".add_card_to_hand(newCard, CARD_DRAW_SPEED)
	AudioManager.play_random_card_draw()
	
	if %battleManager.showOpponentsCards:
		newCard.get_node("AnimationPlayer").play("cardFlip")
	else:
		newCard.get_node("image").visible = false

func reshuffle_from_discards(discardedCards):
	for card in discardedCards:
		deck.append(card.cardKey)
		
		AudioManager.play_random_card_draw()
		await move_card_back_to_deck(card)
		
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
	tween.tween_property(card, "position", SUPPORT_DECK_POSITION, 0.1)
	await tween.finished

# Privates
func _create_card_instance(cardKey: String, scenePath: String, isPlayer: bool = false) -> Node2D:
	var cardScene = load(scenePath)
	var newCard = cardScene.instantiate()
	
	newCard.cardKey = cardKey
	newCard.position = SUPPORT_DECK_POSITION
	newCard.name = "Card"
	newCard.canBePlayed = false

	var data = cardDatabaseReference.SUPPORTS[cardKey]
	newCard.value = data.Value
	newCard.type = data.Type
	newCard.parity = data.Parity
	newCard.nameText = data.CardText
	newCard.perkDescription = data.PerkText
	newCard.faction = "Support"
	
	if isPlayer and %battleManager.battleEngine.has_modifier(Database.Modifier.RUSTY_GEAR):
		newCard.value = newCard.value - 1
	
	newCard.get_node("value").text = str(newCard.value)
	newCard.get_node("name").text = newCard.nameText
	newCard.get_node("imageBack").texture = load("res://core/cards/art/CardBackBlank.png")
	
	if cardDatabaseReference.HOLDOUT_PERKS.has(cardKey):
		newCard.perk = load(cardDatabaseReference.HOLDOUT_PERKS[cardKey]).new()
	
	var iconsNode = newCard.get_node("icons")
	iconsNode.get_node("faction").visible = false
	
	# Hide all the type icons
	var perkSprites = [iconsNode.get_node("perk1"), iconsNode.get_node("perk2")]
	for sprite in perkSprites: sprite.visible = false
	
	newCard.update_visuals()
	
	$"../cardManager".add_child(newCard)
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
