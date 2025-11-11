extends Node2D

const CARD_WIDTH = 180
const HAND_Y_POSITION = 920
const DEFAULT_CARD_MOVE_SPEED = 0.1

var playerHand: Array = []
var centerScreenX: float

func _ready() -> void:
	centerScreenX = get_viewport().size.x / 2

func add_card_to_hand(card, speed):
	if card not in playerHand:
		playerHand.insert(0, card)
		update_hand_positions(speed)
	else:
		animate_card_to_position(card, card.handPosition, DEFAULT_CARD_MOVE_SPEED)

func remove_card_from_hand(card):
	if card in playerHand:
		playerHand.erase(card)
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)

func calculate_card_position(index):
	var offset = (playerHand.size() -1) * CARD_WIDTH
	var cardPosition = centerScreenX + index * CARD_WIDTH - offset / 2.0
	return cardPosition

func update_hand_positions(speed):
	for i in range(playerHand.size()):
		var newPosition = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = playerHand[i]
		card.handPosition = newPosition
		
		animate_card_to_position(card, newPosition, speed)

func animate_card_to_position(card, newPosition, speed):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", newPosition, speed)
