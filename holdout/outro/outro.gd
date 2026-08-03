extends Node

@onready var animationPlayer = %AnimationPlayer
@onready var arena = %arena
@onready var battleManager = %battleManager
@onready var holdoutHub = %HoldoutHub

var baseRoundWinValue: int = 4
var winStreaks: int = 0
var efficiency: int = 0
var distanceToNewRank: int = 0
var accolade: Dictionary
var currentMvpData: Dictionary

@onready var actionButtons = [
	%ContinueButton,
	%ReplayButton,
	%NewRunButton,
	%MainMenuButton
]

func play_holdout_end_sequence(playerWon: bool):
	_calculate_holdout_stats(playerWon)
	_assign_values_to_labels()
	
	await _title_slam_and_slide(playerWon)
	
	await get_tree().create_timer(0.3).timeout
	
	animationPlayer.play("showOverview", -1.0, 0.75)
	AudioManager.play_whoosh(true)
	await animationPlayer.animation_finished
	await get_tree().create_timer(0.3).timeout
	
	animationPlayer.play("showPerformance", -1.0, 0.75)
	AudioManager.play_whoosh(true)
	await animationPlayer.animation_finished
	await get_tree().create_timer(0.3).timeout
	
	animationPlayer.play("showTotal")
	await animationPlayer.animation_finished
	await get_tree().create_timer(0.8).timeout
	
	AudioManager.play_random_rations_collected()
	await animate_rations_tick($"../../arena/outro/total/totalStatContainer/totalValue", HoldoutStats.totalRunRations, HoldoutStats.currentRunRations)
	await get_tree().create_timer(0.3).timeout
	
	animationPlayer.play("showBadges", -1.0, 0.75)
	
	for button in actionButtons:
		button.disabled = false
	
	if !playerWon:
		%ContinueButton.visible = false
		%ContinueButton.disabled = true
	
	animationPlayer.queue("showButtons")
	await animationPlayer.animation_finished
	
	AudioManager.change_volume_background() # Back to default

func play_holdout_tutorial_end_sequence():
	await _title_slam_and_slide(true, true)
	
	$"../../arena/holdoutEndStats/performance".hide()
	$"../../arena/holdoutEndStats/total".hide()
	%ContinueButton.hide()
	$"../../arena/holdoutEndStats/ReplayButton".hide()
	
	$"../../arena/outro/overview/overviewStatContainer/roundsPlayedValue".text = str(HoldoutStats.roundsPlayed)
	$"../../arena/outro/overview/overviewStatContainer/timeElapsedValue".text = format_time(HoldoutStats.currentRoundDuration)
	
	await get_tree().create_timer(0.3).timeout
	
	animationPlayer.play("showOverview", -1.0, 0.75)
	AudioManager.play_whoosh(true)
	await animationPlayer.animation_finished
	await get_tree().create_timer(0.3).timeout
	
	animationPlayer.play("showButtonsTutorial")
	await animationPlayer.animation_finished
	
	AudioManager.change_volume_background() # Back to default

