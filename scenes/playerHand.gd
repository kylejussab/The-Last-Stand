extends Node2D

const HAND_COUNT = 4
const CARD_SCENE_PATH = "res://scenes/card.tscn"
const CARD_WIDTH = 180
const HAND_Y_POSITION = 920

var playerHand: Array = []
var centerScreenX: float

func _ready() -> void:
	centerScreenX = get_viewport().size.x / 2
	
	var cardScene = preload(CARD_SCENE_PATH)
	
	for i in range(HAND_COUNT):
		var newCard = cardScene.instantiate()
		$"../cardManager".add_child(newCard)
		newCard.name = "Card"
		add_card_to_hand(newCard)

func add_card_to_hand(card):
	if card not in playerHand:
		playerHand.insert(0, card)
		update_hand_positions()
	else:
		animate_card_to_position(card, card.handPosition)

func remove_card_from_hand(card):
	if card in playerHand:
		playerHand.erase(card)
		update_hand_positions()

func calculate_card_position(index):
	var offset = (playerHand.size() -1) * CARD_WIDTH
	var cardPosition = centerScreenX + index * CARD_WIDTH - offset / 2.0
	return cardPosition

func update_hand_positions():
	for i in range(playerHand.size()):
		var newPosition = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = playerHand[i]
		card.handPosition = newPosition
		
		animate_card_to_position(card, newPosition)

func animate_card_to_position(card, newPosition):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", newPosition, 0.1)
