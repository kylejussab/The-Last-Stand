extends Node2D

func _ready() -> void:
	GameStats.gameMode = "Splash Screens"
	
	# Disclaimer
	fade_out()
	await get_tree().create_timer(7).timeout
	await fade_in()
	
	$Disclaimer.hide()
	$MadeBy.show()
	
	# A game made by
	fade_out()
	
	await get_tree().create_timer(2).timeout
	var nameTween = create_tween()
	nameTween.tween_property($MadeBy/Name, "modulate:a", 1.0, 1)
	await nameTween.finished
	await get_tree().create_timer(2).timeout
	
	await fade_in()
	
	$MadeBy.hide()
	$MadeWith.show()
	
	# Made with Godot
	fade_out()
	
	# Potential animation in here
	await get_tree().create_timer(5).timeout
	
	await fade_in()
	
	$MadeWith.hide()
	$TitleScreen.show()
	
	# Title Card
	fade_out()
	
	# Potential animation in here
	await get_tree().create_timer(7).timeout
	
	GameStats.gameMode = "Main Menu"
	Curtain.change_scene("res://scenes/mainMenu.tscn")

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
