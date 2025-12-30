extends Node2D

var currentNavigation: String = "Main"

@onready var ui = %arena
@onready var battleManager = %battleManager

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	connect_buttons(self)
	hide()

func _input(event):
	if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
		if GameStats.gameMode != "Last Stand Round Complete" and GameStats.gameMode != "Card Draw Animation":
			battleManager.lockPlayerInput = true
			if currentNavigation == "Main":
				toggle_pause()
			elif currentNavigation == "Options":
				_play_click_sound()
				currentNavigation = "Main"
				$OptionsButtonContainer.hide()
				$OptionsButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
				
				$mainButtonContainer.show()
				$mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT

func toggle_pause():
	var pauseState = !get_tree().paused
	get_tree().paused = pauseState
	
	if pauseState :
		$"../../pauseIcon/text".text = "BACK"
		show()
	else:
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
	get_tree().paused = false
	ui._on_replay_button_pressed()
	hide()

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false 
	ui._on_main_menu_button_pressed()
	hide()

# Helpers
func connect_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			child.mouse_entered.connect(_play_hover_sound)
			child.pressed.connect(_play_click_sound)
		
		if child.get_child_count() > 0:
			connect_buttons(child)

func _play_hover_sound():
	$"../ButtonHoverSound".play()

func _play_click_sound():
	$"../ButtonClickSound".play()
