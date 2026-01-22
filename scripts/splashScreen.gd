extends Node2D

func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	GameStats.gameMode = GameStats.Mode.SPLASH_SCREEN
	
	# Disclaimer
	fade_out()
	await get_tree().create_timer(7).timeout
	await fade_in()
	
	$Disclaimer.hide()
	$MadeBy.show()
	
	# A game made by
	fade_out()
	
	await get_tree().create_timer(5).timeout
	#var nameTween = create_tween()
	#nameTween.tween_property($MadeBy/Name, "modulate:a", 1.0, 1)
	#await nameTween.finished
	#await get_tree().create_timer(2).timeout
	
	await fade_in()
	
	$MadeBy.hide()
	$MadeWith.show()
	
	# Made with Godot
	fade_out()
	
	await get_tree().create_timer(1).timeout
	
	$MadeWith/AnimationPlayer.play("flickerOut")
	
	# Potential animation in here
	await get_tree().create_timer(7).timeout
	
	await fade_in()
	
	$MadeWith.hide()
	$TitleScreen.show()
	
	# Title Card
	fade_out()
	
	# Potential animation in here
	await get_tree().create_timer(5).timeout
	
	GameStats.gameMode = GameStats.Mode.MAIN_MENU
	Curtain.change_scene("res://scenes/mainMenu.tscn", 2.0)

func fade_in():
	$fader.visible = true
	var inTween = create_tween()
	inTween.tween_property($fader, "modulate:a", 1.0, 1)
	
	await inTween.finished

func fade_out():
	var outTween = create_tween()
	outTween.tween_property($fader, "modulate:a", 0.0, 1)
	
	await outTween.finished
	$fader.visible = false
