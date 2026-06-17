extends Node2D

signal characterPlayed(card)
signal supportPlayed(card)

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const DEFAULT_CARD_MOVE_SPEED = 0.1

var draggedCard: Node2D
var hoveredCard: Node2D = null
var playerHandReference: Node

@onready var battleManager = %battleManager

func _ready() -> void:
	playerHandReference = $"../playerHand"
	$"../inputManager".connect("leftMouseButtonReleased", on_left_click_released)

func _process(_delta: float) -> void:
	if draggedCard:
		var mousePosition = get_global_mouse_position()
		var currentScreenSize = get_viewport().get_visible_rect().size
		draggedCard.position = Vector2(clamp(mousePosition.x, 0, currentScreenSize.x), clamp(mousePosition.y, 0, currentScreenSize.y))

func start_drag(card):
	if not "cardSlot" in card:
		return
		
	if battleManager.get("isTutorialActive") == true and "canBePlayed" in card and not card.canBePlayed:
		return
	
	if !battleManager.lockPlayerInput and card.cardSlot == null:
		draggedCard = card
		AudioManager.play_random_card_draw()
		card.scale = Vector2(1, 1)
		card.z_index += 50

func finish_drag():
	draggedCard.scale = Vector2(1.05, 1.05)
	AudioManager.play_random_card_draw()
	
	var cardSlot = get_card_slot()
	
	if cardSlot and not cardSlot.occupied and draggedCard.canBePlayed:
		if draggedCard.type == cardSlot.type:
			# Only allow a support card play after a character card
			if draggedCard.type == "Support" && !battleManager.playerCharacterCard:
				pass
			else:
				playerHandReference.remove_card_from_hand(draggedCard)
				
				draggedCard.z_index = -50
				draggedCard.position = cardSlot.position
				#draggedCard.get_node("Area2D/CollisionShape2D").disabled = true
				cardSlot.occupied = true
				draggedCard.cardSlot = cardSlot
				
				# Update player turn variable
				if draggedCard.type == "Character":
					emit_signal("characterPlayed", draggedCard)
				else:
					emit_signal("supportPlayed", draggedCard)
				
				# Ensure its not highlighted
				draggedCard.scale = Vector2(1, 1)
				draggedCard.get_node("AnimationPlayer").play_backwards("showPerkDescription")
				var endTime = draggedCard.get_node("AnimationPlayer").current_animation_length
				draggedCard.get_node("AnimationPlayer").seek(endTime, true)
				
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
	
	var isCardDisabled: bool = false
	
	#if "type" in card and card.type == "Character" and card.canBePlayed == false:
		#isCardDisabled = true
		
	if battleManager.get("isTutorialActive") == true:
		if "canBePlayed" in card and card.canBePlayed == false:
			isCardDisabled = true
	else:
		if "type" in card and card.type == "Character" and card.canBePlayed == false:
			isCardDisabled = true

	if isCardDisabled:
		if hoveredCard:
			highlight_card(hoveredCard, false)
		hoveredCard = null
		return
	
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
	if not "cardKey" in card:
		return
		
	var animationPlayer = card.get_node("AnimationPlayer")
	
	if battleManager.lockPlayerInput:
		return
		
	if animationPlayer and animationPlayer.is_playing():
		if animationPlayer.current_animation == "showPerk" or animationPlayer.current_animation == "cardFlip":
			return
	
	AudioManager.play_card_hover()
	
	var canShowPerk: bool = false
	if card.perk != null:
		canShowPerk = true
		
		if battleManager.get("isTutorialActive") == true and battleManager.get("arePerksActiveInTutorial") == false:
			canShowPerk = false
	
	if hovered:
		if !AccessibilityData.animationsDisabled:
			card.scale = Vector2(1.35, 1.35)
		
		if canShowPerk and !draggedCard:
			card.get_node("AnimationPlayer").play("showPerkDescription")
			
			if AccessibilityData.animationsDisabled:
				var endTime = card.get_node("AnimationPlayer").current_animation_length
				card.get_node("AnimationPlayer").seek(endTime, true)
	else:
		if !AccessibilityData.animationsDisabled:
			card.scale = Vector2(1, 1)
		
		if canShowPerk:
			card.get_node("AnimationPlayer").play_backwards("showPerkDescription")
			
			if AccessibilityData.animationsDisabled:
				var endTime = card.get_node("AnimationPlayer").current_animation_length
				card.get_node("AnimationPlayer").seek(endTime, true)

