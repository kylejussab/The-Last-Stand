extends Node2D

@onready var optionsMenu = $OptionsMenu

@onready var backgroundImage = $image
@onready var mainButtonContainer = $mainButtonContainer
@onready var storyButtonContainer = $storyButtonContainer
@onready var holdoutButtonContainer = $holdoutButtonContainer

@onready var supplementText = $supplementText

var currentNavigation: String = "Main"

const BACKGROUNDS = {
	"Main": preload("res://assets/mainMenu/main.png"),
	"June": preload("res://assets/mainMenu/june.png"),
}

const SUPPLEMENTTEXT = {
	"Story": "What is the cost of doing what you believe is right?",
	"Holdout": "A roguelite gauntlet where you overcome escalating enemies and unpredictable modifiers.\n\nYeilds: [img width=14 color=#4c4c4c]res://assets/ui/RationsIconSlim.png[/img]",
	"June": "What is the cost of doing what you believe is right?",
	"Remnants": "A tactical deck-building campaign where you lead a Faction, master card synergies, and secure territory.\n\nYeilds: [img width=14 color=#4c4c4c]res://assets/ui/RationsIconSlim.png[/img]"
}

# Card for Accessibility Card Graphics
var previewCard: Node2D = null

func _ready() -> void:
	optionsMenu.options_exited.connect(_on_options_menu_exited)
	
	setup_button_sounds(mainButtonContainer)
	setup_button_sounds(storyButtonContainer)
	setup_button_sounds(holdoutButtonContainer)
	
	if GameStats.invitationAccepted:
		$pressAnywhere.hide()
		mainButtonContainer.show()
		mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		$pressAnywhere.show()
		mainButtonContainer.hide()
		mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
		pulse_text()
	
	_show_continue_button()

