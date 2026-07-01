extends Node2D

@onready var orbitContainer = $OrbitContainer

var delayBeforeTransition: float = 4.5
var transitionDuration: float = 1.4
var moveDistance: float = 700.0

func _ready() -> void:
	if SaveManager.isLoadingSave:
		hide()
		set_process(false)
		return

	await _trigger_transition()
	

func _trigger_transition() -> void:
	await get_tree().create_timer(delayBeforeTransition).timeout
	
	AudioManager.play_whoosh(true)
	
	orbitContainer.process_mode = Node.PROCESS_MODE_DISABLED
	%HoldoutHub.show()
	%HoldoutHub._setup_hub()
	
	_transition_to_game()
	var transitionTween = create_tween().set_parallel(true)
	
	transitionTween.tween_property(orbitContainer, "position:y", orbitContainer.position.y - moveDistance, transitionDuration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).set_delay(0.15)
	transitionTween.tween_property(orbitContainer, "modulate:a", 0.0, transitionDuration / 8.0).set_delay(0.15)
	transitionTween.tween_property($ColorRect, "modulate:a", 0.0, 0.5)
	
	await transitionTween.finished
	orbitContainer.hide()

func _transition_to_game() -> void:
	GameStats.showHoldoutTutorial = false
	GameStats.save_game()
	
	%HoldoutHub.show_hub()
