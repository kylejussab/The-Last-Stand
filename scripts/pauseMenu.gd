extends Node2D

var currentNavigation: String = "Main"

@onready var ui = %arena
@onready var battleManager = %battleManager

# Card for Accessibility Card Graphics
var previewCard: Node2D = null

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	connect_buttons(self)
	hide()
	$overlay.modulate.a = 0.0

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if GameStats.gameMode != GameStats.Mode.HOLDOUT_ROUND_COMPLETED and GameStats.gameMode != GameStats.Mode.CARD_DRAW and GameStats.gameMode != GameStats.Mode.MODIFIER_SELECTION:
			battleManager.lockPlayerInput = true
			if currentNavigation == "Main":
				toggle_pause()
			elif currentNavigation == "View Deck": # This is changed by the viewDeck script
				currentNavigation = "Main"
				battleManager.lockPlayerInput = false
			elif currentNavigation == "Options":
				AudioManager.play_button_back()
				$OptionsButtonContainer.hide()
				$OptionsButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
				
				$mainButtonContainer.show()
				$mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
				currentNavigation = "Main"
			elif currentNavigation == "Restart Confirmation":
				AudioManager.play_button_back()
				$restartConfirmation.hide()
				$restartConfirmation.process_mode = Node.PROCESS_MODE_DISABLED
				
				$mainButtonContainer.show()
				$mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
				currentNavigation = "Main"
			elif currentNavigation == "Main Menu Confirmation":
				AudioManager.play_button_back()
				$mainMenuConfirmation.hide()
				$mainMenuConfirmation.process_mode = Node.PROCESS_MODE_DISABLED
				
				$mainButtonContainer.show()
				$mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
				currentNavigation = "Main"
			elif currentNavigation == "Accessibility":
				AudioManager.play_button_back()
				$OptionsButtonContainer/accessibilityMenuContainer.hide()
				$OptionsButtonContainer/accessibilityMenuContainer.process_mode = Node.PROCESS_MODE_DISABLED
				
				$OptionsButtonContainer/mainContainer.show()
				$OptionsButtonContainer/mainContainer.process_mode = Node.PROCESS_MODE_INHERIT
				currentNavigation = "Options"
				_make_background_lighter()
			elif currentNavigation == "Accessibility/Cards":
				AudioManager.play_button_back()
				$OptionsButtonContainer/accessibilityMenuContainer/Heading.text = "OPTIONS   >   ACCESSIBILITY"
				
				$OptionsButtonContainer/accessibilityMenuContainer/cardsContainer.hide()
				$OptionsButtonContainer/accessibilityMenuContainer/cardsContainer.process_mode = Node.PROCESS_MODE_DISABLED
				
				$OptionsButtonContainer/accessibilityMenuContainer/mainContainer.show()
				$OptionsButtonContainer/accessibilityMenuContainer/mainContainer.process_mode = Node.PROCESS_MODE_INHERIT
				currentNavigation = "Accessibility"
				
				_update_all_game_card_visuals()
				_clear_preview_card()

func toggle_pause():
	var pauseState = !get_tree().paused
	get_tree().paused = pauseState
	
	if pauseState:
		AudioManager.play_button_click()
		AudioManager.change_volume_layer1(-35, 1)
		$"../../pauseIcon/text".text = "BACK"
		show()
		_make_background_lighter()
	else:
		AudioManager.play_button_back()
		AudioManager.change_volume_layer1(-20, 1)
		battleManager.lockPlayerInput = false
		$"../../pauseIcon/text".text = "PAUSE"
		await _make_background_invisible()
		hide()
		$mainButtonContainer.modulate.a = 1.0

func _on_resume_pressed():
	toggle_pause()

func _on_options_button_pressed() -> void:
	currentNavigation = "Options"
	$mainButtonContainer.hide()
	$mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	$OptionsButtonContainer.show()
	$OptionsButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT

func _on_display_button_pressed() -> void:
	_play_denied_animation($OptionsButtonContainer/mainContainer/DisplayButton)

func _on_audio_button_pressed() -> void:
	_play_denied_animation($OptionsButtonContainer/mainContainer/AudioButton)

func _on_subtitles_button_pressed() -> void:
	_play_denied_animation($OptionsButtonContainer/accessibilityMenuContainer/mainContainer/SubtitlesButton)

func _on_tutorial_button_pressed() -> void:
	_play_denied_animation($mainButtonContainer/TutorialButton)

func _on_restart_button_mouse_entered() -> void:
	%holdIcon.show()

func _on_restart_button_mouse_exited() -> void:
	%holdIcon.hide()

func _on_restart_button_hold_complete() -> void:
	get_tree().paused = false
	ui._on_replay_button_hold_complete()
	hide()

func _on_main_menu_button_mouse_entered() -> void:
	%holdIcon.show()

func _on_main_menu_button_mouse_exited() -> void:
	%holdIcon.hide()

func _on_main_menu_button_hold_complete() -> void:
	get_tree().paused = false 
	ui._on_main_menu_button_hold_complete()
	hide()

# Helpers
func connect_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			child.mouse_entered.connect(AudioManager.play_button_hover)
			child.focus_mode = Control.FOCUS_NONE
			
			if child.name == "NoButton":
				child.pressed.connect(AudioManager.play_button_back)
			else:
				child.pressed.connect(AudioManager.play_button_click)
		
		if child.get_child_count() > 0:
			connect_buttons(child)

