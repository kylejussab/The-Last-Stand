extends Control

@onready var label = $WindowModeLabel
@onready var leftButton = $LeftButton
@onready var rightButton = $RightButton

const ARROW = preload("res://core/menus/subcomponents/ArrowLeft.png")
const ARROW_HOVER = preload("res://core/menus/subcomponents/ArrowLeftPressed.png")
const ARROW_EMPTY = preload("res://core/menus/subcomponents/ArrowLeftNone.png")

var MODE_LABELS = ["Fullscreen", "Borderless", "Windowed"]

func _ready():
	leftButton.mouse_entered.connect(_play_hover.bind(leftButton))
	leftButton.focus_mode = Control.FOCUS_NONE
	
	rightButton.mouse_entered.connect(_play_hover.bind(rightButton))
	rightButton.focus_mode = Control.FOCUS_NONE
	
	_apply_window_mode()
	_update_ui()

func _on_left_button_pressed():
	_change_setting(-1)

func _on_right_button_pressed():
	_change_setting(1)

func _change_setting(direction: int):
	var current = int(SettingsData.currentWindowMode)
	var count = SettingsData.WindowMode.size()

	var target = current + direction
	if target < 0 or target >= count:
		return
	
	AudioManager.play_button_click()
	
	SettingsData.currentWindowMode = target as SettingsData.WindowMode
	_apply_window_mode()
	_update_ui()

func _apply_window_mode():
	match SettingsData.currentWindowMode:
		SettingsData.WindowMode.FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		SettingsData.WindowMode.BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		SettingsData.WindowMode.WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(SettingsData.currentResolution)

func _update_ui():
	var current = int(SettingsData.currentWindowMode)
	var count = SettingsData.WindowMode.size()
	
	label.text = MODE_LABELS[current]
	
	if current == 0:
		leftButton.texture_normal = ARROW_EMPTY
		leftButton.texture_hover = ARROW_EMPTY
	else:
		leftButton.texture_normal = ARROW
		leftButton.texture_hover = ARROW_HOVER
	
	if current == count - 1:
		rightButton.texture_normal = ARROW_EMPTY
		rightButton.texture_hover = ARROW_EMPTY
	else:
		rightButton.texture_normal = ARROW
		rightButton.texture_hover = ARROW_HOVER

func _play_hover(btn: TextureButton):
	if btn.texture_normal == ARROW_EMPTY:
		return
	AudioManager.play_button_hover()
