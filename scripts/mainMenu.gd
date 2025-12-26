extends Node2D

@onready var backgroundImage = $image
@onready var mainButtonContainer = $mainButtonContainer
@onready var storyButtonContainer = $storyButtonContainer

@onready var supplementText = $supplementText

const BACKGROUNDS = {
	"Main": preload("res://assets/mainMenu/main.png"),
	"June": preload("res://assets/mainMenu/june.png"),
}

const SUPPLEMENTTEXT = {
	"Story": "Play through a choice of three different survivor stories.",
	"Last Stand": "Survive as many waves as possible with boosted health and no healing.",
	"Tutorial": "Coming soon.",
	"Options": "Coming soon.",
	"June": "What is the cost of doing what you believe is right?"
}

func _ready() -> void:
	setup_button_sounds(mainButtonContainer)
	setup_button_sounds(storyButtonContainer)
	
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
	if !GameStats.invitationAccepted and (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
		GameStats.invitationAccepted = true
		_play_click()
		
		$pressAnywhere.hide()
		mainButtonContainer.show()
		mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT

func setup_button_sounds(container: Node):
	for child in container.get_children():
		if child is Button:
			child.mouse_entered.connect(_play_hover)
			child.pressed.connect(_play_click)

func _on_story_button_mouse_entered() -> void:
	supplementText.text = SUPPLEMENTTEXT["Story"]

func _on_story_button_mouse_exited() -> void:
	supplementText.text = ""

func _on_story_button_pressed() -> void:
	mainButtonContainer.hide()
	mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	storyButtonContainer.show()
	storyButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT

func _on_last_stand_button_mouse_entered() -> void:
	supplementText.text = SUPPLEMENTTEXT["Last Stand"]

func _on_last_stand_button_mouse_exited() -> void:
	supplementText.text = ""

func _on_last_stand_button_pressed() -> void:
	GameStats.gameMode = "Last Stand"
	Curtain.change_scene("res://scenes/main.tscn")

func _on_tutorial_button_mouse_entered() -> void:
	supplementText.text = SUPPLEMENTTEXT["Tutorial"]

func _on_tutorial_button_mouse_exited() -> void:
	supplementText.text = ""

func _on_options_button_mouse_entered() -> void:
	supplementText.text = SUPPLEMENTTEXT["Options"]

func _on_options_button_mouse_exited() -> void:
	supplementText.text = ""

func _on_back_button_pressed() -> void:
	storyButtonContainer.hide()
	storyButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	backgroundImage.texture = BACKGROUNDS["Main"]
	
	mainButtonContainer.show()
	mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT

func _on_june_button_mouse_entered() -> void:
	backgroundImage.texture = BACKGROUNDS["June"]
	supplementText.text = SUPPLEMENTTEXT["June"]

func _on_june_button_mouse_exited() -> void:
	backgroundImage.texture = BACKGROUNDS["Main"]
	supplementText.text = ""

func _on_quit_button_pressed() -> void:
	get_tree().quit()

# Helpers
func _play_hover():
	$ButtonHoverSound.play()

func _play_click():
	$ButtonClickSound.play()
