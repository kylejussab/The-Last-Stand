extends Button
signal hold_complete 
@export var holdDuration: float = 1.0
@onready var progressRing = $HoldProgress
var hold_timer: float = 0.0
var is_holding: bool = false
var hold_enabled: bool = true

func _ready():
	progressRing.max_value = holdDuration
	progressRing.value = 0
	progressRing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progressRing.hide()
	
	button_down.connect(_button_down)
	button_up.connect(_button_up)

func set_hold_enabled(enabled: bool) -> void:
	hold_enabled = enabled
	if not enabled:
		is_holding = false
		hold_timer = 0
		progressRing.value = 0
		progressRing.hide()

func _process(delta):
	if not hold_enabled:
		return
	if is_holding:
		hold_timer += delta
		progressRing.value = hold_timer
		
		if hold_timer >= holdDuration:
			_finish_hold()
	else:
		if hold_timer > 0:
			hold_timer = 0
			progressRing.value = 0
			progressRing.hide()

func _button_down():
	if not hold_enabled:
		return
	is_holding = true
	progressRing.show()

func _button_up():
	if not hold_enabled:
		return
	if is_holding and hold_timer < holdDuration:
		_play_denied_animation()
		release_focus()
		button_pressed = false
	
	is_holding = false

func _finish_hold():
	is_holding = false
	hold_timer = 0
	progressRing.hide()
	
	emit_signal("hold_complete")

func _play_denied_animation():
	var original_x = position.x
	var tween = create_tween()
	tween.tween_property(self, "position:x", original_x + 5, 0.05)
	tween.tween_property(self, "position:x", original_x - 5, 0.05)
	tween.tween_property(self, "position:x", original_x, 0.05)
