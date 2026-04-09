extends Node2D

@onready var orbit_container = $Container/OrbitContainer
@onready var heading = $Heading
@onready var animationPlayer = $AnimationPlayer

var delay_before_transition: float = 4.5
var transition_duration: float = 1.4
var move_distance: float = 700.0

var isActive: bool = true

func _ready() -> void:
	if SaveManager.isLoadingSave or GameStats.gameMode == GameStats.Mode.HOLDOUT_TUTORIAL:
		isActive = false
		hide()
		set_process(false)
		return
		
	for button in $Container.get_children():
		if button is Button:
			button.mouse_entered.connect(AudioManager.play_button_hover)
			button.pressed.connect(AudioManager.play_button_click)
			
	heading.position.y += move_distance
	heading.modulate.a = 0.0
	
	await _trigger_transition()
	
	await _show_tutorial_menu(GameStats.showHoldoutTutorial)
	
	if !GameStats.showHoldoutTutorial:
		_on_skip_holdout_tutorial_button_pressed()

func fade_out_screen(showTutorial: bool, duration: float = 1.0) -> void:
	$Container.process_mode = Node.PROCESS_MODE_DISABLED
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property($ColorRect, "modulate:a", 0.0, duration)
	
	if showTutorial:
		tween.tween_property($Container, "modulate:a", 0.0, duration / 4)
	
	tween.tween_property(heading, "modulate:a", 0.0, duration).set_delay(duration / 3)
	
	$Container/PlayHoldoutButton.visible = false
	$Container/SkipHoldoutTutorialButton.visible = false
	$Container/PlayHoldoutButton.disabled = true
	$Container/SkipHoldoutTutorialButton.disabled = true

func _trigger_transition() -> void:
	if not isActive:
		orbit_container.hide()
		orbit_container.set_process(false) 
		return
	
	await get_tree().create_timer(delay_before_transition).timeout
	
	var transition_tween = create_tween().set_parallel(true)
	
	AudioManager.play_whoosh(true)
	
	transition_tween.tween_property(heading, "position:y", heading.position.y - move_distance, transition_duration / 2.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	transition_tween.tween_property(heading, "modulate:a", 1.0, transition_duration / 2.0)
	
	transition_tween.tween_property(orbit_container, "position:y", orbit_container.position.y - move_distance, transition_duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).set_delay(.15)
	transition_tween.tween_property(orbit_container, "modulate:a", 0.0, transition_duration / 8.0).set_delay(.15)
	
	await transition_tween.finished
	
	orbit_container.hide()
	orbit_container.set_process(false)

func _show_tutorial_menu(showTutorial: bool) -> void:
	if showTutorial:
		$Container/PlayHoldoutButton.visible = true
		$Container/SkipHoldoutTutorialButton.visible = true
		
		animationPlayer.play("show_tutorial")
		await animationPlayer.animation_finished
		
		$Container/PlayHoldoutButton.disabled = false
		$Container/SkipHoldoutTutorialButton.disabled = false

func _on_play_holdout_button_pressed() -> void:
	fade_out_screen(true, 1.0)
	GameStats.gameMode = GameStats.Mode.HOLDOUT_TUTORIAL 
	%battleManager.start_tutorial()

func _on_skip_holdout_tutorial_button_pressed() -> void:
	fade_out_screen(true, 2.0)
	
	GameStats.showHoldoutTutorial = false
	GameStats.save_game()
	
	%battleManager.initialize_game()
