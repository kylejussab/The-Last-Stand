extends Control

const ARROW = preload("res://core/menus/subcomponents/ArrowLeft.png")
const ARROW_HOVER = preload("res://core/menus/subcomponents/ArrowLeftPressed.png")
const ARROW_EMPTY = preload("res://core/menus/subcomponents/ArrowLeftNone.png")

var tutorialStep: int
var lastTutorialStep: int = 4

func _ready():
	$Navigation/LeftButton.mouse_entered.connect(_play_hover.bind($Navigation/LeftButton))
	$Navigation/LeftButton.focus_mode = Control.FOCUS_NONE
	
	$Navigation/RightButton.mouse_entered.connect(_play_hover.bind($Navigation/RightButton))
	$Navigation/RightButton.focus_mode = Control.FOCUS_NONE
	
	%StartNewRunButton.mouse_entered.connect(func(): _play_hover(%StartNewRunButton))


func reset() -> void:
	tutorialStep = 1
	%StartNewRunButton.visible = false
	%StartNewRunButton.disabled = true
	$Number.visible = true
	
	_update_button_graphics()
	_update_tutorial_graphics(tutorialStep)


func _on_left_button_pressed() -> void:
	_change_tutorial_step(-1)


func _on_right_button_pressed() -> void:
	_change_tutorial_step(1)


func _change_tutorial_step(direction: int) -> void:
	var nextStep = tutorialStep + direction
	
	if nextStep < 1 or nextStep > lastTutorialStep:
		return
	
	tutorialStep += direction
	AudioManager.play_button_click()
	
	_update_button_graphics()
	_update_tutorial_graphics(tutorialStep)


func _update_button_graphics() -> void:
	if tutorialStep == 1:
		$Navigation/LeftButton.texture_normal = ARROW_EMPTY
		$Navigation/LeftButton.texture_hover = ARROW_EMPTY
	else:
		$Navigation/LeftButton.texture_normal = ARROW
		$Navigation/LeftButton.texture_hover = ARROW_HOVER
	
	if tutorialStep == lastTutorialStep:
		$Navigation/RightButton.texture_normal = ARROW_EMPTY
		$Navigation/RightButton.texture_hover = ARROW_EMPTY
	else:
		$Navigation/RightButton.texture_normal = ARROW
		$Navigation/RightButton.texture_hover = ARROW_HOVER


func _update_tutorial_graphics(step: int) -> void:
	match step:
		1:
			$"Number".text = "1/4"
			$"Heading".text = "HOLDOUT"
			$"Image".texture = load("res://holdout/tutorial/onStart/1.png")
			$"Body".text = "In Holdout, you and your opponent draw from the same shared deck."
			
			%StartNewRunButton.disabled = true
			%StartNewRunButton.visible = false
		2:
			$"Number".text = "2/4"
			$"Heading".text = "WINNING A ROUND"
			$"Image".texture = load("res://holdout/tutorial/onStart/2.png")
			$"Body".text = "Each round, you and your opponent play a character card.\nThe higher value wins, and the difference is the damage dealt."
		3:
			$"Number".text = "3/4"
			$"Heading".text = "PERKS AND SUPPORTS"
			$"Image".texture = load("res://holdout/tutorial/onStart/3.png")
			$"Body".text = "After characters are played, you can play an optional support card to swing the odds.\nPerks on your cards can increase your value, or decrease your opponent’s."
		4:
			$"Number".text = "4/4"
			$"Heading".text = "YOU ARE ALL SET"
			$"Image".texture = load("res://holdout/tutorial/onStart/4.png")
			$"Body".text = "That is everything you needed to get started.\nYou can always view more detailed help in the pause menu."
			
			%StartNewRunButton.disabled = false
			%StartNewRunButton.visible = true


func _play_hover(btn: Control):
	if "texture_nomral" in btn and btn.texture_normal == ARROW_EMPTY:
		return
	
	AudioManager.play_button_hover()


func _on_start_new_run_button_pressed() -> void:
	AudioManager.play_button_click()
	$".."._on_new_button_hold_complete()
	GameStats.showHoldoutTutorial = false # If we've seen it once it doesnt need to come again
