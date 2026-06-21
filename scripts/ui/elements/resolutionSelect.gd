extends Control

@onready var label = $ResolutionLabel
@onready var leftButton = $LeftButton
@onready var rightButton = $RightButton

const ARROW = preload("res://assets/mainMenu/ArrowLeft.png")
const ARROW_HOVER = preload("res://assets/mainMenu/ArrowLeftPressed.png")
const ARROW_EMPTY = preload("res://assets/mainMenu/ArrowLeftNone.png")

const RESOLUTIONS = [
	Vector2(1280, 720),
	Vector2(1600, 900),
	Vector2(1920, 1080),
	Vector2(2560, 1440)
]
var RES_LABELS = ["1280 x 720", "1600 x 900", "1920 x 1080", "2560 x 1440"]

var currentIndex: int = 2

func _ready():
	leftButton.mouse_entered.connect(_play_hover.bind(leftButton))
	leftButton.focus_mode = Control.FOCUS_NONE
	
	rightButton.mouse_entered.connect(_play_hover.bind(rightButton))
	rightButton.focus_mode = Control.FOCUS_NONE
	
	var foundIndex = RESOLUTIONS.find(SettingsData.currentResolution)
	if foundIndex != -1:
		currentIndex = foundIndex
		
	_apply_resolution()
	_update_ui()

func _on_left_button_pressed():
	_change_setting(-1)

func _on_right_button_pressed():
	_change_setting(1)

func _change_setting(direction: int):
	var target = currentIndex + direction
	if target < 0 or target >= RESOLUTIONS.size():
		return
	
	AudioManager.play_button_click()
	
	currentIndex = target
	SettingsData.currentResolution = RESOLUTIONS[currentIndex]
	_apply_resolution()
	_update_ui()

func _apply_resolution():
	if SettingsData.currentWindowMode == SettingsData.WindowMode.WINDOWED:
		DisplayServer.window_set_size(SettingsData.currentResolution)

func _update_ui():
	label.text = RES_LABELS[currentIndex]
	
	if currentIndex == 0:
		leftButton.texture_normal = ARROW_EMPTY
		leftButton.texture_hover = ARROW_EMPTY
	else:
		leftButton.texture_normal = ARROW
		leftButton.texture_hover = ARROW_HOVER
	
	if currentIndex == RESOLUTIONS.size() - 1:
		rightButton.texture_normal = ARROW_EMPTY
		rightButton.texture_hover = ARROW_EMPTY
	else:
		rightButton.texture_normal = ARROW
		rightButton.texture_hover = ARROW_HOVER

func _play_hover(btn: TextureButton):
	if btn.texture_normal == ARROW_EMPTY:
		return
	AudioManager.play_button_hover()
