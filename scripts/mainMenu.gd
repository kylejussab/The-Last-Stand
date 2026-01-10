extends Node2D

@onready var backgroundImage = $image
@onready var mainButtonContainer = $mainButtonContainer
@onready var storyButtonContainer = $storyButtonContainer
@onready var lastStandButtonContainer = $lastStandButtonContainer
@onready var optionsButtonContainer = $optionsButtonContainer

@onready var supplementText = $supplementText

var currentNavigation: String = "Main"

const BACKGROUNDS = {
	"Main": preload("res://assets/mainMenu/main.png"),
	"June": preload("res://assets/mainMenu/june.png"),
}

const SUPPLEMENTTEXT = {
	"Story": "Play through a choice of three different survivor stories.",
	"Last Stand": "Survive as many waves as possible with boosted health and no healing.",
	"June": "What is the cost of doing what you believe is right?"
}

func _ready() -> void:
	setup_button_sounds(mainButtonContainer)
	setup_button_sounds(storyButtonContainer)
	setup_button_sounds(lastStandButtonContainer)
	setup_button_sounds(optionsButtonContainer)
	
	if GameStats.invitationAccepted:
		$pressAnywhere.hide()
		mainButtonContainer.show()
		mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		$pressAnywhere.show()
		mainButtonContainer.hide()
		mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
		pulse_text()

func pulse_text():
	var pulse = create_tween().set_loops()
	
	pulse.tween_property($pressAnywhere/text, "modulate:a", 0.3, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property($pressAnywhere/text, "modulate:a", 1.0, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _input(event: InputEvent) -> void:
	if !GameStats.invitationAccepted and (event is InputEventMouseButton and event.pressed):
		GameStats.invitationAccepted = true
		_play_click()
		
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
		_play_back()
		
		if currentNavigation == "Story":
			$pauseIcon.hide()
			currentNavigation = "Main"
			storyButtonContainer.hide()
			storyButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
			
			backgroundImage.texture = BACKGROUNDS["Main"]
			
			mainButtonContainer.show()
			mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
		elif currentNavigation == "Last Stand":
			$pauseIcon.hide()
			currentNavigation = "Main"
			lastStandButtonContainer.hide()
			lastStandButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
			
			backgroundImage.texture = BACKGROUNDS["Main"]
			
			mainButtonContainer.show()
			mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
		elif currentNavigation == "Options":
			$pauseIcon.hide()
			currentNavigation = "Main"
			optionsButtonContainer.hide()
			optionsButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
			
			backgroundImage.texture = BACKGROUNDS["Main"]
			
			mainButtonContainer.show()
			mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT

func setup_button_sounds(container: Node):
	for child in container.get_children():
		if child is Button:
			child.mouse_entered.connect(_play_hover)
			child.pressed.connect(_play_click)
			
			child.focus_mode = Control.FOCUS_NONE

func _on_story_button_mouse_entered() -> void:
	supplementText.text = SUPPLEMENTTEXT["Story"]

func _on_story_button_mouse_exited() -> void:
	supplementText.text = ""

func _on_story_button_pressed() -> void:
	$pauseIcon.show()
	currentNavigation = "Story"
	
	mainButtonContainer.hide()
	mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	storyButtonContainer.show()
	storyButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT

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

func _on_last_stand_button_mouse_entered() -> void:
	supplementText.text = SUPPLEMENTTEXT["Last Stand"]

func _on_last_stand_button_mouse_exited() -> void:
	supplementText.text = ""

func _on_last_stand_button_pressed() -> void:
	$pauseIcon.show()
	currentNavigation = "Last Stand"
	
	mainButtonContainer.hide()
	mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	lastStandButtonContainer.show()
	lastStandButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT

func _on_new_button_pressed() -> void:
	GameStats.gameMode = GameStats.Mode.LAST_STAND
	Curtain.change_scene("res://scenes/main.tscn")

func _on_options_button_pressed() -> void:
	$pauseIcon.show()
	currentNavigation = "Options"
	
	mainButtonContainer.hide()
	mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	optionsButtonContainer.show()
	optionsButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT

func _on_quit_button_pressed() -> void:
	get_tree().quit()

# Helpers
func _play_hover():
	$ButtonHoverSound.play()

func _play_click():
	$ButtonClickSound.play()

func _play_back():
	$ButtonBackSound.play()
