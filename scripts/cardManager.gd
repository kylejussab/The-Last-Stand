extends Node2D

signal characterPlayed(card)
signal supportPlayed(card)

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const DEFAULT_CARD_MOVE_SPEED = 0.1

var draggedCard: Node2D
var screenSize: Vector2
var hoveredCard: Node2D = null
var playerHandReference: Node

func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	screenSize = get_viewport().get_visible_rect().size

	playerHandReference = $"../playerHand"
	$"../inputManager".connect("leftMouseButtonReleased", on_left_click_released)

func _process(_delta: float) -> void:
	if draggedCard:
		var mousePosition = get_global_mouse_position()
		draggedCard.position = Vector2(clamp(mousePosition.x, 0, screenSize.x), clamp(mousePosition.y, 0, screenSize.y))

func start_drag(card):
	if !$"../battleManager".lockPlayerInput:
		draggedCard = card
		draggedCard.play_draw_sound()
		card.scale = Vector2(1, 1)

func finish_drag():
	draggedCard.scale = Vector2(1.05, 1.05)
	draggedCard.play_draw_sound()
	
	var cardSlot = get_card_slot()
	
	if cardSlot and not cardSlot.occupied and draggedCard.canBePlayed:
		if draggedCard.type == cardSlot.type:
			# Only allow a support card play after a character card
			if draggedCard.type == "Support" && !$"../battleManager".playerCharacterCard:
				pass
			else:
				playerHandReference.remove_card_from_hand(draggedCard)
				
				draggedCard.z_index = -1
				draggedCard.position = cardSlot.position
				draggedCard.get_node("Area2D/CollisionShape2D").disabled = true
				cardSlot.occupied = true
				draggedCard.cardSlot = cardSlot
				
				# Update player turn variable
				if draggedCard.type == "Character":
					emit_signal("characterPlayed", draggedCard)
				else:
					emit_signal("supportPlayed", draggedCard)
				
				draggedCard = null
				return
	
	playerHandReference.add_card_to_hand(draggedCard, DEFAULT_CARD_MOVE_SPEED)
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

func get_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var slots = space_state.intersect_point(parameters)
	
	if slots.size() > 0:
		return slots[0].collider.get_parent()
	return null

func connect_card_signals(card):
	card.connect("hoverEntered", on_card_hover_enter)
	card.connect("hoverExited", on_card_hover_exit)

func on_card_hover_enter(card):
	if draggedCard: return
	
	if hoveredCard and hoveredCard != card:
		highlight_card(hoveredCard, false)
	
	hoveredCard = card
	highlight_card(card, true)

func on_card_hover_exit(card):
	if hoveredCard == card:
		highlight_card(card, false)
		hoveredCard = null
		
		var newCardHovered = get_card()
		if newCardHovered:
			on_card_hover_enter(newCardHovered)

func highlight_card(card, hovered: bool):
	if hovered:
		card.scale = Vector2(1.05, 1.05)
		card.z_index = 2
		if card.perk:
			card.get_node("description").visible = true
	else:
		card.scale = Vector2(1, 1)
		card.z_index = 1
		if card.perk:
			card.get_node("description").visible = false

func get_top_card(cards):
	var topCard = cards[0].collider.get_parent()
	var topCardZIndex = topCard.z_index 
	
	for i in range(1, cards.size()):
		var currentCard = cards[i].collider.get_parent()
		if currentCard.z_index > topCardZIndex:
			topCard = currentCard
			topCardZIndex = currentCard.z_index
	return topCard

func on_left_click_released():
	if draggedCard:
		finish_drag()

# Double Click functionality
func auto_play_card(card):
	if !$"../battleManager".lockPlayerInput:
		var characterSlot = $"../cardSlots/cardSlotCharacter"
		var supportSlot = $"../cardSlots/cardSlotSupport"
		
		if card.type == "Character" && !characterSlot.occupied:
			move_card_on_double_click(card, characterSlot)
		elif card.type == "Support" && $"../battleManager".playerCharacterCard && card.canBePlayed:
			move_card_on_double_click(card, supportSlot)

func move_card_on_double_click(card, cardSlot):
	if !cardSlot.occupied:
		var tween = get_tree().create_tween()
		tween.tween_property(card, "position", cardSlot.position, 0.1)
		tween.finished.connect(func(): card.play_draw_sound())
		
		playerHandReference.remove_card_from_hand(draggedCard)
		
		card.z_index = -1
		card.position = cardSlot.position
		card.get_node("Area2D/CollisionShape2D").disabled = true
		cardSlot.occupied = true
		card.cardSlot = cardSlot
		
		draggedCard = card
		
		# Update player turn variable
		if draggedCard.type == "Character":
			emit_signal("characterPlayed", draggedCard)
		else:
			emit_signal("supportPlayed", draggedCard)
		
		playerHandReference.remove_card_from_hand(draggedCard)
		draggedCard = null
