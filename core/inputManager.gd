extends Node2D

signal leftMouseButtonClicked
signal leftMouseButtonReleased

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_DECK = 3

var cardManagerReference
var deckReference

@onready var doubleClickTimer = $Timer

var last_click_time := 0.0
var double_click_threshold := 0.2

var clickEvent = false

func _ready() -> void:
	cardManagerReference = $"../cardManager"
	deckReference = $"../characterDeck"

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			await checkDoubleClick() # Proceeds normally if nothing happens
			
			emit_signal("leftMouseButtonClicked")
			
			if get_card_from_cursor():
				cardManagerReference.start_drag(get_card_from_cursor())
		else:
			emit_signal("leftMouseButtonReleased")

func get_card_from_cursor() -> Node2D:
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
			return card
	
	return null

func checkDoubleClick():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_click_time < double_click_threshold:
		doubleClickTimer.stop()
		if get_card_from_cursor():
			cardManagerReference.auto_play_card(get_card_from_cursor())
	else:
		doubleClickTimer.start(double_click_threshold)
	last_click_time = current_time
