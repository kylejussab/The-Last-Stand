extends Node2D

var icons: Array[Sprite2D] = []
var icon_blends: Array[float] = [] 
var time: float = PI
var is_orbiting: bool = false

var current_orbit_speed: float 

var num_icons: int = 5
var line_spacing: float = 80.0
var width_amplitude: float = 160.0
var height_amplitude: float = 75.0
var orbit_speed: float = 9.0
var target_scale: float = 0.05
var peel_delay: float = 0.15 

func _ready() -> void:
	if SaveManager.isLoadingSave:
		hide()
		set_process(false)
		return
		
	await get_tree().create_timer(0.5).timeout
	
	current_orbit_speed = orbit_speed
	_spawn_and_pop_in()

func _spawn_and_pop_in() -> void:
	for i in range(num_icons):
		var icon = Sprite2D.new()
		icon.texture = preload("res://assets/ui/Opponent.png") 
		add_child(icon)
		icons.append(icon)
		
		icon_blends.append(0.0) 
		icon.scale = Vector2.ZERO 
		icon.position = Vector2.ZERO
		
		_update_line_positions(i + 1, 0.4)
		
		AudioManager.play_card_hover()
		
		var pop_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop_tween.tween_property(icon, "scale", Vector2(target_scale, target_scale), 0.4)
		
		await get_tree().create_timer(0.4).timeout

	_start_orbit()

func _update_line_positions(current_count: int, speed: float) -> void:
	var total_width = (current_count - 1) * line_spacing
	var start_x = -total_width / 2.0
	
	for j in range(current_count):
		var target_x = start_x + (j * line_spacing)
		var new_pos = Vector2(target_x, 0)
		
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(icons[j], "position", new_pos, speed)

func _start_orbit() -> void:
	is_orbiting = true
	
	AudioManager.play_whoosh(true)
	
	for i in range(num_icons):
		var tween = create_tween()
		
		tween.tween_interval(i * peel_delay)
		
		tween.set_parallel(true)
		
		tween.tween_method(Callable(self, "_set_icon_blend").bind(i), 0.0, 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		
		tween.tween_property(icons[i], "modulate", Color("4c4c4c"), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var slowdown_tween = create_tween()
	slowdown_tween.tween_interval(.5)
	slowdown_tween.tween_property(self, "current_orbit_speed", 0.0, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	AudioManager.play_whoosh(true)

func _set_icon_blend(val: float, index: int) -> void:
	icon_blends[index] = val

func _process(delta: float) -> void:
	if not is_orbiting:
		return
		
	time += delta * current_orbit_speed 
	
	for i in range(icons.size()):
		var icon = icons[i]
		
		var offset_x = (i - (num_icons - 1) / 2.0) * line_spacing
		var line_pos = Vector2(offset_x, 0)
		
		var trail_offset = i * (peel_delay * orbit_speed) 
		
		var curve_pos = Vector2(
			width_amplitude * sin(time - trail_offset),
			height_amplitude * sin(2.0 * (time - trail_offset))
		)
		
		icon.position = line_pos.lerp(curve_pos, icon_blends[i])
