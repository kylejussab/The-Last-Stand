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

var playingStartAnimation: bool = false
#var canPlayHoverSound: bool = true

@onready var battleAnimator: Node = %battleAnimator

func _ready() -> void:
	%pauseIcon.hide()

func show_modifier_menu() -> void:
	_select_modifiers()
	
	playingStartAnimation = true
	
	show()
	$overlay.modulate.a = 0.0
	$title.modulate.a = 0.0
	$title.position.y = 540
	$subtitle.modulate.a = 0.0
	
	for slot in [$"Slot 1", $"Slot 2", $"Slot 3"]:
		slot.position.y = 1440
		slot.get_node("visuals/ReelWindow").position.y = -50
		slot.get_node("visuals/ReelWindow").modulate.a = 0.0
		slot.get_node("visuals/ReelWindow").hide()
		slot.get_node("visuals/ReelWindow").scale = Vector2(1, 1)
		slot.get_node("visuals/text").modulate.a = 0.0
		slot.get_node("visuals/text").position.y = 50
	
	$ConfirmButton.modulate.a = 0.0
	$ConfirmButton.disabled = true
	
	await get_tree().create_timer(1).timeout
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property($overlay, "modulate:a", 1.0, 0.5)
	
	var growTween = create_tween().set_parallel(true)
	growTween.tween_property($title, "modulate:a", 1.0, 0.5)
	growTween.tween_property($title, "scale", Vector2(3.0, 3.0), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	AudioManager.play_whoosh()
	
	var fadeTween = create_tween()
	fadeTween.tween_property($title, "modulate:a", 1.0, 0.3)
	await fadeTween.finished
	
	var slamTween = create_tween()
	slamTween.tween_property($title, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	slamTween.tween_interval(0.4)
	
	await slamTween.finished
	
	var slideTween = create_tween().set_parallel(true)
	
	AudioManager.play_whoosh(true)
	
	slideTween.tween_property($title, "position:y", -375.0, 0.5).as_relative().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	await slideTween.finished
	
	var finalTween = create_tween()
	
	finalTween.tween_interval(0.2)
	finalTween.tween_property($subtitle, "modulate:a", 1.0, 1)
	
	finalTween.tween_callback(func(): _animate_single_slot($"Slot 1", tierOneModifier))
	finalTween.tween_interval(0.6)
	
	finalTween.tween_callback(func(): _animate_single_slot($"Slot 2", tierTwoModifier))
	finalTween.tween_interval(0.6)
		
	finalTween.tween_callback(func(): _animate_single_slot($"Slot 3", tierThreeModifier))
	
	finalTween.tween_interval(2.5)
	finalTween.tween_property($ConfirmButton, "modulate:a", 1.0, 1)
	$ConfirmButton.disabled = false
	
	finalTween.tween_callback(func(): playingStartAnimation = false)
	
	var audioTween = create_tween()
	
	audioTween.tween_interval(2.0)
	audioTween.tween_callback(AudioManager.play_slot_spin)
	
	audioTween.tween_interval(1.8) 
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	audioTween.tween_interval(0.7)
	audioTween.tween_callback(AudioManager.play_slot_stop)
	
	audioTween.tween_interval(0.6)
	audioTween.tween_callback(AudioManager.play_slot_stop)

# Privates
func _select_modifiers() -> void:
	if not is_node_ready():
		await ready
	
	var availableByTier = { 1: [], 2: [], 3: [] }
	var activeIdModifiers = []
	for active in GameStats.activeModifiers:
		activeIdModifiers.append(active["id"])
	
	for modifier in Database.MODIFIERS.values():
		if not modifier["id"] in activeIdModifiers:
			var tier = modifier["tier"]
			
			if modifier.has("healthCost") and GameStats.playerHealthValue <= modifier["healthCost"]:
				continue
			
			if availableByTier.has(tier):
				availableByTier[tier].append(modifier)
	
	tierOneModifier = _pick_weighted_modifier(availableByTier[1])
	tierTwoModifier = _pick_weighted_modifier(availableByTier[2])
	tierThreeModifier = _pick_weighted_modifier(availableByTier[3])
	
	var currentPicks = [tierOneModifier.id, tierTwoModifier.id, tierThreeModifier.id]
	
	GameStats.lastOfferedModifierIds.append_array(currentPicks)
	
	if GameStats.lastOfferedModifierIds.size() >= 12: # currently 60% of the entire list (20 mods)
		GameStats.lastOfferedModifierIds.clear()
		GameStats.lastOfferedModifierIds.append_array(currentPicks)
	
	_update_slot_ui(tierOneModifier, slotOne)
	_update_slot_ui(tierTwoModifier, slotTwo)
	_update_slot_ui(tierThreeModifier, slotThree)
	
	$"Slot 1/visuals/ReelWindow".setup_reel(availableByTier[1])
	$"Slot 2/visuals/ReelWindow".setup_reel(availableByTier[2])
	$"Slot 3/visuals/ReelWindow".setup_reel(availableByTier[3])

func _update_slot_ui(modifier, slot) -> void:
	slot.get_node("visuals/text/name").text = modifier.name
	slot.get_node("visuals/text/description").text = modifier.description
	slot.get_node("visuals/text/multiplier").text = "+ " + str(modifier.multiplier) + "x"
	slot.get_node("visuals/text/duration").text = str(modifier.duration) + " Game" + ("s" if modifier.duration > 1 else "")

func _animate_single_slot(slot: Node2D, modifierData: Dictionary) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	slot.get_node("visuals/ReelWindow").show()
	tween.tween_property(slot, "position:y", 540.0, 0.75).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(slot.get_node("visuals/ReelWindow"), "modulate:a", 1.0, 0.75).set_delay(0.1)
	tween.tween_callback(func(): slot.get_node("visuals/ReelWindow").spin_to_modifier(modifierData))
	
	tween.tween_interval(2.2)
	
	tween.tween_property(slot.get_node("visuals/ReelWindow"), "position:y", -115.0, 0.6).as_relative().set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(slot.get_node("visuals/ReelWindow"), "scale", Vector2(0.7, 0.7), 0.3).set_ease(Tween.EASE_OUT)
	
	tween.parallel().tween_property(slot.get_node("visuals/text"), "modulate:a", 1.0, 0.6).set_delay(0.1)
	tween.parallel().tween_property(slot.get_node("visuals/text"), "position:y", -60.0, 0.6).as_relative().set_ease(Tween.EASE_OUT).set_delay(0.1)
	
	tween.tween_callback(func(): slot.get_node("AnimationPlayer").play("showMultiplier"))

func _pick_weighted_modifier(tierPool: Array) -> Dictionary:
	if tierPool.is_empty(): 
		return {}
	
	# 80% chance to try and pick something "fresh" (not shown last time)
	if randf() < 0.8:
		var freshPool = []
		for modifier in tierPool:
			if not modifier.id in GameStats.lastOfferedModifierIds:
				freshPool.append(modifier)
		
		# Fallback if too many "fresh" picks were chosen
		if not freshPool.is_empty():
			return freshPool.pick_random()

	# 20% chance (or ultiamte fallback) for pure randomness
	return tierPool.pick_random()

# Signals
func _on_slot1_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and !playingStartAnimation:
			if slotOneActive:
				slotOneActive = false
				slotOne.get_node("visuals/background").texture = load("res://assets/modifiers/SlotInActive.png")
				slotOne.get_node("visuals/text/selectedText").visible = false
			else:
				slotOneActive = true
				slotOne.get_node("visuals/background").texture = load("res://assets/modifiers/SlotActive.png")
				slotOne.get_node("visuals/text/selectedText").visible = true

func _on_slot2_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and !playingStartAnimation:
			if slotTwoActive:
				slotTwoActive = false
				slotTwo.get_node("visuals/background").texture = load("res://assets/modifiers/SlotInActive.png")
				slotTwo.get_node("visuals/text/selectedText").visible = false
			else:
				slotTwoActive = true
				slotTwo.get_node("visuals/background").texture = load("res://assets/modifiers/SlotActive.png")
				slotTwo.get_node("visuals/text/selectedText").visible = true

func _on_slot3_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and !playingStartAnimation:
			if slotThreeActive:
				slotThreeActive = false
				slotThree.get_node("visuals/background").texture = load("res://assets/modifiers/SlotInActive.png")
				slotThree.get_node("visuals/text/selectedText").visible = false
			else:
				slotThreeActive = true
				slotThree.get_node("visuals/background").texture = load("res://assets/modifiers/SlotActive.png")
				slotThree.get_node("visuals/text/selectedText").visible = true

func _on_slot1_area_2d_mouse_entered() -> void:
	if !playingStartAnimation:
		var tween = create_tween()
		tween.tween_property(slotOne.get_node("visuals"), "scale", Vector2(1.05, 1.05), 0.1)
		AudioManager.play_card_hover()

func _on_slot1_area_2d_mouse_exited() -> void:
	if !playingStartAnimation:
		var tween = create_tween()
		tween.tween_property(slotOne.get_node("visuals"), "scale", Vector2(1, 1), 0.1)
		AudioManager.play_card_hover()

func _on_slot2_area_2d_mouse_entered() -> void:
	if !playingStartAnimation:
		var tween = create_tween()
		tween.tween_property(slotTwo.get_node("visuals"), "scale", Vector2(1.05, 1.05), 0.1)
		AudioManager.play_card_hover()

func _on_slot2_area_2d_mouse_exited() -> void:
	if !playingStartAnimation:
		var tween = create_tween()
		tween.tween_property(slotTwo.get_node("visuals"), "scale", Vector2(1, 1), 0.1)
		AudioManager.play_card_hover()

func _on_slot3_area_2d_mouse_entered() -> void:
	if !playingStartAnimation:
		var tween = create_tween()
		tween.tween_property(slotThree.get_node("visuals"), "scale", Vector2(1.05, 1.05), 0.1)
		AudioManager.play_card_hover()

func _on_slot3_area_2d_mouse_exited() -> void:
	if !playingStartAnimation:
		var tween = create_tween()
		tween.tween_property(slotThree.get_node("visuals"), "scale", Vector2(1, 1), 0.1)
		AudioManager.play_card_hover()

func _on_confirm_button_pressed() -> void:
	if !slotOneActive and !slotTwoActive and !slotThreeActive:
		$ConfirmButton.release_focus()
		$ConfirmButton.button_pressed = false
		return
	
	playingStartAnimation = true
	
	if slotOneActive:
		%battleManager.add_modifier(tierOneModifier.id)
	if slotTwoActive:
		%battleManager.add_modifier(tierTwoModifier.id)
	if slotThreeActive:
		%battleManager.add_modifier(tierThreeModifier.id)
	
	AudioManager.play_button_click()
	
	slotOneActive = false
	slotTwoActive = false
	slotThreeActive = false
	
	slotOne.get_node("visuals/background").texture = load("res://assets/modifiers/SlotInActive.png")
	slotOne.get_node("visuals/text/selectedText").visible = false
	slotTwo.get_node("visuals/background").texture = load("res://assets/modifiers/SlotInActive.png")
	slotTwo.get_node("visuals/text/selectedText").visible = false
	slotThree.get_node("visuals/background").texture = load("res://assets/modifiers/SlotInActive.png")
	slotThree.get_node("visuals/text/selectedText").visible = false
	
	AudioManager.play_whoosh(true)
	
	get_node("AnimationPlayer").play("hideUI")
	await get_node("AnimationPlayer").animation_finished
	
	hide()
	
	get_node("AnimationPlayer").play("RESET")
	
	tierOneModifier = null
	tierTwoModifier = null
	tierThreeModifier = null
	
	GameStats.gameMode = GameStats.Mode.HOLDOUT
	%battleManager.initialize_game()
	
	playingStartAnimation = false

func _on_confirm_button_mouse_entered() -> void:
	AudioManager.play_button_hover()