func _on_accessibility_button_pressed() -> void:
	currentNavigation = "Accessibility"
	$OptionsButtonContainer/mainContainer.hide()
	$OptionsButtonContainer/mainContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	$OptionsButtonContainer/accessibilityMenuContainer.show()
	$OptionsButtonContainer/accessibilityMenuContainer.process_mode = Node.PROCESS_MODE_INHERIT
	_make_background_darker()

func _on_cards_button_pressed() -> void:
	currentNavigation = "Accessibility/Cards"
	
	$OptionsButtonContainer/accessibilityMenuContainer/Heading.text = "OPTIONS   >   ACCESSIBILITY   >   CARDS"
	$OptionsButtonContainer/accessibilityMenuContainer/mainContainer.hide()
	$OptionsButtonContainer/accessibilityMenuContainer/mainContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	$OptionsButtonContainer/accessibilityMenuContainer/cardsContainer.show()
	$OptionsButtonContainer/accessibilityMenuContainer/cardsContainer.process_mode = Node.PROCESS_MODE_INHERIT
	
	update_preview_card()

# Privates
func update_preview_card():
	if previewCard != null:
		previewCard.queue_free()
	
	var card_scene = load("res://scenes/card.tscn")
	previewCard = card_scene.instantiate()
	
	previewCard.scale = Vector2(2, 2)
	previewCard.position = Vector2(1450, 540)
	
	previewCard.cardKey = "Clicker"
	previewCard.value = 5
	previewCard.type = "Character"
	previewCard.faction = "Infected"
	previewCard.role = "Aggressive"
	previewCard.nameText = "CLICKER"
	previewCard.perkDescription = "-2 to opponent health on round win"
	
	previewCard.get_node("value").text = str(previewCard.value)
	previewCard.get_node("name").text = previewCard.nameText
	previewCard.get_node("imageBack").texture = load("res://assets/cards/CardBackBlank.png")
	
	previewCard.get_node("icons/faction").texture = load("res://assets/cardIcons/Infected.png")
	
	$OptionsButtonContainer/accessibilityMenuContainer/cardsContainer.add_child(previewCard)
	
	var adapter = Control.new()
	adapter.name = "UI_Input_Adapter"
	previewCard.add_child(adapter)
	
	var size = load("res://assets/cards/CardBackBlank.png").get_size() * 0.2
	adapter.size = size
	adapter.position = -(size / 2)
	
	adapter.mouse_entered.connect(_on_preview_hover_entered.bind(previewCard))
	adapter.mouse_exited.connect(_on_preview_hover_exited.bind(previewCard))
	previewCard.update_visuals()

func _clear_preview_card():
	if previewCard != null:
		previewCard.queue_free()
		previewCard = null

func _update_all_game_card_visuals():
	var playerHand = %playerHand.playerHand
	var opponentHand = %opponentHand.opponentHand
	
	for card in playerHand:
		card.update_visuals()
	
	for card in opponentHand:
		card.update_visuals()
	
	if %battleManager.playerCharacterCard:
		%battleManager.playerCharacterCard.update_visuals()
	if %battleManager.opponentCharacterCard:
		%battleManager.opponentCharacterCard.update_visuals()
	if %battleManager.playerSupportCard:
		%battleManager.playerSupportCard.update_visuals()
	if %battleManager.opponentSupportCard:
		%battleManager.opponentSupportCard.update_visuals()

func _on_preview_hover_entered(card_node):
	AudioManager.play_card_hover()
	
	if !AccessibilityData.animationsDisabled:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(card_node, "scale", Vector2(2.35, 2.35), 0.1)
	
	if card_node.has_node("AnimationPlayer"):
		if card_node.get_node("AnimationPlayer").has_animation("showPerkDescription"):
			card_node.get_node("AnimationPlayer").play("showPerkDescription")
			
			if AccessibilityData.animationsDisabled:
				var endTime = card_node.get_node("AnimationPlayer").current_animation_length
				card_node.get_node("AnimationPlayer").seek(endTime, true)
			
	card_node.z_index = 10

func _on_preview_hover_exited(card_node):
	AudioManager.play_card_hover()
	
	if !AccessibilityData.animationsDisabled:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(card_node, "scale", Vector2(2, 2), 0.1)
	
	if card_node.has_node("AnimationPlayer"):
		if card_node.get_node("AnimationPlayer").has_animation("showPerkDescription"):
			card_node.get_node("AnimationPlayer").play_backwards("showPerkDescription")
			
			if AccessibilityData.animationsDisabled:
				card_node.get_node("AnimationPlayer").seek(0, true)
			
	card_node.z_index = 0

func _make_background_invisible():
	var tween = create_tween()
	tween.tween_property($overlay, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property($mainButtonContainer, "modulate:a", 0.0, 0.2)
	
	await tween.finished

func _make_background_lighter():
	var tween = create_tween()
	tween.tween_property($overlay, "modulate:a", 0.9, 0.2)
	
	await tween.finished

func _make_background_darker():
	var tween = create_tween()
	tween.tween_property($overlay, "modulate:a", 1.0, 0.2)
	
	await tween.finished

func _play_denied_animation(currentButton: Button):
	var originalPos = currentButton.position.x
	var shake_offset = 5.0
	var duration = 0.05
	
	var tween = create_tween()
	tween.tween_property(currentButton, "position:x", originalPos + shake_offset, duration)
	tween.tween_property(currentButton, "position:x", originalPos - shake_offset, duration)
	tween.tween_property(currentButton, "position:x", originalPos, duration)