func pulse_text():
	var pulse = create_tween().set_loops()
	
	pulse.tween_property($pressAnywhere/text, "modulate:a", 0.3, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property($pressAnywhere/text, "modulate:a", 1.0, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _input(event: InputEvent) -> void:
	if !GameStats.invitationAccepted and (event is InputEventMouseButton and event.pressed):
		GameStats.invitationAccepted = true
		AudioManager.play_button_click()
		
		AudioManager.change_volume_layer1(-20, 5.0)
		AudioManager.change_volume_layer2(-80, 5.0)
		
		mainButtonContainer.modulate.a = 0.0
		mainButtonContainer.show()
		
		var outTween = create_tween()
		outTween.tween_property($pressAnywhere, "modulate:a", 0.0, 0.3)
		await outTween.finished
		$pressAnywhere.hide()
		
		var inTween = create_tween()
		inTween.tween_property(mainButtonContainer, "modulate:a", 1.0, 0.3)
		await inTween.finished
		
		mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and currentNavigation != "Main":
		AudioManager.play_button_back()
		
		if currentNavigation == "Story":
			$pauseIcon.hide()
			currentNavigation = "Main"
			storyButtonContainer.hide()
			storyButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
			
			backgroundImage.texture = BACKGROUNDS["Main"]
			
			mainButtonContainer.show()
			mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
		elif currentNavigation == "Holdout":
			$pauseIcon.hide()
			currentNavigation = "Main"
			holdoutButtonContainer.hide()
			holdoutButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
			
			backgroundImage.texture = BACKGROUNDS["Main"]
			
			mainButtonContainer.show()
			mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT

func setup_button_sounds(container: Node):
	for child in container.get_children():
		if child is Button:
			child.mouse_entered.connect(AudioManager.play_button_hover)
			child.pressed.connect(AudioManager.play_button_click)
			
			child.focus_mode = Control.FOCUS_NONE

func _on_story_button_mouse_entered() -> void:
	supplementText.text = SUPPLEMENTTEXT["Story"]

func _on_story_button_mouse_exited() -> void:
	supplementText.text = ""

func _on_story_button_pressed() -> void:
	_play_denied_animation($mainButtonContainer/StoryButton)
	
	#$pauseIcon.show()
	#currentNavigation = "Story"
	#
	#mainButtonContainer.hide()
	#mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	#
	#storyButtonContainer.show()
	#storyButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT

func _on_june_button_mouse_entered() -> void:
	backgroundImage.texture = BACKGROUNDS["June"]
	supplementText.text = SUPPLEMENTTEXT["June"]

func _on_june_button_mouse_exited() -> void:
	backgroundImage.texture = BACKGROUNDS["Main"]
	supplementText.text = ""

func _on_june_button_pressed() -> void:
	#GameStats.gameMode = GameStats.Mode.JUNE_RAVEL
	#Curtain.change_scene("res://scenes/main.tscn")
	pass

func _on_holdout_button_mouse_entered() -> void:
	supplementText.text = SUPPLEMENTTEXT["Holdout"]

func _on_holdout_button_mouse_exited() -> void:
	supplementText.text = ""

func _on_holdout_button_pressed() -> void:
	$pauseIcon.show()
	currentNavigation = "Holdout"
	
	mainButtonContainer.hide()
	mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	holdoutButtonContainer.show()
	holdoutButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT

func _on_new_button_mouse_entered() -> void:
	$holdIcon.show()

func _on_new_button_mouse_exited() -> void:
	$holdIcon.hide()

func _on_new_button_hold_complete() -> void:
	GameStats.gameMode = GameStats.Mode.HOLDOUT
	HoldoutStats.reset_for_new_run()
	
	Curtain.change_scene("res://scenes/main.tscn")
	
	AudioManager.stop_music(2.5)
	
	AudioManager.start_background_playlist()

func _on_continue_button_pressed() -> void:
	if SaveManager.has_holdout_save():
		AudioManager.play_button_click()
		
		SaveManager.isLoadingSave = true 
		GameStats.gameMode = GameStats.Mode.HOLDOUT
		
		Curtain.change_scene("res://scenes/main.tscn")
		AudioManager.stop_music(2.5)
		
		AudioManager.start_background_playlist()
	else:
		_play_denied_animation($holdoutButtonContainer/ContinueButton)

func _on_remnants_button_mouse_entered() -> void:
	supplementText.text = SUPPLEMENTTEXT["Remnants"]

func _on_remnants_button_mouse_exited() -> void:
	supplementText.text = ""

func _on_achievements_button_pressed() -> void:
	_play_denied_animation($holdoutButtonContainer/AchievementsButton)

func _on_remnants_button_pressed() -> void:
	_play_denied_animation($mainButtonContainer/RemnantsButton)

func _on_options_button_pressed() -> void:
	$pauseIcon.show()
	currentNavigation = "Options"
	backgroundImage.texture = null
	
	mainButtonContainer.hide()
	mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	optionsMenu.open()

func _on_options_menu_exited() -> void:
	$pauseIcon.hide()
	currentNavigation = "Main"
	backgroundImage.texture = BACKGROUNDS["Main"]
	
	_show_continue_button()
	
	mainButtonContainer.show()
	mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT

func _on_quit_button_pressed() -> void:
	if OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		get_tree().quit()

# Privates
func _play_denied_animation(currentButton: Button):
	var originalPos = currentButton.position.x
	var shake_offset = 5.0
	var duration = 0.05
	
	var tween = create_tween()
	tween.tween_property(currentButton, "position:x", originalPos + shake_offset, duration)
	tween.tween_property(currentButton, "position:x", originalPos - shake_offset, duration)
	tween.tween_property(currentButton, "position:x", originalPos, duration)

func _show_continue_button() -> void:
	if SaveManager.has_holdout_save():
		%ContinueButton.visible = true
		%ContinueButton.disabled = false
		
		%AchievementsButton.position.y = 500
		$"holdoutButtonContainer/Temporary Lock Icons/Lock2".position.y = 525
	else:
		%ContinueButton.visible = false
		%ContinueButton.disabled = true
		
		%AchievementsButton.position.y = 450
		$"holdoutButtonContainer/Temporary Lock Icons/Lock2".position.y = 475