func get_top_card(cards):
	var topCard = cards[0].collider.get_parent()
	var topCardZIndex = topCard.z_index 
	
	for i in range(1, cards.size()):
		var currentCard = cards[i].collider.get_parent()
		if "type" not in currentCard: # Filters out anything that isn't a card
			continue
		
		if currentCard.z_index > topCardZIndex:
			topCard = currentCard
			topCardZIndex = currentCard.z_index
	return topCard

func on_left_click_released():
	if draggedCard:
		finish_drag()

# Double Click functionality
func auto_play_card(card):
	if not "type" in card:
		return
	
	if !$"../battleManager".lockPlayerInput:
		var characterSlot = $"../cardSlots/cardSlotCharacter"
		var supportSlot = $"../cardSlots/cardSlotSupport"
		
		if card.type == "Character" && !characterSlot.occupied && card.canBePlayed:
			move_card_on_double_click(card, characterSlot)
		elif card.type == "Support" && $"../battleManager".playerCharacterCard && card.canBePlayed:
			move_card_on_double_click(card, supportSlot)

func move_card_on_double_click(card, cardSlot):
	if !cardSlot.occupied:
		var tween = get_tree().create_tween()
		tween.tween_property(card, "position", cardSlot.position, 0.1)
		tween.finished.connect(AudioManager.play_random_card_draw)
		
		playerHandReference.remove_card_from_hand(card)
		
		card.z_index = -1
		card.position = cardSlot.position
		cardSlot.occupied = true
		card.cardSlot = cardSlot
		
		draggedCard = card
		
		# Update player turn variable
		if draggedCard.type == "Character":
			emit_signal("characterPlayed", draggedCard)
		else:
			emit_signal("supportPlayed", draggedCard)
		
		# Ensure its not highlighted
		draggedCard.scale = Vector2(1, 1)
		var anim = draggedCard.get_node("AnimationPlayer")
		anim.play_backwards("showPerkDescription")
		anim.seek(0, true)
		
		draggedCard = null

func play_top_character_from_deck() -> void:
	var card = $"../characterDeck".spawn_top_card_node()
	
	if card == null:
		return
	
	var characterSlot = $"../cardSlots/cardSlotCharacter"
	
	card.z_index = 10 
	
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", characterSlot.position, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.finished.connect(func(): 
		AudioManager.play_random_card_draw()
		card.z_index = 0
	)

	characterSlot.occupied = true
	card.cardSlot = characterSlot

	emit_signal("characterPlayed", card)

# Used to stop hovering when player input is locked
func force_unhighlight_all_cards() -> void:
	if hoveredCard and is_instance_valid(hoveredCard):
		_reset_card_visuals(hoveredCard)
		hoveredCard = null
	
	if "playerHand" in playerHandReference:
		for card in playerHandReference.playerHand:
			if is_instance_valid(card):
				_reset_card_visuals(card)

# Reset without audio
func _reset_card_visuals(card: Node2D) -> void:
	if !AccessibilityData.animationsDisabled:
		card.scale = Vector2(1, 1)
	
	if not "perk" in card or card.perk == null: 
		return
		
	var anim = card.get_node("AnimationPlayer")
	
	if anim.current_animation == "showPerkDescription":
		if AccessibilityData.animationsDisabled:
			anim.play("showPerkDescription")
			anim.seek(0, true)
			anim.stop()
		else:
			anim.play_backwards("showPerkDescription")
			
	elif anim.assigned_animation == "showPerkDescription" and not anim.is_playing():
		anim.play("showPerkDescription")
		anim.seek(0, true)
		anim.stop()
