extends Node2D

const CARD_WIDTH = 180
const HAND_Y_POSITION = 120 #It was 120 to see the opponents cards
const DEFAULT_CARD_MOVE_SPEED = 0.1

var opponentHand: Array = []
var centerScreenX: float

func _ready() -> void:
	centerScreenX = get_viewport().get_visible_rect().size.x / 2

func add_card_to_hand(card, speed):
	if card not in opponentHand:
		if card.type == "Character":
			opponentHand.insert(0, card)
		else:
			opponentHand.append(card)
			
		update_hand_positions(speed)
	else:
		animate_card_to_position(card, card.handPosition, DEFAULT_CARD_MOVE_SPEED)

func remove_card_from_hand(card):
	if card in opponentHand:
		opponentHand.erase(card)
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)

func calculate_card_position(index):
	var offset = (opponentHand.size() -1) * CARD_WIDTH
	var cardPosition = centerScreenX + index * CARD_WIDTH - offset / 2.0
	return cardPosition

func update_hand_positions(speed):
	for i in range(opponentHand.size()):
		var newPosition = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = opponentHand[i]
		card.handPosition = newPosition
		
		animate_card_to_position(card, newPosition, speed)

func animate_card_to_position(card, newPosition, speed):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", newPosition, speed)
