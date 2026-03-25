extends Button

@onready var knob = $Knob
@onready var track = $Track

var xPositionOff: float = 3.0 
var xPositionOn: float = 41.0

const KNOB_COLOR_DEFAULT = Color("4c4c4c")
const KNOB_COLOR_HOVER = Color.WHITE

const TRACK_COLOR_DEFAULT = Color("2c2c2c")
const TRACK_COLOR_HOVER = Color("4c4c4c")

@onready var textLabel = $"../AnimationDescriptionLabel"

func _ready():
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	
	var areAnimationsOn = not AccessibilityData.animationsDisabled
	set_pressed_no_signal(areAnimationsOn)
	
	if areAnimationsOn:
		knob.position.x = xPositionOn
	else:
		knob.position.x = xPositionOff
	
	toggled.connect(_on_toggled)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_toggled(buttonState: bool):
	AudioManager.play_button_click()
	
	AccessibilityData.animationsDisabled = not buttonState
	
	var targetX = xPositionOn if buttonState else xPositionOff
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(knob, "position:x", targetX, 0.1)
	
	if AccessibilityData.animationsDisabled:
		textLabel.text = "Off"
	else:
		textLabel.text = "On"
	
	if owner.has_method("update_preview_card"):
		owner.update_preview_card()
	else:
		var pauseMenu = find_parent("pause") 
		if pauseMenu and pauseMenu.has_method("update_preview_card"):
			pauseMenu.update_preview_card()

func _on_mouse_entered():
	_set_element_color(knob, KNOB_COLOR_HOVER)
	_set_element_color(track, TRACK_COLOR_HOVER)
	
	AudioManager.play_button_hover()

func _on_mouse_exited():
	_set_element_color(knob, KNOB_COLOR_DEFAULT)
	_set_element_color(track, TRACK_COLOR_DEFAULT)

func _set_element_color(element: Panel, color: Color):
	var style = element.get_theme_stylebox("panel")
	if style:
		style = style.duplicate()
		style.bg_color = color
		element.add_theme_stylebox_override("panel", style)
