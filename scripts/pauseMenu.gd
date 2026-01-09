extends Node2D

var currentNavigation: String = "Main"

@onready var ui = %arena
@onready var battleManager = %battleManager

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	connect_buttons(self)
	hide()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if GameStats.gameMode != GameStats.Mode.LAST_STAND_ROUND_COMPLETED and GameStats.gameMode != GameStats.Mode.CARD_DRAW and GameStats.gameMode != GameStats.Mode.MODIFIER_SELECTION:
			battleManager.lockPlayerInput = true
			if currentNavigation == "Main":
				toggle_pause()
			elif currentNavigation == "Options":
				_play_back_sound()
				$OptionsButtonContainer.hide()
				$OptionsButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
				
				$mainButtonContainer.show()
				$mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
				currentNavigation = "Main"
			elif currentNavigation == "Restart Confirmation":
				_play_back_sound()
				$restartConfirmation.hide()
				$restartConfirmation.process_mode = Node.PROCESS_MODE_DISABLED
				
				$mainButtonContainer.show()
				$mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
				currentNavigation = "Main"
			elif currentNavigation == "Main Menu Confirmation":
				_play_back_sound()
				$mainMenuConfirmation.hide()
				$mainMenuConfirmation.process_mode = Node.PROCESS_MODE_DISABLED
				
				$mainButtonContainer.show()
				$mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
				currentNavigation = "Main"

func toggle_pause():
	var pauseState = !get_tree().paused
	get_tree().paused = pauseState
	
	if pauseState :
		_play_click_sound()
		$"../../pauseIcon/text".text = "BACK"
		show()
	else:
		_play_back_sound()
		battleManager.lockPlayerInput = false
		$"../../pauseIcon/text".text = "PAUSE"
		hide()

func _on_resume_pressed():
	toggle_pause()

func _on_options_button_pressed() -> void:
	currentNavigation = "Options"
	$mainButtonContainer.hide()
	$mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	$OptionsButtonContainer.show()
	$OptionsButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT

func _on_restart_button_pressed() -> void:
	currentNavigation = "Restart Confirmation"
	$mainButtonContainer.hide()
	$mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	$restartConfirmation.show()
	$restartConfirmation.process_mode = Node.PROCESS_MODE_INHERIT

func _on_restart_yes_button_pressed() -> void:
	get_tree().paused = false
	ui._on_replay_button_pressed()
	hide()

func _on_restart_no_button_pressed() -> void:
	$restartConfirmation.hide()
	$restartConfirmation.process_mode = Node.PROCESS_MODE_DISABLED
	
	$mainButtonContainer.show()
	$mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
	currentNavigation = "Main"

func _on_main_menu_button_pressed() -> void:
	currentNavigation = "Main Menu Confirmation"
	$mainButtonContainer.hide()
	$mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	$mainMenuConfirmation.show()
	$mainMenuConfirmation.process_mode = Node.PROCESS_MODE_INHERIT

func _on_main_menu_yes_button_pressed() -> void:
	get_tree().paused = false 
	ui._on_main_menu_button_pressed()
	hide()

func _on_main_menu_no_button_pressed() -> void:
	$mainMenuConfirmation.hide()
	$mainMenuConfirmation.process_mode = Node.PROCESS_MODE_DISABLED
	
	$mainButtonContainer.show()
	$mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
	currentNavigation = "Main"

# Helpers
func connect_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			child.mouse_entered.connect(_play_hover_sound)
			if child.name == "NoButton":
				child.pressed.connect(_play_back_sound)
			else:
				child.pressed.connect(_play_click_sound)
		
		if child.get_child_count() > 0:
			connect_buttons(child)

func _play_hover_sound():
	$"../ButtonHoverSound".play()

func _play_click_sound():
	$"../ButtonClickSound".play()

func _play_back_sound():
	$"../ButtonBackSound".play()
