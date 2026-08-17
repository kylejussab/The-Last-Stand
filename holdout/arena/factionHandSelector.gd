extends Node2D

const CENTER_X = 827.0
const POSITION_Y = 590.0
const SPACING = 50.0

const ICON_TARGET_SIZE = 40.0
const ICON_SOURCE_SIZE = 420.0

const ALL_FACTIONS = ["Firefly", "Infected", "Jackson", "Smuggler", "Seraphite", "WLF"]

var _selectedFaction: String = ""
var _selectionMade: bool = false

func prompt_faction_selection(hand: Array) -> String:
	var factionsInHand = _get_present_factions(hand)
	if factionsInHand.is_empty():
		return ""
	
	var buttons = _spawn_buttons(factionsInHand)
	
	await _fade_in()
	await _animate_buttons_in(buttons)
	
	_selectionMade = false
	_selectedFaction = ""
	while not _selectionMade:
		await get_tree().process_frame
	
	await _animate_buttons_out(buttons)
	await _fade_out()
	
	for b in buttons:
		b.queue_free()
	
	return _selectedFaction

func _get_present_factions(hand: Array) -> Array:
	var found = []
	for c in hand:
		if is_instance_valid(c) and c.type == "Character" and c.faction in ALL_FACTIONS:
			if not found.has(c.faction):
				found.append(c.faction)
	return found

func _spawn_buttons(factions: Array) -> Array:
	var buttons = []
	var count = factions.size()
	var span = (count - 1) * SPACING
	var startX = CENTER_X - (span / 2.0)
	
	for i in range(count):
		var button = _create_button_node(factions[i])
		add_child(button)
		button.global_position = Vector2(startX + (i * SPACING), POSITION_Y)
		button.scale = Vector2.ZERO
		buttons.append(button)
	
	return buttons

func _create_button_node(faction: String) -> Node2D:
	var button = Node2D.new()
	button.name = "FactionButton_" + faction
	
	var icon = Sprite2D.new()
	icon.name = "icon"
	icon.centered = true
	icon.texture = load("res://holdout/removal/" + faction + ".png")
	
	var iconScale = ICON_TARGET_SIZE / ICON_SOURCE_SIZE
	icon.scale = Vector2(iconScale, iconScale)
	
	button.add_child(icon)
	
	var area = Area2D.new()
	area.name = "Area2D"
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(ICON_TARGET_SIZE, ICON_TARGET_SIZE)
	collision.shape = shape
	area.add_child(collision)
	button.add_child(area)
	
	area.input_event.connect(_on_button_input.bind(button, faction))
	area.mouse_entered.connect(_on_button_hover.bind(button, true))
	area.mouse_exited.connect(_on_button_hover.bind(button, false))
	
	return button

func _on_button_input(_viewport, event, _shape_idx, _button: Node2D, faction: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		AudioManager.play_button_click()
		_selectedFaction = faction
		_selectionMade = true

func _on_button_hover(button: Node2D, isEnter: bool) -> void:
	AudioManager.play_card_hover()
	var baseScale = ICON_TARGET_SIZE / ICON_SOURCE_SIZE
	var targetScale = baseScale * 1.1 if isEnter else baseScale
	var icon = button.get_node("icon")
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "scale", Vector2(targetScale, targetScale), 0.1)

func _fade_in() -> void:
	$fade.modulate.a = 0.0
	$fade.show()
	var tween = create_tween()
	tween.tween_property($fade, "modulate:a", 0.8, 0.3)
	await tween.finished

func _fade_out() -> void:
	var tween = create_tween()
	tween.tween_property($fade, "modulate:a", 0.0, 0.3)
	await tween.finished
	$fade.hide()

func _animate_buttons_in(buttons: Array) -> void:
	for b in buttons:
		AudioManager.play_card_hover()
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(b, "scale", Vector2(1.0, 1.0), 0.3)
	
	await get_tree().create_timer(0.3).timeout

func _animate_buttons_out(buttons: Array) -> void:
	for b in buttons:
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(b, "scale", Vector2.ZERO, 0.25)
	
	await get_tree().create_timer(0.25).timeout
