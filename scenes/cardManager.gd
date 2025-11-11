extends Node2D

const COLLISION_MASK_CARD = 1

var draggedCard
var screenSize

func _ready() -> void:
	screenSize = get_viewport_rect().size

func _process(delta: float) -> void:
	if draggedCard:
		var mousePosition = get_global_mouse_position()
		draggedCard.position = Vector2(clamp(mousePosition.x, 0, screenSize.x), clamp(mousePosition.y, 0, screenSize.y))

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var card = get_clicked_card()
			if card:
				draggedCard = card
		else:
			draggedCard = null

func get_clicked_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var card = space_state.intersect_point(parameters)
	
	if card.size() > 0:
		return card[0].collider.get_parent()
	return null
