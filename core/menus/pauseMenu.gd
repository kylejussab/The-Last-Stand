extends Node2D

@onready var optionsMenu = $OptionsMenu

var currentNavigation: String = "Main"

#@onready var ui = %arena
@onready var outro = %outro

@onready var battleManager = %battleManager

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	connect_buttons(self)
	hide()
	$overlay.modulate.a = 0.0
	
	# Connect the signals from our unified component!
	optionsMenu.options_exited.connect(_on_options_menu_exited)
	optionsMenu.card_accessibility_closed.connect(_update_all_game_card_visuals)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if GameStats.gameMode != GameStats.Mode.HOLDOUT_ROUND_COMPLETED and GameStats.gameMode != GameStats.Mode.CARD_DRAW and GameStats.gameMode != GameStats.Mode.MODIFIER_SELECTION:
			battleManager.lockPlayerInput = true
			if currentNavigation == "Main":
				toggle_pause()
			elif currentNavigation == "View Deck": # This is changed by the viewDeck script
				currentNavigation = "Main"
				battleManager.lockPlayerInput = false
			elif currentNavigation == "Tutorial":
				AudioManager.play_button_back()
				var tween = create_tween()
				tween.tween_property($TutorialMenu, "modulate:a", 0.0, 0.25)
	
				$mainButtonContainer.show()
				$mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
				currentNavigation = "Main"
				
				tween.finished.connect(func():
					$TutorialMenu.hide()
					$TutorialMenu.process_mode = Node.PROCESS_MODE_DISABLED
					$TutorialMenu.modulate.a = 1.0
				)

func toggle_pause():
	var pauseState = !get_tree().paused
	get_tree().paused = pauseState
	
	if pauseState:
		AudioManager.play_button_click()
		AudioManager.change_volume_background(-30)
		$"../../pauseIcon/text".text = "BACK"
		show()
		_make_background_lighter()
	else:
		AudioManager.play_button_back()
		AudioManager.change_volume_background() # Audio back to default always
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
	
	_make_background_darker()
	optionsMenu.open(false)

func _on_options_menu_exited() -> void:
	currentNavigation = "Main"
	$mainButtonContainer.show()
	$mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
	
	_make_background_lighter()

func _on_help_button_pressed() -> void:
	currentNavigation = "Tutorial"
	$mainButtonContainer.hide()
	$mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	
	$TutorialMenu.reset()
	$TutorialMenu.show()
	$TutorialMenu.process_mode = Node.PROCESS_MODE_INHERIT

func _on_restart_button_mouse_entered() -> void:
	%holdIcon.show()

func _on_restart_button_mouse_exited() -> void:
	%holdIcon.hide()

func _on_restart_button_hold_complete() -> void:
	get_tree().paused = false
	outro._on_replay_button_hold_complete()
	hide()

func _on_main_menu_button_mouse_entered() -> void:
	%holdIcon.show()

func _on_main_menu_button_mouse_exited() -> void:
	%holdIcon.hide()

func _on_main_menu_button_hold_complete() -> void:
	get_tree().paused = false 
	outro._on_main_menu_button_hold_complete()
	hide()

func _on_corrupt_main_menu_button_pressed() -> void:
	outro._on_main_menu_button_hold_complete()
	%saveFileCorrupt.visible = false

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
	
	for card in %battleManager.discardedCards:
		card.update_visuals()

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
