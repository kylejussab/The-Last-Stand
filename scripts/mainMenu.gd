extends Node2D

@onready var optionsMenu = $OptionsMenu

@onready var backgroundImage = $image
@onready var mainButtonContainer = $mainButtonContainer
@onready var storyButtonContainer = $storyButtonContainer
@onready var holdoutButtonContainer = $holdoutButtonContainer
@onready var holdoutStatsContainer = $StatisticsMenu

# Background sprites
@onready var holdoutBg = $holdoutButtonContainer/Background
@onready var holdoutFg = $holdoutButtonContainer/Foreground

var startingHoldoutBackgroundPosition: Vector2
var startingHoldoutForegroundPosition: Vector2

var parallax_tween: Tween
var is_parallax_hovered: bool = false

const PARALLAX_DURATION: float = 0.6 # How long the tween takes
const HOVER_DELAY: float = 0.1 # Delay before tweening to prevent jitter

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
	startingHoldoutBackgroundPosition = holdoutBg.position
	startingHoldoutForegroundPosition = holdoutFg.position
	$versionNumber.hide()
	
	optionsMenu.options_exited.connect(_on_options_menu_exited)
	
	setup_button_sounds(mainButtonContainer)
	setup_button_sounds(storyButtonContainer)
	setup_button_sounds(holdoutButtonContainer)
	
	if GameStats.invitationAccepted:
		$pressAnywhere.hide()
		$versionNumber.show()
		mainButtonContainer.show()
		mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		$pressAnywhere.show()
		mainButtonContainer.hide()
		mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
		pulse_text()
	
	_show_continue_button()
	_show_tutorial_button()
	_show_statistics_button()
	
	if OS.has_feature("web"):
		$mainButtonContainer/QuitButton.hide()

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
		$versionNumber.show()
		
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
			await Curtain.fade_in(0.75)
			$pauseIcon.hide()
			currentNavigation = "Main"
			holdoutButtonContainer.hide()
			holdoutButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
			
			backgroundImage.texture = BACKGROUNDS["Main"]
			
			mainButtonContainer.show()
			mainButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
			Curtain.fade_out(0.75)
		elif currentNavigation == "HoldoutStatistics":
			currentNavigation = "Holdout"
			await Curtain.fade_in(0.25)
			
			holdoutStatsContainer.hide()
			
			holdoutButtonContainer.show()
			holdoutButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
			Curtain.fade_out(0.25)

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
	pass

func _on_holdout_button_mouse_entered() -> void:
	supplementText.text = SUPPLEMENTTEXT["Holdout"]

func _on_holdout_button_mouse_exited() -> void:
	supplementText.text = ""

func _on_holdout_button_pressed() -> void:
	await Curtain.fade_in(0.75)
	$pauseIcon.show()
	currentNavigation = "Holdout"
	
	mainButtonContainer.hide()
	mainButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	
	holdoutButtonContainer.show()
	holdoutButtonContainer.process_mode = Node.PROCESS_MODE_INHERIT
	
	await get_tree().create_timer(0.5).timeout
	
	Curtain.fade_out(0.75)

func _on_new_button_mouse_entered() -> void:
	$holdIcon.show()
	_start_parallax_effect()

func _on_new_button_mouse_exited() -> void:
	$holdIcon.hide()
	_stop_parallax_effect()

func _on_new_button_hold_complete() -> void:
	GameStats.gameMode = GameStats.Mode.HOLDOUT
	HoldoutStats.reset_for_new_run()
	
	Curtain.change_scene("res://scenes/holdoutGame.tscn")
	
	AudioManager.stop_music(2.5)
	
	AudioManager.start_background_playlist()

func _on_continue_button_mouse_entered() -> void:
	_start_parallax_effect()

func _on_continue_button_mouse_exited() -> void:
	_stop_parallax_effect()

func _on_continue_button_pressed() -> void:
	if SaveManager.has_holdout_save():
		AudioManager.play_button_click()
		
		SaveManager.isLoadingSave = true 
		GameStats.gameMode = GameStats.Mode.HOLDOUT
		
		Curtain.change_scene("res://scenes/holdoutGame.tscn", 1.0, 0.75) # wait .75 seconds while the screen is black for scene load
		AudioManager.stop_music(2.5)
		
		AudioManager.start_background_playlist()
	else:
		_play_denied_animation($holdoutButtonContainer/ContinueButton)

func _on_tutorial_button_mouse_entered() -> void:
	_start_parallax_effect()

func _on_tutorial_button_mouse_exited() -> void:
	_stop_parallax_effect()

func _on_tutorial_button_pressed() -> void:
	AudioManager.play_button_click()
	AudioManager.stop_music(2.5) 
	
	GameStats.gameMode = GameStats.Mode.HOLDOUT_TUTORIAL 
	
	Curtain.change_scene("res://scenes/holdoutGame.tscn", 1.0, 0.75) # wait .75 seconds while the screen is black for scene load
	
	AudioManager.start_background_playlist()

