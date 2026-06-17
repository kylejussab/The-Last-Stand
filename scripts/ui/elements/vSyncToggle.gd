extends Button

@onready var knob = $Knob
@onready var track = $Track

var xPositionOff: float = 3.0 
var xPositionOn: float = 41.0

const KNOB_COLOR_DEFAULT = Color("4c4c4c")
const KNOB_COLOR_HOVER = Color.WHITE

const TRACK_COLOR_DEFAULT = Color("2c2c2c")
const TRACK_COLOR_HOVER = Color("4c4c4c")

@onready var textLabel = $"../DescriptionLabel"

@onready var maxFPSSelect = $"../../MaxFPSSelect"
@onready var maxFPSLabel = $"../../MaxFPSLabel"

func _ready():
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	
	var isVsyncOn = SettingsData.vsyncEnabled
	set_pressed_no_signal(isVsyncOn)
	
	if isVsyncOn:
		knob.position.x = xPositionOn
		textLabel.text = "On"
	else:
		knob.position.x = xPositionOff
		textLabel.text = "Off"
	
	_apply_vsync()
	
	toggled.connect(_on_toggled)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	maxFPSSelect.visible = not SettingsData.vsyncEnabled
	maxFPSLabel.visible = not SettingsData.vsyncEnabled

func _on_toggled(buttonState: bool):
	AudioManager.play_button_click()
	
	SettingsData.vsyncEnabled = buttonState
	_apply_vsync()
	
	maxFPSSelect.visible = not buttonState
	maxFPSLabel.visible = not buttonState
	
	var targetX = xPositionOn if buttonState else xPositionOff
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(knob, "position:x", targetX, 0.1)
	
	if SettingsData.vsyncEnabled:
		textLabel.text = "On"
	else:
		textLabel.text = "Off"

func _apply_vsync():
	if SettingsData.vsyncEnabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

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
