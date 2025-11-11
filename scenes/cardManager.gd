extends Node2D

const COLLISION_MASK_CARD = 1

var draggedCard
var screenSize
var isHoveringOnCard

func _ready() -> void:
	screenSize = get_viewport_rect().size

func _process(_delta: float) -> void:
	if draggedCard:
		var mousePosition = get_global_mouse_position()
		draggedCard.position = Vector2(clamp(mousePosition.x, 0, screenSize.x), clamp(mousePosition.y, 0, screenSize.y))

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var card = get_card()
			if card:
				start_drag(card)
		else:
			if draggedCard:
				finish_drag()

func start_drag(card):
	draggedCard = card
	card.scale = Vector2(1, 1)

func finish_drag():
	draggedCard.scale = Vector2(1.05, 1.05)
	draggedCard = null

func get_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var cards = space_state.intersect_point(parameters)
	
	if cards.size() > 0:
		return get_top_card(cards)
	return null

func connect_card_signals(card):
	card.connect("on", on_card_hover_enter)
	card.connect("off", on_card_hover_exit)
	
func on_card_hover_enter(card):
	if !isHoveringOnCard:
		highlight_card(card, true)
		isHoveringOnCard = true

func on_card_hover_exit(card):
	if !draggedCard:
		highlight_card(card, false)
		
		var newCardHovered = get_card()
		if newCardHovered:
			highlight_card(card, true)
		else:
			isHoveringOnCard = false

func highlight_card(card, hovered: bool):
	if hovered:
		card.scale = Vector2(1.05, 1.05)
		card.z_index = 2
	else:
		card.scale = Vector2(1, 1)
		card.z_index = 1

func get_top_card(cards):
	var topCard = cards[0].collider.get_parent()
	var topCardZIndex = topCard.z_index 
	
	for i in range(1, cards.size()):
		var currentCard = cards[i].collider.get_parent()
		if currentCard.z_index > topCardZIndex:
			topCard = currentCard
			topCardZIndex = currentCard.z_index
	return topCard
