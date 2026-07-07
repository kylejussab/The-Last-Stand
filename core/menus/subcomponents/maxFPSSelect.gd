extends Control

@onready var label = $MaxFPSDescriptionLabel
@onready var leftButton = $LeftButton
@onready var rightButton = $RightButton

const ARROW = preload("res://core/menus/subcomponents/ArrowLeft.png")
const ARROW_HOVER = preload("res://core/menus/subcomponents/ArrowLeftPressed.png")
const ARROW_EMPTY = preload("res://core/menus/subcomponents/ArrowLeftNone.png")

const FPS_OPTIONS = [60, 120, 144, 0] 
var FPS_LABELS = ["60", "120", "144", "Unlimited"]

var currentIndex: int = 0 # Default to 60

func _ready():
	leftButton.mouse_entered.connect(_play_hover.bind(leftButton))
	leftButton.focus_mode = Control.FOCUS_NONE
	
	rightButton.mouse_entered.connect(_play_hover.bind(rightButton))
	rightButton.focus_mode = Control.FOCUS_NONE
	
	var foundIndex = FPS_OPTIONS.find(SettingsData.maxFps)
	if foundIndex != -1:
		currentIndex = foundIndex
		
	_apply_fps()
	_update_ui()

func _on_left_button_pressed():
	_change_setting(-1)

func _on_right_button_pressed():
	_change_setting(1)

func _change_setting(direction: int):
	var target = currentIndex + direction
	if target < 0 or target >= FPS_OPTIONS.size():
		return
	
	AudioManager.play_button_click()
	
	currentIndex = target
	SettingsData.maxFps = FPS_OPTIONS[currentIndex]
	_apply_fps()
	_update_ui()

func _apply_fps():
	Engine.max_fps = SettingsData.maxFps

func _update_ui():
	label.text = FPS_LABELS[currentIndex]
	
	if currentIndex == 0:
		leftButton.texture_normal = ARROW_EMPTY
		leftButton.texture_hover = ARROW_EMPTY
	else:
		leftButton.texture_normal = ARROW
		leftButton.texture_hover = ARROW_HOVER
	
	if currentIndex == FPS_OPTIONS.size() - 1:
		rightButton.texture_normal = ARROW_EMPTY
		rightButton.texture_hover = ARROW_EMPTY
	else:
		rightButton.texture_normal = ARROW
		rightButton.texture_hover = ARROW_HOVER

func _play_hover(btn: TextureButton):
	if btn.texture_normal == ARROW_EMPTY:
		return
	AudioManager.play_button_hover()
