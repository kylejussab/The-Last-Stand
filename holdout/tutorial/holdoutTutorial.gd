extends Control

const ARROW = preload("res://core/menus/subcomponents/ArrowLeft.png")
const ARROW_HOVER = preload("res://core/menus/subcomponents/ArrowLeftPressed.png")
const ARROW_EMPTY = preload("res://core/menus/subcomponents/ArrowLeftNone.png")

var tutorialStep: int
var lastTutorialStep: int = 7

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
			$"Number".text = "1/7"
			$"Heading".text = "HOLDOUT"
			$"Image".texture = load("res://holdout/tutorial/1.png")
			$"Body".text = "You start every run at 99 health, fighting opponents until you hit 0.\nBoth players draw from the same shared decks.\nYour goal is to survive as long as possible."
			
			if get_parent().name == "MainMenu":
				%StartNewRunButton.disabled = true
				%StartNewRunButton.visible = false
			elif get_parent().name == "pause":
				$Number.visible = false
		2:
			$"Number".text = "2/7"
			$"Heading".text = "WINNING A ROUND"
			$"Image".texture = load("res://holdout/tutorial/2.png")
			$"Body".text = "Each round, you and your opponent play a character card.\nThe higher value wins, and the difference is the damage dealt.\nYou drag or double-click a card to play it in its slot."
		3:
			$"Number".text = "3/7"
			$"Heading".text = "PERKS AND SUPPORTS"
			$"Image".texture = load("res://holdout/tutorial/3.png")
			$"Body".text = "After characters are played, you can play a support card to swing the odds.\nPerks on your cards can increase your value, or decrease your opponent’s."
		4:
			$"Number".text = "4/7"
			$"Heading".text = "YOUR HAND"
			$"Image".texture = load("res://holdout/tutorial/4.png")
			$"Body".text = "You start with 4 characters and 2 supports. Your hand holds up to 4 of each.\nCharacters are drawn automatically every round but supports every 3rd round.\nCharacters must be played; supports are optional.\nTurn order alternates every round."
		5:
			$"Number".text = "5/7"
			$"Heading".text = "MODIFIERS"
			$"Image".texture = load("res://holdout/tutorial/5.png")
			$"Body".text = "Opponents add modifiers that change the rules of the battle.\nYou’ll have chances to add your own modifiers during the run.\nModifiers also boost the rations you earn for other game modes."
		6:
			$"Number".text = "6/7"
			$"Heading".text = "ALLEGIANCES AND FACTIONS"
			$"Image".texture = load("res://holdout/tutorial/6.png")
			$"Body".text = "Every character belongs to one of 5 factions.\nStart your run by aligning with a faction to boost only your cards from that group.\nLater, you can improve that allegiance, or break it for a different faction."
		7:
			$"Number".text = "7/7"
			$"Heading".text = "YOU ARE ALL SET"
			$"Image".texture = load("res://holdout/tutorial/7.png")
			$"Body".text = "That is everything you needed to get started.\nYou can always view this again in the pause menu.\nReminder: You can customize card displays and other options in the accessibility menu."
			
			if get_parent().name == "MainMenu":
				%StartNewRunButton.disabled = false
				%StartNewRunButton.visible = true
				
			GameStats.showHoldoutTutorial = false # If we've seen it once it doesnt need to come again


func _play_hover(btn: Control):
	if "texture_nomral" in btn and btn.texture_normal == ARROW_EMPTY:
		return
	
	AudioManager.play_button_hover()


func _on_start_new_run_button_pressed() -> void:
	AudioManager.play_button_click()
	$".."._on_new_button_hold_complete()
