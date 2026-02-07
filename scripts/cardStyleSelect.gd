extends Control

@onready var label = $StyleDescriptionLabel 
@onready var leftButton = $LeftButton
@onready var rightButton = $RightButton

const ARROW = preload("res://assets/mainMenu/ArrowLeft.png")
const ARROW_HOVER = preload("res://assets/mainMenu/ArrowLeftPressed.png")
const ARROW_EMPTY = preload("res://assets/mainMenu/ArrowLeftNone.png")

var STYLE_LABELS = ["Default", "No Character", "Minimal"]

func _ready():
	leftButton.mouse_entered.connect(_play_hover.bind(leftButton))
	leftButton.focus_mode = Control.FOCUS_NONE
	
	rightButton.mouse_entered.connect(_play_hover.bind(rightButton))
	rightButton.focus_mode = Control.FOCUS_NONE
	
	_update_ui()

func _on_left_button_pressed():
	_change_setting(-1)

func _on_right_button_pressed():
	_change_setting(1)

func _change_setting(direction: int):
	var current = 0
	var count = 0
	
	current = int(AccessibilityData.currentCardStyle)
	count = AccessibilityData.CardStyle.size()

	var target = current + direction
	if target < 0 or target >= count:
		return
	
	_play_click()
	
	AccessibilityData.currentCardStyle = target as AccessibilityData.CardStyle

	_update_ui()
	
	if owner.has_method("update_preview_card"):
		owner.update_preview_card()
	else:
		var pauseMenu = find_parent("pause") 
		if pauseMenu and pauseMenu.has_method("update_preview_card"):
			pauseMenu.update_preview_card()

func _update_ui():
	var count = AccessibilityData.CardStyle.size()
	
	label.text = STYLE_LABELS[int(AccessibilityData.currentCardStyle)]
	
	if int(AccessibilityData.currentCardStyle) == 0:
		leftButton.texture_normal = ARROW_EMPTY
		leftButton.texture_hover = ARROW_EMPTY
	else:
		leftButton.texture_normal = ARROW
		leftButton.texture_hover = ARROW_HOVER
	
	if int(AccessibilityData.currentCardStyle) == count - 1:
		rightButton.texture_normal = ARROW_EMPTY
		rightButton.texture_hover = ARROW_EMPTY
	else:
		rightButton.texture_normal = ARROW
		rightButton.texture_hover = ARROW_HOVER

# Helpers
func _play_hover(btn: TextureButton):
	if btn.texture_normal == ARROW_EMPTY:
		return
		
	%ButtonHoverSound.play()

func _play_click():
	%ButtonClickSound.play()
