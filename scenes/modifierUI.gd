extends Node2D

var tierOneModifier
var tierTwoModifier
var tierThreeModifier

@onready var slotOne: Node2D = $"Slot 1"
@onready var slotTwo: Node2D = $"Slot 2"
@onready var slotThree: Node2D = $"Slot 3"

var slotOneActive: bool = false
var slotTwoActive: bool = false
var slotThreeActive: bool = false

func _ready() -> void:
	_select_modifiers()
	%pauseIcon.hide()

func show_modifier_menu() -> void:
	show()

func _select_modifiers() -> void:
	var availableModifiers = {
		1: [],
		2: [],
		3: []
	}
	
	var activeIdModifiers = []
	for active in GameStats.activeModifiers:
		activeIdModifiers.append(active["id"])

	for modifier in Database.MODIFIERS.values():
		if not modifier["id"] in activeIdModifiers:
			var tier = modifier["tier"]
			
			if availableModifiers.has(tier):
				availableModifiers[tier].append(modifier)
	
	if availableModifiers[1].size() > 0:
		tierOneModifier = availableModifiers[1].pick_random()
		_update_slot_ui(tierOneModifier, slotOne)
	
	if availableModifiers[2].size() > 0:
		tierTwoModifier = availableModifiers[2].pick_random()
		_update_slot_ui(tierTwoModifier, slotTwo)

	if availableModifiers[3].size() > 0:
		tierThreeModifier = availableModifiers[3].pick_random()
		_update_slot_ui(tierThreeModifier, slotThree)

func _update_slot_ui(modifier, slot) -> void:
	slot.get_node("name").text = modifier.name
	slot.get_node("description").text = modifier.description
	slot.get_node("multiplier").text = "+ " + str(modifier.multiplier) + "x"
	slot.get_node("duration").text = str(modifier.duration) + " Game" + ("s" if modifier.duration > 1 else "")


# Signals
func _on_slot1_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if slotOneActive:
				slotOneActive = false
				slotOne.get_node("background").texture = load("res://assets/modifiers/SlotInActive.png")
				slotOne.get_node("selectedText").visible = false
			else:
				slotOneActive = true
				slotOne.get_node("background").texture = load("res://assets/modifiers/SlotActive.png")
				slotOne.get_node("selectedText").visible = true

func _on_slot2_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if slotTwoActive:
				slotTwoActive = false
				slotTwo.get_node("background").texture = load("res://assets/modifiers/SlotInActive.png")
				slotTwo.get_node("selectedText").visible = false
			else:
				slotTwoActive = true
				slotTwo.get_node("background").texture = load("res://assets/modifiers/SlotActive.png")
				slotTwo.get_node("selectedText").visible = true

func _on_slot3_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if slotThreeActive:
				slotThreeActive = false
				slotThree.get_node("background").texture = load("res://assets/modifiers/SlotInActive.png")
				slotThree.get_node("selectedText").visible = false
			else:
				slotThreeActive = true
				slotThree.get_node("background").texture = load("res://assets/modifiers/SlotActive.png")
				slotThree.get_node("selectedText").visible = true

func _on_slot1_area_2d_mouse_entered() -> void:
	slotOne.scale = Vector2(1.05, 1.05)

func _on_slot1_area_2d_mouse_exited() -> void:
	slotOne.scale = Vector2(1, 1)

func _on_slot2_area_2d_mouse_entered() -> void:
	slotTwo.scale = Vector2(1.05, 1.05)

func _on_slot2_area_2d_mouse_exited() -> void:
	slotTwo.scale = Vector2(1, 1)

func _on_slot3_area_2d_mouse_entered() -> void:
	slotThree.scale = Vector2(1.05, 1.05)

func _on_slot3_area_2d_mouse_exited() -> void:
	slotThree.scale = Vector2(1, 1)

func _on_confirm_button_pressed() -> void:
	if !slotOneActive and !slotTwoActive and !slotThreeActive:
		$ConfirmButton.release_focus()
		$ConfirmButton.button_pressed = false
		return
	
	if slotOneActive:
		%battleManager.add_modifier(tierOneModifier.id)
	if slotTwoActive:
		%battleManager.add_modifier(tierTwoModifier.id)
	if slotThreeActive:
		%battleManager.add_modifier(tierThreeModifier.id)
	
	hide()
	
	slotOneActive = false
	slotTwoActive = false
	slotThreeActive = false
	tierOneModifier = null
	tierTwoModifier = null
	tierThreeModifier = null
	
	GameStats.gameMode = GameStats.Mode.LAST_STAND
	%battleManager.start_new_match()