func _on_statistics_button_pressed() -> void:
	holdoutButtonContainer.process_mode = Node.PROCESS_MODE_DISABLED
	currentNavigation = "HoldoutStatistics"
	
	await Curtain.fade_in(0.25)
	_update_stats_screen()
	
	holdoutButtonContainer.hide()
	holdoutStatsContainer.show()
	
	Curtain.fade_out(0.25)

func _on_remnants_button_mouse_entered() -> void:
	supplementText.text = SUPPLEMENTTEXT["Remnants"]

func _on_remnants_button_mouse_exited() -> void:
	supplementText.text = ""

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
	_show_tutorial_button()
	_show_statistics_button()
	
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

		%TutorialButton.position.y = 500
		%StatisticsButton.position.y = 550
	else:
		%ContinueButton.visible = false
		%ContinueButton.disabled = true
		
		%TutorialButton.position.y = 450
		%StatisticsButton.position.y = 500

func _show_tutorial_button() -> void:
	if !GameStats.showHoldoutTutorial:
		%TutorialButton.visible = true
		%TutorialButton.disabled = false
	else:
		%TutorialButton.visible = false
		%TutorialButton.disabled = true

func _show_statistics_button() -> void:
	%StatisticsButton.visible = false
	%StatisticsButton.disabled = true
	
	if SaveManager.has_main_save():
		var saveData = SaveManager.load_main_state()
		var modifierCounts = saveData.get("holdoutModifierUses", {})
		
		if modifierCounts.size() >= 3:
			%StatisticsButton.visible = true
			%StatisticsButton.disabled = false

func _start_parallax_effect() -> void:
	is_parallax_hovered = true
	
	await get_tree().create_timer(HOVER_DELAY).timeout
	
	if not is_parallax_hovered:
		return
		
	if parallax_tween and parallax_tween.is_valid():
		parallax_tween.kill()
		
	parallax_tween = create_tween().set_parallel(true)
	parallax_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	parallax_tween.tween_property(holdoutBg, "position:x", 1050, PARALLAX_DURATION)
	parallax_tween.tween_property(holdoutFg, "position:x", 880, PARALLAX_DURATION)

func _stop_parallax_effect() -> void:
	is_parallax_hovered = false
	
	await get_tree().create_timer(HOVER_DELAY).timeout
	
	if is_parallax_hovered:
		return
		
	if parallax_tween and parallax_tween.is_valid():
		parallax_tween.kill()
		
	parallax_tween = create_tween().set_parallel(true)
	parallax_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	parallax_tween.tween_property(holdoutBg, "position:x", startingHoldoutBackgroundPosition.x, PARALLAX_DURATION)
	parallax_tween.tween_property(holdoutFg, "position:x", startingHoldoutForegroundPosition.x, PARALLAX_DURATION)

func _update_stats_screen() -> void:
	var saveData = SaveManager.load_main_state()
	
	$StatisticsMenu/mainStats/RunsAttemptedValue.text = str(int(saveData.get("holdoutRunsAttempted", 0)))
	$StatisticsMenu/mainStats/OpponentsDefeatedValue.text = str(int(saveData.get("holdoutBattlesWon", 0)))
	$StatisticsMenu/mainStats/CardsPlayedValue.text = str(int(saveData.get("holdoutCardsPlayed", 0)))
	$StatisticsMenu/mainStats/TimePlayedValue.text = _format_time(saveData.get("holdoutTimePlayed", 0))
	
	$StatisticsMenu/mainStats/FastestWinValue.text = _format_time(saveData.get("holdoutFastestWin", 0))
	$StatisticsMenu/mainStats/HighestDominanceValue.text = str(int(saveData.get("holdoutHighestDominance", 0)))
	$StatisticsMenu/mainStats/WinStreakValue.text = str(int(saveData.get("holdoutLongestStreak", 0)))
	$StatisticsMenu/mainStats/UnderdogWinsValue.text = str(int(saveData.get("holdoutUnderdogWins", 0)))
	
	var accoladeCounts = saveData.get("holdoutAccoladeCounts", {})
	var accoladesContainer = $StatisticsMenu/accolades
	
	for accoladeKey in HoldoutStats.ACCOLADES.keys():
		
		var count = int(accoladeCounts.get(accoladeKey, 0))
		
		if accoladesContainer.has_node(accoladeKey):
			var uiNode = accoladesContainer.get_node(accoladeKey)
			var icon = uiNode.get_node("Icon")
			var label = uiNode.get_node("Label")
			
			if count > 0:
				icon.modulate = Color("6c6c6c")
				label.text = "Earned: " + str(count)
			else:
				icon.modulate = Color("2c2c2c") 
				label.text = "Not Earned"
	
	# MVPs
	var mvpCounts = saveData.get("holdoutMvpCounts", {})
	
	var sortedKeys = mvpCounts.keys()
	
	sortedKeys.sort_custom(func(a, b): return mvpCounts[a] > mvpCounts[b])
	
	for i in range(1, 4):
		var mvpNode = get_node("StatisticsMenu/mvps/" + str(i))
		
		if i <= sortedKeys.size():
			var cardKey = sortedKeys[i-1]
			var texturePath = "res://assets/holdout/mvp/" + cardKey + ".png"
			
			if ResourceLoader.exists(texturePath):
				mvpNode.texture = load(texturePath)
	
	var modifierCounts = saveData.get("holdoutModifierUses", {})
	
	var sortedModKeys = modifierCounts.keys()
	
	sortedModKeys.sort_custom(func(a, b): return modifierCounts[a] > modifierCounts[b])
	
	for i in range(1, 4):
		var modNode = get_node("StatisticsMenu/modifiers/" + str(i))
		var modKey = sortedModKeys[i-1]
		var texturePath = "res://assets/holdout/mods/" + modKey + ".png"
		
		if ResourceLoader.exists(texturePath):
			modNode.texture = load(texturePath)
			modNode.modulate = Color("8c8c8c")

