extends Node2D

const PLAYER_CARD_SCENE_PATH = "res://scenes/card.tscn"
const OPPONENT_CARD_SCENE_PATH = "res://scenes/opponentCard.tscn"
const CARD_DRAW_SPEED = 0.2

const CHARACTER_DECK_POSITION = Vector2(135, 796)

@onready var soundPlayer = $AudioStreamPlayer2D

var shuffleSounds = [
	preload("res://assets/sounds/cards/shuffle_1.wav"),
	preload("res://assets/sounds/cards/shuffle_2.wav"),
	preload("res://assets/sounds/cards/shuffle_3.wav"),
	preload("res://assets/sounds/cards/shuffle_4.wav")
]

var deck: Array

var cardDatabaseReference

func _ready() -> void:
	$RichTextLabel.text = str(deck.size())
	cardDatabaseReference = preload("res://scripts/database.gd")

func draw_card():
	var cardDrawn = deck[0]
	deck.erase(cardDrawn)
	
	if deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$image.visible = false
	$RichTextLabel.text = str(deck.size())
	
	var newCard = _create_card_instance(cardDrawn, PLAYER_CARD_SCENE_PATH, true)
	
	$"../playerHand".add_card_to_hand(newCard, CARD_DRAW_SPEED)
	
	newCard.get_node("AnimationPlayer").play("cardFlip")
	newCard.play_draw_sound()

func draw_opponent_card():
	var cardDrawn = deck[0]
	deck.erase(cardDrawn)
	
	if deck.size() == 0:
		$image.visible = false
	$RichTextLabel.text = str(deck.size())
	
	var newCard = _create_card_instance(cardDrawn, OPPONENT_CARD_SCENE_PATH)
	
	$"../opponentHand".add_card_to_hand(newCard, CARD_DRAW_SPEED)
	newCard.play_draw_sound()
	
	# This if statement hides and shows the cards (In place for now, for debugging)
	if $"../battleManager".showOpponentsCards:
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
		
		deck.append(card.cardKey)
		
		card.play_draw_sound()
		await move_card_back_to_deck(card)
		
		if is_instance_valid(card):
			card.queue_free()
		
	deck.shuffle()
	
	z_index = 100
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property($image, "scale", Vector2(0.288, 0.288), 0.15)
	await tween.finished
	
	_play_shuffle_sound()
	
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
	
	if %battleManager.noDefenseActive and "Defensive" in newCard.role and isPlayer:
		newCard.value = 0
	
	if %battleManager.loneWolfActive and isPlayer:
		newCard.value *= 1.75
	
	newCard.get_node("value").text = str(newCard.value)
	newCard.get_node("image").texture = load("res://assets/cards/" + cardKey + "Card.png")
	newCard.get_node("imageBack").texture = load("res://assets/cards/CardBackBlank.png")

	if cardDatabaseReference.PERKS.has(cardKey):
		newCard.perk = load(cardDatabaseReference.PERKS[cardKey]).new()
		newCard.get_node("supportingText/text").texture = load("res://assets/cardDescriptions/" + cardKey + ".png")

	$"../cardManager".add_child(newCard)
	
	return newCard

func _play_shuffle_sound():
	var randomSound = shuffleSounds.pick_random()
	soundPlayer.stream = randomSound
	soundPlayer.play()