# Animation Helpers
func _title_slam_and_slide(playerWon: bool, fromTutorial: bool = false):
	%outro.visible = true
	$"../../arena/outro/overlay".visible = true
	$"../../arena/outro/title".visible = true
	
	var resultLabel = $"../../arena/outro/title"
	if !fromTutorial:
		resultLabel.text = "SURVIVED" if playerWon else "DEFEATED"
	else:
		resultLabel.text = "COMPLETED"
	
	resultLabel.pivot_offset = resultLabel.size / 2
	
	AudioManager.change_volume_background(-40)
	
	var screenSize = get_viewport().get_visible_rect().size
	resultLabel.global_position = screenSize / 2 - resultLabel.size / 2
	resultLabel.scale = Vector2(2.0, 2.0)
	resultLabel.modulate.a = 0.0
	resultLabel.visible = true
	
	var growTween = create_tween().set_parallel(true)
	growTween.tween_property(resultLabel, "modulate:a", 1.0, 0.5)
	growTween.tween_property(resultLabel, "scale", Vector2(4.0, 4.0), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	AudioManager.play_whoosh()
	
	var fadeTween = create_tween()
	fadeTween.tween_property(resultLabel, "modulate:a", 1.0, 0.3)
	await fadeTween.finished
	
	var slamTween = create_tween()
	slamTween.tween_property(resultLabel, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	await slamTween.finished
	
	await get_tree().create_timer(1).timeout
	
	var slideTween = create_tween().set_parallel(true)
	var targetPosition
	
	AudioManager.play_whoosh(true)
	
	if !fromTutorial:
		targetPosition = Vector2(145, 121)
		animationPlayer.play("showWins", -1.0, 0.5)
	else:
		targetPosition = Vector2(160, 121)
		animationPlayer.play("showLineTutorial", -1.0, 0.5)
	
	slideTween.tween_property(resultLabel, "global_position", targetPosition, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	slideTween.tween_property(resultLabel, "scale", Vector2(1, 1), 0.5)
	
	await slideTween.finished

func _calculate_holdout_stats(playerWon: bool) -> void:
	var totalRationsToAdd: int = 0
	
	if playerWon:
		HoldoutStats.numberOfWins += 1
	
	winStreaks = HoldoutStats.longestStreak * 2
	
	if playerWon:
		baseRoundWinValue = 4
		efficiency = int(40.0 / float(HoldoutStats.roundsPlayed))
	else:
		baseRoundWinValue = 0
		efficiency = 0
	
	totalRationsToAdd = int((baseRoundWinValue + HoldoutStats.highestDominance + winStreaks + efficiency + HoldoutStats.underdogWins) * HoldoutStats.multiplierTotal)
	
	HoldoutStats.currentRunRations = HoldoutStats.totalRunRations + totalRationsToAdd
	
	HoldoutStats.currentRank = HoldoutStats.evaluate_rank(HoldoutStats.totalRunRations + totalRationsToAdd)
	
	distanceToNewRank = HoldoutStats.get_distance_to_next(HoldoutStats.totalRunRations + totalRationsToAdd)
	
	currentMvpData = get_card_stats(HoldoutStats.allPlayedCards)
	var mvpKey = currentMvpData["cardKey"]
	
	if mvpKey != "None":
		GameStats.holdoutMvpCounts[mvpKey] = GameStats.holdoutMvpCounts.get(mvpKey, 0) + 1
	
	accolade = get_final_accolade()
	GameStats.holdoutAccoladeCounts[accolade.id] += 1
	
	if !playerWon:
		GameStats.rations += HoldoutStats.totalRunRations + totalRationsToAdd

func _assign_values_to_labels() -> void:
	$"../../arena/outro/wins".text = "%02d" % HoldoutStats.numberOfWins
	
	# Overview
	$"../../arena/outro/overview/overviewStatContainer/roundsPlayedValue".text = str(HoldoutStats.roundsPlayed)
	$"../../arena/outro/overview/overviewStatContainer/timeElapsedValue".text = format_time(HoldoutStats.currentRoundDuration)
	
	# Performance
	$"../../arena/outro/performance/performanceStatContainer/roundWinValue".text = str(baseRoundWinValue)
	$"../../arena/outro/performance/performanceStatContainer/dominanceValue".text = str(HoldoutStats.highestDominance)
	$"../../arena/outro/performance/performanceStatContainer/streakValue".text = str(winStreaks)
	$"../../arena/outro/performance/performanceStatContainer/efficiencyValue".text = str(efficiency)
	$"../../arena/outro/performance/performanceStatContainer/underdogMasteryValue".text = str(HoldoutStats.underdogWins)
	$"../../arena/outro/performance/performanceStatContainer/modifierMultiplierValue".text = str(HoldoutStats.multiplierTotal) + "x"
	
	$"../../arena/outro/total/totalStatContainer/totalValue".text = str(HoldoutStats.totalRunRations)
	
	$"../../arena/outro/total/rankIcon".texture = load("res://holdout/outro/icons/rank/" + HoldoutStats.get_current_rank_string() + ".png")
	
	var premiumAssetPath = "res://holdout/outro/icons/mvp/" + currentMvpData["cardKey"] + ".png"
	
	if ResourceLoader.exists(premiumAssetPath):
		$"../../arena/outro/total/mvpIcon".texture = load(premiumAssetPath)
	else:
		$"../../arena/outro/total/mvpIcon".texture = load("res://holdout/outro/icons/" + currentMvpData["faction"] + ".png")
	
	$"../../arena/outro/total/badgeOutlineMvp".modulate = HoldoutStats.FACTION_COLORS[currentMvpData["faction"]]
	
	if HoldoutStats.get_next_rank_string() == "":
		$"../../arena/outro/total/badgeTextContainer/rankText".text = "Max Rank"
	else:
		$"../../arena/outro/total/badgeTextContainer/rankText".text = str(distanceToNewRank) + " [img width=10]res://core/menus/ui/RationsIconSlim.png[/img] to Rank " + HoldoutStats.get_next_rank_string()
	
	$"../../arena/outro/total/rankIcon".modulate = HoldoutStats.RANK_COLORS[HoldoutStats.currentRank]
	$"../../arena/outro/total/badgeOutlineRank".modulate = HoldoutStats.RANK_COLORS[HoldoutStats.currentRank]
	
	$"../../arena/outro/total/badgeTextContainer/accoladeText".text = accolade.title
	
	$"../../arena/outro/total/accoladeIcon".texture = load("res://holdout/outro/icons/accolade/" + accolade.title + ".png")

func format_time(time: float) -> String:
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	return "%02d:%02d" % [minutes, seconds]

func get_card_stats(playedCards):
	var factionImpact = {}
	var cardImpact = {}
	var cardFactions = {}

	for card in playedCards:
		var faction = card.get("faction", "None")
		var key = card.get("cardKey", "None")
		var value = card.get("value", 1) 
		
		if faction != "Support":
			factionImpact[faction] = factionImpact.get(faction, 0) + value
			cardImpact[key] = cardImpact.get(key, 0) + value
			cardFactions[key] = faction # Map the card key directly to its faction
		
	# Find the Top Faction (Overall run stat, not necessarily the MVP's faction)
	var topFaction = "None"
	var highestFactionValue = -1
	for faction in factionImpact:
		if factionImpact[faction] > highestFactionValue:
			highestFactionValue = factionImpact[faction]
			topFaction = faction
	
	# Find the MVP Card Key
	var mvpKey = "None"
	var highestCardValue = -1
	for key in cardImpact:
		if cardImpact[key] > highestCardValue:
			highestCardValue = cardImpact[key]
			mvpKey = key
			
	var mvpFaction = cardFactions.get(mvpKey, "None")
	
	# Format the Display Name
	var cardName = ""
	var displayOverrides = {
		"WLFSoldier": "WLF Soldier",
		"TommyFirefly": "Tommy",
		"JoelSmuggler": "Joel",
		"BillSmuggler": "Bill",
		"LiSmuggler": "Li",
		"AbbyFirefly": "Abby",
		"AliceHumanity": "Alice",
		"FireflySoldierHumanity": "Firefly Soldier",
		"WLFSoldierHumanity": "WLF Soldier",
		"IsaacHumanity": "Isaac",
		"TommyFireflyHumanity": "Tommy",
		"RileyHumanity": "Riley",
	}
	
	if displayOverrides.has(mvpKey):
		cardName = displayOverrides[mvpKey]
	else:
		for i in range(mvpKey.length()):
			var letter = mvpKey[i]
			if i > 0 and letter == letter.to_upper():
				cardName += " "
			cardName += letter
	
	return {
		"faction": mvpFaction, 
		"topFaction": topFaction, 
		"card": cardName, 
		"cardKey": mvpKey
	}

func animate_rations_tick(label, start_score: int, end_score: int):
	var duration = 0.0 if AccessibilityData.animationsDisabled else 2.0 

	var tween = create_tween()
	
	tween.tween_method(
		func(val: int): label.text = str(val),
		start_score,
		end_score,
		duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT) 
	
	return tween

func handle_modifier_durations() -> void:
	for i in range(HoldoutStats.activeModifiers.size() - 1, -1, -1):
		var modifier = HoldoutStats.activeModifiers[i]
		
		modifier["currentDuration"] += 1
		
		if modifier["currentDuration"] >= modifier["duration"]:
			%battleManager.remove_modifier(modifier["id"])

static func get_final_accolade() -> Dictionary:
	if HoldoutStats.achievedOldWounds:
		return HoldoutStats.ACCOLADES["OldWounds"]
	
	if HoldoutStats.multiplierTotal >= 1.8:
		return HoldoutStats.ACCOLADES["ThrillSeeker"]
	
	if HoldoutStats.currentRoundDuration < 60.0 and HoldoutStats.numberOfWins > 0:
		return HoldoutStats.ACCOLADES["SpeedDemon"]
	
	var earned: Array = []
	
	if HoldoutStats.playerHealthValue == HoldoutStats.playerHealthAtRoundStart: 
		earned.append(HoldoutStats.ACCOLADES["Untouchable"])
	
	if HoldoutStats.highestDominance >= 10:
		earned.append(HoldoutStats.ACCOLADES["Executioner"])
		
	if HoldoutStats.underdogWins >= 3:
		earned.append(HoldoutStats.ACCOLADES["GiantSlayer"])
		
	if HoldoutStats.longestStreak >= 4:
		earned.append(HoldoutStats.ACCOLADES["Relentless"])
		
	if HoldoutStats.roundsPlayed <= 3 and HoldoutStats.numberOfWins > 0:
		earned.append(HoldoutStats.ACCOLADES["QuickDraw"])
		
	if HoldoutStats.multiplierTotal == 1.0:
		earned.append(HoldoutStats.ACCOLADES["Purist"])
	
	if HoldoutStats.longestThinkTime >= 30.0 and HoldoutStats.numberOfWins > 0:
		earned.append(HoldoutStats.ACCOLADES["AnalysisParalysis"])
		
	var supportCount: int = 0
	for card in HoldoutStats.allPlayedCards:
		if card.get("faction", "") == "Support":
			supportCount += 1
			
	if supportCount <= 1 and HoldoutStats.numberOfWins > 0:
		earned.append(HoldoutStats.ACCOLADES["Brawler"])
	
	if not earned.is_empty():
		return earned.pick_random()
		
	return HoldoutStats.ACCOLADES["RubberDuck"]

func trigger_badge_thud() -> void:
	AudioManager.play_badge_thud()

func _on_dominance_text_mouse_entered() -> void:
	%tooltip.get_node("tooltipText").text = "The highest value difference you've had over your opponent in a single round.\n\nEach point of Dominance adds a flat bonus to your total rations."
	%tooltip.get_node("indicator").position.y = 489.5
	%tooltip.visible = true

func _on_dominance_text_mouse_exited() -> void:
	%tooltip.visible = false

func _on_streak_text_mouse_entered() -> void:
	%tooltip.get_node("tooltipText").text = "The number of consecutive rounds won without a loss.\n\nYour Streak is multiplied by 2 and added as a bonus to your total rations."
	%tooltip.get_node("indicator").position.y = 529.5
	%tooltip.visible = true

func _on_streak_text_mouse_exited() -> void:
	%tooltip.visible = false

func _on_efficiency_text_mouse_entered() -> void:
	%tooltip.get_node("tooltipText").text = "A decaying reward based on the number of rounds played.\n\nWinning the battle in fewer rounds keeps this bonus high."
	%tooltip.get_node("indicator").position.y = 569.5
	%tooltip.visible = true

func _on_efficiency_text_mouse_exited() -> void:
	%tooltip.visible = false

func _on_underdog_mastery_text_mouse_entered() -> void:
	%tooltip.get_node("tooltipText").text = "The number of wins where you played a weaker character than your opponent.\n\nEach win adds a flat bonus to your total rations."
	%tooltip.get_node("indicator").position.y = 609.5
	%tooltip.visible = true

func _on_underdog_mastery_text_mouse_exited() -> void:
	%tooltip.visible = false


# Privates
func _on_continue_button_pressed() -> void:
	AudioManager.change_volume_background() # Audio back to default always
	
	HoldoutStats.replayedRound = false
	HoldoutStats.totalRunRations = HoldoutStats.currentRunRations
	
	if GameStats.gameMode == GameStats.Mode.HOLDOUT_ROUND_COMPLETED:
		HoldoutStats.playerHealthValue = int(arena.playerHealthLabel.text)
		GameStats.gameMode = GameStats.Mode.HOLDOUT
	
	handle_modifier_durations()
	
	_fade_with_round_reset()

func _on_replay_button_mouse_entered() -> void:
	%holdIcon.get_node("image").position.x = 1800
	%holdIcon.get_node("text").position.x = 1821
	%holdIcon.show()

func _on_replay_button_mouse_exited() -> void:
	%holdIcon.hide()
	%holdIcon.get_node("image").position.x = 1675
	%holdIcon.get_node("text").position.x = 1700

func _on_replay_button_hold_complete() -> void:
	AudioManager.change_volume_background() # Audio back to default always
	
	HoldoutStats.replayedRound = true
	
	if GameStats.gameMode == GameStats.Mode.HOLDOUT_ROUND_COMPLETED:
		GameStats.gameMode = GameStats.Mode.HOLDOUT
	
	_fade_with_round_reset()

func _on_new_run_button_mouse_entered() -> void:
	%holdIcon.get_node("image").position.x = 1800
	%holdIcon.get_node("text").position.x = 1821
	%holdIcon.show()

func _on_new_run_button_mouse_exited() -> void:
	%holdIcon.hide()
	%holdIcon.get_node("image").position.x = 1675
	%holdIcon.get_node("text").position.x = 1700

func _on_new_run_button_hold_complete() -> void:
	AudioManager.change_volume_background() # Audio back to default always
	
	GameStats.gameMode = GameStats.Mode.HOLDOUT
	HoldoutStats.reset_for_new_run()
	
	Curtain.change_scene("res://holdout/battle/holdoutBattle.tscn")

func _on_main_menu_button_hold_complete() -> void:
	Database.clear_avatar_cache()
	GameStats.gameMode = GameStats.Mode.MAIN_MENU
	Curtain.change_scene("res://core/menus/mainMenu.tscn", 1.0, 0.75) # wait .75 seconds while the screen is black for scene load
	
	AudioManager.stop_background()
	AudioManager.play_beyondTheThreshold(-20, -80, 4)

func _on_main_menu_button_mouse_entered() -> void:
	%holdIcon.get_node("image").position.x = 1800
	%holdIcon.get_node("text").position.x = 1821
	%holdIcon.show()

func _on_main_menu_button_mouse_exited() -> void:
	%holdIcon.hide()
	%holdIcon.get_node("image").position.x = 1675
	%holdIcon.get_node("text").position.x = 1700

func _fade_with_round_reset() -> void:
	await Curtain.fade_in()
	
	Database.clear_avatar_cache()
	%bubbleContainer.clear_modifiers()
	%pauseIcon/text.text = "PAUSE"
	arena.change_mood(Actor.Type.PLAYER, Actor.Mood.NEUTRAL)
	arena.change_mood(Actor.Type.OPPONENT, Actor.Mood.NEUTRAL)
	arena.set_indicator(Actor.Type.NONE)
	_reset_holdout_stats_ui()
	_reset_board_state()
	
	arena.update_health(Actor.Type.PLAYER, HoldoutStats.playerHealthValue, true)
	
	battleManager.prepare_opponent()
	
	if not HoldoutStats.replayedRound:
		await holdoutHub._ensure_hub_data_ready()
	
	Curtain.fade_out()
	
	holdoutHub.show_hub()

func _reset_holdout_stats_ui() -> void:
	%outro.visible = false
	
	%AnimationPlayer.play("RESET")
	
	for button in actionButtons:
		button.disabled = true

func _reset_board_state() -> void:
	battleManager.lockPlayerInput = true
	arena.show_end_turn_button(false)
	HoldoutStats.reset_for_new_battle()
	%playerHand.playerHand.clear()
	%opponentHand.opponentHand.clear()
	
	%cardSlotSupport.occupied = false
	%cardSlotCharacter.occupied = false
	# Clean up older scene children
	for card in %cardManager.get_children():
		card.queue_free()