func _format_time(time: float) -> String:
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	return "%02d:%02d" % [minutes, seconds]

# Accolade hover functionality
func _place_and_populate_tooltip(parent: Control, xOffset: float = -45.0, yOffset: float = -108.0) -> void:
	$StatisticsMenu/Tooltip.global_position = Vector2(parent.global_position.x + xOffset, parent.global_position.y + yOffset)
	$StatisticsMenu/Tooltip.get_node("Name").text = HoldoutStats.ACCOLADES[parent.name].title.to_upper()
	$StatisticsMenu/Tooltip.get_node("Description").text = HoldoutStats.ACCOLADES[parent.name].description

var tooltipTween: Tween
var currentHoveredAccolade: Control = null

func _show_accolade_tooltip(accolade: Control) -> void:
	currentHoveredAccolade = accolade
	AudioManager.play_card_hover()
	
	await get_tree().create_timer(0.15).timeout
	
	if currentHoveredAccolade == accolade:
		_place_and_populate_tooltip(accolade)
		
		if tooltipTween and tooltipTween.is_valid():
			tooltipTween.kill()
		
		
		tooltipTween = create_tween()
		tooltipTween.tween_property($StatisticsMenu/Tooltip, "modulate:a", 1.0, 0.15)

func _hide_accolade_tooltip() -> void:
	currentHoveredAccolade = null 
	
	if tooltipTween and tooltipTween.is_valid():
		tooltipTween.kill()
		
	tooltipTween = create_tween()
	tooltipTween.tween_property($StatisticsMenu/Tooltip, "modulate:a", 0.0, 0.1)

func _on_analysis_paralysis_mouse_entered() -> void:
	_show_accolade_tooltip($StatisticsMenu/accolades/AnalysisParalysis)

func _on_analysis_paralysis_mouse_exited() -> void:
	_hide_accolade_tooltip()

func _on_brawler_mouse_entered() -> void:
	_show_accolade_tooltip($StatisticsMenu/accolades/Brawler)

func _on_brawler_mouse_exited() -> void:
	_hide_accolade_tooltip()

func _on_executioner_mouse_entered() -> void:
	_show_accolade_tooltip($StatisticsMenu/accolades/Executioner)

func _on_executioner_mouse_exited() -> void:
	_hide_accolade_tooltip()

func _on_giant_slayer_mouse_entered() -> void:
	_show_accolade_tooltip($StatisticsMenu/accolades/GiantSlayer)

func _on_giant_slayer_mouse_exited() -> void:
	_hide_accolade_tooltip()

func _on_old_wounds_mouse_entered() -> void:
	_show_accolade_tooltip($StatisticsMenu/accolades/OldWounds)

func _on_old_wounds_mouse_exited() -> void:
	_hide_accolade_tooltip()

func _on_purist_mouse_entered() -> void:
	_show_accolade_tooltip($StatisticsMenu/accolades/Purist)

func _on_purist_mouse_exited() -> void:
	_hide_accolade_tooltip()

func _on_quick_draw_mouse_entered() -> void:
	_show_accolade_tooltip($StatisticsMenu/accolades/QuickDraw)

func _on_quick_draw_mouse_exited() -> void:
	_hide_accolade_tooltip()

func _on_relentless_mouse_entered() -> void:
	_show_accolade_tooltip($StatisticsMenu/accolades/Relentless)

func _on_relentless_mouse_exited() -> void:
	_hide_accolade_tooltip()

func _on_rubber_duck_mouse_entered() -> void:
	_show_accolade_tooltip($StatisticsMenu/accolades/RubberDuck)

func _on_rubber_duck_mouse_exited() -> void:
	_hide_accolade_tooltip()

func _on_speed_demon_mouse_entered() -> void:
	_show_accolade_tooltip($StatisticsMenu/accolades/SpeedDemon)

func _on_speed_demon_mouse_exited() -> void:
	_hide_accolade_tooltip()

func _on_thrill_seeker_mouse_entered() -> void:
	_show_accolade_tooltip($StatisticsMenu/accolades/ThrillSeeker)

func _on_thrill_seeker_mouse_exited() -> void:
	_hide_accolade_tooltip()

func _on_untouchable_mouse_entered() -> void:
	_show_accolade_tooltip($StatisticsMenu/accolades/Untouchable)

func _on_untouchable_mouse_exited() -> void:
	_hide_accolade_tooltip()
