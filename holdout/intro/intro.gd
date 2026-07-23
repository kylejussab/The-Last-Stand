extends Node2D

@onready var infinityContainer: Node2D = $InfinityContainer

# Infinity Variables
var icons: Array[Sprite2D] = []
var iconBlends: Array[float] = []
var time: float = PI
var isOrbiting: bool = false
var currentOrbitSpeed: float
var numberOfIcons: int = 5
var lineSpacing: float = 80.0
var widthAmplitude: float = 160.0
var heightAmplitude: float = 75.0
var orbitSpeed: float = 9.0
var targetScale: float = 0.05
var peelDelay: float = 0.15

var delayBeforeTransition: float = 4.5
var transitionDuration: float = 1.4
var moveDistance: float = 700.0


func _ready() -> void:
	if SaveManager.isLoadingSave:
		hide()
		set_process(false)
		return
	
	if GameStats.gameMode == GameStats.Mode.HOLDOUT_TUTORIAL:
		hide()
		set_process(false)
		return
	
	_run_intro_sequence()
	_trigger_transition()


func _process(delta: float) -> void:
	if not isOrbiting:
		return
	
	time += delta * currentOrbitSpeed
	
	for i in range(icons.size()):
		var icon = icons[i]
		
		var offset_x = (i - (numberOfIcons - 1) / 2.0) * lineSpacing
		var line_pos = Vector2(offset_x, 0)
		
		var trail_offset = i * (peelDelay * orbitSpeed)
		
		var curve_pos = Vector2(
			widthAmplitude * sin(time - trail_offset),
			heightAmplitude * sin(2.0 * (time - trail_offset))
		)
		
		icon.position = line_pos.lerp(curve_pos, iconBlends[i])


func _run_intro_sequence() -> void:
	await get_tree().create_timer(0.5).timeout
	
	currentOrbitSpeed = orbitSpeed
	_spawn_and_pop_in()


func _spawn_and_pop_in() -> void:
	for i in range(numberOfIcons):
		var icon = Sprite2D.new()
		icon.texture = preload("res://holdout/intro/Opponent.png")
		infinityContainer.add_child(icon)
		icons.append(icon)
		
		iconBlends.append(0.0)
		icon.scale = Vector2.ZERO
		icon.position = Vector2.ZERO
		
		_update_line_positions(i + 1, 0.4)
		
		AudioManager.play_card_hover()
		
		var pop_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop_tween.tween_property(icon, "scale", Vector2(targetScale, targetScale), 0.4)
		
		await get_tree().create_timer(0.4).timeout
	_start_orbit()


func _update_line_positions(current_count: int, speed: float) -> void:
	var total_width = (current_count - 1) * lineSpacing
	var start_x = -total_width / 2.0
	
	for j in range(current_count):
		var target_x = start_x + (j * lineSpacing)
		var new_pos = Vector2(target_x, 0)
		
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(icons[j], "position", new_pos, speed)


func _start_orbit() -> void:
	isOrbiting = true
	
	AudioManager.play_whoosh(true)
	
	for i in range(numberOfIcons):
		var tween = create_tween()
		
		tween.tween_interval(i * peelDelay)
		tween.set_parallel(true)
		tween.tween_method(Callable(self, "_set_icon_blend").bind(i), 0.0, 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(icons[i], "modulate", Color("4c4c4c"), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var slowdown_tween = create_tween()
	slowdown_tween.tween_interval(.5)
	slowdown_tween.tween_property(self, "currentOrbitSpeed", 0.0, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	AudioManager.play_whoosh(true)


func _set_icon_blend(val: float, index: int) -> void:
	iconBlends[index] = val


func _trigger_transition() -> void:
	await get_tree().create_timer(delayBeforeTransition).timeout
	
	AudioManager.play_whoosh(true)
	
	isOrbiting = false
	%HoldoutHub.show()
	%HoldoutHub._setup_hub()
	
	_transition_to_game()
	var transitionTween = create_tween().set_parallel(true)
	
	transitionTween.tween_property(infinityContainer, "position:y", infinityContainer.position.y - moveDistance, transitionDuration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).set_delay(0.15)
	transitionTween.tween_property(infinityContainer, "modulate:a", 0.0, transitionDuration / 8.0).set_delay(0.15)
	transitionTween.tween_property($ColorRect, "modulate:a", 0.0, 0.5)
	
	await transitionTween.finished
	infinityContainer.hide()


func _transition_to_game() -> void:
	GameStats.showHoldoutTutorial = false
	GameStats.save_game()
	
	%HoldoutHub.show_hub()
