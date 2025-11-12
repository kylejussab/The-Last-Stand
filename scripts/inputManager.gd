extends Node2D

signal leftMouseButtonClicked
signal leftMouseButtonReleased

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_DECK = 3

var cardManagerReference
var deckReference

func _ready() -> void:
	cardManagerReference = $"../cardManager"
	deckReference = $"../characterDeck"

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			emit_signal("leftMouseButtonClicked")
			get_card_from_cursor()
		else:
			emit_signal("leftMouseButtonReleased")

func get_card_from_cursor():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	
	if result.size() > 0:
		var collisionMask = result[0].collider.collision_mask
		if collisionMask == COLLISION_MASK_CARD:
			var card = result[0].collider.get_parent()
			if card:
				cardManagerReference.start_drag(card)
		elif collisionMask == COLLISION_MASK_DECK:
			# Dont want this to be clickable in the future
			deckReference.draw_card()
