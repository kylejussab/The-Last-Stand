extends Node

@onready var screen = %holdoutEndStats
@onready var animationPlayer = %AnimationPlayer

var baseRoundWinValue: int = 4
var winStreaks: int = 0
var efficiency: int = 0
var distanceToNewRank: int = 0
var accolade: Dictionary

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
	await animate_rations_tick(screen.get_node("total/totalStatContainer/totalValue"), HoldoutStats.totalRunRations, HoldoutStats.currentRunRations)
	await get_tree().create_timer(0.3).timeout
	
	animationPlayer.play("showBadges", -1.0, 0.75)
	
	for child in %holdoutEndStats.get_children():
		if child is Button:
			child.disabled = false
	
	if !playerWon:
		%ContinueButton.visible = false
		%ContinueButton.disabled = true
	
	animationPlayer.queue("showButtons")
	await animationPlayer.animation_finished

# Helpers
func _title_slam_and_slide(playerWon: bool):
	screen.visible = true
	screen.get_node("overlay").visible = true
	screen.get_node("title").visible = true
	
	var resultLabel = screen.get_node("title")
	resultLabel.text = "SURVIVED" if playerWon else "DEFEATED"
	resultLabel.pivot_offset = resultLabel.size / 2
	
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
	var targetPosition = Vector2(145, 121)
	
	AudioManager.play_whoosh(true)
	
	animationPlayer.play("showWins", -1.0, 0.5)

	
	slideTween.tween_property(resultLabel, "global_position", targetPosition, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	slideTween.tween_property(resultLabel, "scale", Vector2(1, 1), 0.5)
	
	await slideTween.finished


#func show_stats(playerWon: bool):
	##await set_end_game_stats(playerWon)
	#
	#HoldoutStats.log_battle_results("WIN" if playerWon else "LOSS")
	#
	#var performance = gameOver.get_node("performance")
	#var game = gameOver.get_node("game")
	#var score = gameOver.get_node("score")
	#var line = gameOver.get_node("line")
	#var replayButton = gameOver.get_node("ReplayButton")
	#replayButton.disabled = true
	#var mainMenuButton = gameOver.get_node("MainMenuButton")
	#mainMenuButton.disabled = true
	#var continueButton = gameOver.get_node("ContinueButton")
	#continueButton.disabled = true
	#var newRunButton = gameOver.get_node("NewRunButton")
	#newRunButton.disabled = true
	#
	#for node in [performance, game, score, line, replayButton, mainMenuButton, continueButton, newRunButton]:
		#node.modulate.a = 0.0
		#node.visible = true
	#
	#performance.position.y += 20
	#game.position.y += 20
	#score.position.y += 20
	#
	#if playerWon:
		## Show the continue button
		#continueButton.position.y = 735
		#replayButton.position.y = 805
		#newRunButton.position.y = 875
		#mainMenuButton.position.y = 945
	#else:
		#replayButton.position.y = 805
		#newRunButton.position.y = 875
		#mainMenuButton.position.y = 945
		#continueButton.position.y = 1015
	#
	#var uiTween = create_tween()
	#
	#
	#uiTween.tween_callback(func(): AudioManager.play_whoosh(true))
	#uiTween.tween_property(performance, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	#uiTween.parallel().tween_property(performance, "position:y", performance.position.y - 20, 0.8).set_trans(Tween.TRANS_CUBIC)
	#uiTween.parallel().tween_property(line, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	#
	#uiTween.tween_interval(0.3)
	#
	#uiTween.tween_callback(func(): AudioManager.play_whoosh(true))
	#uiTween.tween_property(game, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	#uiTween.parallel().tween_property(game, "position:y", game.position.y - 20, 0.8).set_trans(Tween.TRANS_CUBIC)
	#
	#uiTween.tween_interval(0.3)
	#
	#uiTween.tween_callback(func(): AudioManager.play_whoosh(true))
	#uiTween.tween_property(score, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	#uiTween.parallel().tween_property(score, "position:y", score.position.y - 20, 0.8).set_trans(Tween.TRANS_CUBIC)
	#
	#await uiTween.finished 
	#
	#score.get_node("scoreAnimationLabel").text =  "+" + str(GameStats.lastStandCurrentRoundScore)
	#score.get_node("AnimationPlayer").queue("showScoreUpdate")
	#
	#animate_score_tick(score.get_node("stat7"), GameStats.lastStandTotalScore, GameStats.lastStandTotalScore + GameStats.lastStandCurrentRoundScore)
	#
	#var buttonTween = create_tween()
	#
	#if playerWon:
		#buttonTween.tween_property(continueButton, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
		#continueButton.disabled = false
	#
	#buttonTween.tween_property(replayButton, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	#replayButton.disabled = false
	#
	#buttonTween.tween_property(newRunButton, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	#newRunButton.disabled = false
	#
	#buttonTween.tween_property(mainMenuButton, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	#mainMenuButton.disabled = false
	#
	#await buttonTween.finished

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
	
	accolade = get_final_accolade()
	GameStats.accoladeCounts[accolade.id] += 1
	
	if !playerWon:
		GameStats.rations += HoldoutStats.totalRunRations + totalRationsToAdd

func _assign_values_to_labels() -> void:
	screen.get_node("wins").text = "%02d" % HoldoutStats.numberOfWins
	
	# Overview
	screen.get_node("overview/overviewStatContainer/roundsPlayedValue").text = str(HoldoutStats.roundsPlayed)
	screen.get_node("overview/overviewStatContainer/timeElapsedValue").text = format_time(HoldoutStats.currentRoundDuration)
	
	# Performance
	screen.get_node("performance/performanceStatContainer/roundWinValue").text = str(baseRoundWinValue)
	screen.get_node("performance/performanceStatContainer/dominanceValue").text = str(HoldoutStats.highestDominance)
	screen.get_node("performance/performanceStatContainer/streakValue").text = str(winStreaks)
	screen.get_node("performance/performanceStatContainer/efficiencyValue").text = str(efficiency)
	screen.get_node("performance/performanceStatContainer/underdogMasteryValue").text = str(HoldoutStats.underdogWins)
	screen.get_node("performance/performanceStatContainer/modifierMultiplierValue").text = str(HoldoutStats.multiplierTotal) + "x"
	
	screen.get_node("total/totalStatContainer/totalValue").text = str(HoldoutStats.totalRunRations)
	
	screen.get_node("total/rankIcon").texture = load("res://assets/holdout/rank/" + HoldoutStats.get_current_rank_string() + ".png")
	
	var premiumAssetPath = "res://assets/holdout/mvp/" + get_card_stats(HoldoutStats.allPlayedCards)["cardKey"] + ".png"
	
	if ResourceLoader.exists(premiumAssetPath):
		screen.get_node("total/mvpIcon").texture = load(premiumAssetPath)
	else:
		screen.get_node("total/mvpIcon").texture = load("res://assets/holdout/" + get_card_stats(HoldoutStats.allPlayedCards)["faction"] + ".png")
	
	screen.get_node("total/badgeOutlineMvp").modulate = HoldoutStats.FACTION_COLORS[get_card_stats(HoldoutStats.allPlayedCards)["faction"]]
	
	if HoldoutStats.get_next_rank_string() == "":
		screen.get_node("total/badgeTextContainer/rankText").text = "Max Rank"
	else:
		screen.get_node("total/badgeTextContainer/rankText").text = str(distanceToNewRank) + " [img width=10]res://assets/ui/RationsIconSlim.png[/img] to Rank " + HoldoutStats.get_next_rank_string()
	
	screen.get_node("total/rankIcon").modulate = HoldoutStats.RANK_COLORS[HoldoutStats.currentRank]
	screen.get_node("total/badgeOutlineRank").modulate = HoldoutStats.RANK_COLORS[HoldoutStats.currentRank]
	
	screen.get_node("total/badgeTextContainer/accoladeText").text = accolade.title
	
	screen.get_node("total/accoladeIcon").texture = load("res://assets/holdout/accolade/" + accolade.title + ".png")

func format_time(time: float) -> String:
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	return "%02d:%02d" % [minutes, seconds]

func get_card_stats(playedCards):
	var factionImpact = {}
	var cardImpact = {}

	for card in playedCards:
		var faction = card.get("faction", "None")
		var key = card.get("cardKey", "None")
		var value = card.get("value", 1) 
		
		if faction != "Support":
			factionImpact[faction] = factionImpact.get(faction, 0) + value
			cardImpact[key] = cardImpact.get(key, 0) + value
		
	# Find the Top Faction
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
	
	return {"faction": topFaction, "card": cardName, "cardKey": mvpKey}

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
	if HoldoutStats.playerHealthValue == HoldoutStats.playerHealthAtRoundStart: 
		return HoldoutStats.ACCOLADES["Untouchable"]
	
	if HoldoutStats.achievedOldWounds:
		return HoldoutStats.ACCOLADES["OldWounds"]
	
	if HoldoutStats.multiplierTotal >= 1.8:
		return HoldoutStats.ACCOLADES["ThrillSeeker"]
	
	var earned: Array = []
	
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
	
	if HoldoutStats.currentRoundDuration < 60.0 and HoldoutStats.numberOfWins > 0:
		earned.append(HoldoutStats.ACCOLADES["SpeedDemon"])
	
	if HoldoutStats.longestThinkTime >= 30.0 and HoldoutStats.numberOfWins > 0:
		earned.append(HoldoutStats.ACCOLADES["AnalysisParalysis"])
		
	var playedSupport: bool = false
	for card in HoldoutStats.allPlayedCards:
		if card.get("faction", "") == "Support":
			playedSupport = true
			break
			
	if not playedSupport and HoldoutStats.numberOfWins > 0:
		earned.append(HoldoutStats.ACCOLADES["Brawler"])
	
	if not earned.is_empty():
		return earned.pick_random()
		
	return HoldoutStats.ACCOLADES["RubberDuck"]

func trigger_badge_thud() -> void:
	AudioManager.play_badge_thud()
