extends Node

@onready var gameOver = %gameOver

@export var whooshSounds = [
	preload("res://assets/sounds/ui/whoosh.wav"),
	preload("res://assets/sounds/ui/whoosh2.wav")
]

func play_game_over_sequence(playerWon: bool):
	await title_slam_and_slide(playerWon)
	await get_tree().create_timer(0.3).timeout
	await show_stats(playerWon)

func title_slam_and_slide(playerWon: bool):
	%gameOver.visible = true
	gameOver.get_node("overlay").visible = true
	gameOver.get_node("title").visible = true
	
	if playerWon:
		GameStats.numberOfWins += 1
	
	var resultLabel = gameOver.get_node("title")
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
	
	var sound = gameOver.get_node("effects")
	sound.stream = whooshSounds[0]
	sound.play()
	
	var fadeTween = create_tween()
	fadeTween.tween_property(resultLabel, "modulate:a", 1.0, 0.3)
	await fadeTween.finished
	
	var slamTween = create_tween()
	slamTween.tween_property(resultLabel, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	await slamTween.finished
	
	await get_tree().create_timer(1).timeout
	
	var slideTween = create_tween().set_parallel(true)
	var targetPosition = Vector2(150, 80)
	
	sound.stream = whooshSounds[1]
	sound.play()
	
	slideTween.tween_property(resultLabel, "global_position", targetPosition, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	slideTween.tween_property(resultLabel, "scale", Vector2(1, 1), 0.5)
	
	await slideTween.finished

func show_stats(playerWon: bool):
	set_end_game_stats(playerWon)
	
	var performance = gameOver.get_node("performance")
	var game = gameOver.get_node("game")
	var score = gameOver.get_node("score")
	var line = gameOver.get_node("line")
	var replayButton = gameOver.get_node("ReplayButton")
	replayButton.disabled = true
	var mainMenuButton = gameOver.get_node("MainMenuButton")
	mainMenuButton.disabled = true
	var continueButton = gameOver.get_node("ContinueButton")
	continueButton.disabled = true
	
	for node in [performance, game, score, line, replayButton, mainMenuButton, continueButton]:
		node.modulate.a = 0.0
		node.visible = true
	
	performance.position.y += 20
	game.position.y += 20
	score.position.y += 20
	
	if playerWon:
		# Show the continue button
		replayButton.position.y = 805
		mainMenuButton.position.y = 875
		continueButton.position.y = 945
	else:
		replayButton.position.y = 875
		mainMenuButton.position.y = 945
		continueButton.position.y = 1015
	
	var uiTween = create_tween()
	
	var sound = gameOver.get_node("effects")
	sound.stream = whooshSounds[1]
	
	uiTween.tween_callback(sound.play)
	uiTween.tween_property(performance, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	uiTween.parallel().tween_property(performance, "position:y", performance.position.y - 20, 0.8).set_trans(Tween.TRANS_CUBIC)
	uiTween.parallel().tween_property(line, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	
	uiTween.tween_interval(0.3)
	
	uiTween.tween_callback(sound.play)
	uiTween.tween_property(game, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	uiTween.parallel().tween_property(game, "position:y", game.position.y - 20, 0.8).set_trans(Tween.TRANS_CUBIC)
	
	uiTween.tween_interval(0.3)
	
	uiTween.tween_callback(sound.play)
	uiTween.tween_property(score, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	uiTween.parallel().tween_property(score, "position:y", score.position.y - 20, 0.8).set_trans(Tween.TRANS_CUBIC)
	
	await uiTween.finished 
	
	score.get_node("scoreAnimationLabel").text =  "+" + str(GameStats.lastStandCurrentRoundScore)
	score.get_node("AnimationPlayer").queue("showScoreUpdate")
	
	animate_score_tick(score.get_node("stat7"), GameStats.lastStandTotalScore, GameStats.lastStandTotalScore + GameStats.lastStandCurrentRoundScore)
	
	var buttonTween = create_tween()
	
	buttonTween.tween_property(replayButton, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	replayButton.disabled = false
	
	buttonTween.tween_property(mainMenuButton, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	mainMenuButton.disabled = false
	
	if playerWon:
		buttonTween.tween_property(continueButton, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
		continueButton.disabled = false
	
	await buttonTween.finished

# Helper functions
func set_end_game_stats(playerWon: bool):
	# Performance stats
	var performance = gameOver.get_node("performance")
	performance.get_node("wins").text = "%02d" % GameStats.numberOfWins
	performance.get_node("stat1").text = str(GameStats.totalForceExerted)
	performance.get_node("stat2").text = str(GameStats.opponentForceExerted)
	performance.get_node("stat3").text = str(GameStats.roundNumber)
	performance.get_node("stat4").text = format_time(GameStats.currentRoundDuration)
	var dominance = GameStats.totalForceExerted / float(GameStats.totalForceExerted + GameStats.opponentForceExerted)
	var momentum = ((GameStats.totalForceExerted/float(GameStats.roundNumber))/7) * dominance * 200 #7 is used as a base "average" value per round
	performance.get_node("stat5").text = "%.1f%%" % momentum
	
	# Game stats
	var game = gameOver.get_node("game")
	var valuableCards = get_card_stats(GameStats.allPlayedCards)
	game.get_node("stat1").text = valuableCards["card"]
	game.get_node("stat2").text = valuableCards["faction"]
	game.get_node("stat3").text = str(GameStats.highestDamageDealt)
	game.get_node("stat4").text = str(GameStats.roundWinsUnderdog)
	
	# Score stats
	var score = gameOver.get_node("score")
	if playerWon:
		score.get_node("stat1text").text = "Victory"
		var winningBase = 20
		score.get_node("stat1").text = str(winningBase)
		var force = GameStats.totalForceExerted - GameStats.opponentForceExerted
		score.get_node("stat2").text = str(force)
		var efficiency = (9 - GameStats.roundNumber) * 5 # 9 as an average number of rounds
		score.get_node("stat3").text = str(efficiency)
		var underdog = GameStats.roundWinsUnderdog * 5
		score.get_node("stat4").text = str(underdog)
		score.get_node("stat5").text = str(int(momentum))
		# Multiplier
		score.get_node("stat6").text = str(GameStats.multiplierTotal) + "x"
		GameStats.lastStandCurrentRoundScore = int((winningBase + force + efficiency + underdog + momentum) * GameStats.multiplierTotal)
		score.get_node("stat7").text = "%05d" % GameStats.lastStandTotalScore
	else:
		score.get_node("stat1text").text = "Defeat"
		@warning_ignore("integer_division")
		var losingScore = int(GameStats.totalForceExerted / 10)
		score.get_node("stat1").text = str(losingScore)
		score.get_node("stat2").text = "-"
		score.get_node("stat3").text = "-"
		score.get_node("stat4").text = "-"
		score.get_node("stat5").text = "-"
		score.get_node("stat6").text = str(GameStats.multiplierTotal) + "x"
		GameStats.lastStandCurrentRoundScore = losingScore
		score.get_node("stat7").text = "%05d" % GameStats.lastStandTotalScore

func format_time(time: float) -> String:
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	return "%02d:%02d" % [minutes, seconds]

func get_card_stats(playedCards):
	var factionCounts = {}
	var cardCounts = {}

	for card in playedCards:
		var faction = card["faction"]
		var mvp = card["cardKey"]
		
		factionCounts[faction] = factionCounts.get(faction, 0) + 1
		cardCounts[mvp] = cardCounts.get(mvp, 0) + 1
		
	var topFaction = "None"
	var highestFactionCount = 0
	
	for faction in factionCounts:
		if factionCounts[faction] > highestFactionCount:
			highestFactionCount = factionCounts[faction]
			topFaction = faction
	
	var cardKey = "None"
	var highestCharacterCount = 0
	
	for card in cardCounts:
		if cardCounts[card] > highestCharacterCount:
			highestCharacterCount = cardCounts[card]
			cardKey = card
	
	var cardName = ""
	
	for i in range(cardKey.length()):
		var letter = cardKey[i]
		if i > 0 and letter == letter.to_upper():
			cardName += " "
		cardName += letter
	
	return {"faction": topFaction, "card": cardName}

func animate_score_tick(label, start_score: int, end_score: int):
	var duration = 0.0 if Settings.reduceAnimations else 2.0 

	var tween = create_tween()
	
	tween.tween_method(
		func(val: int): label.text = "%05d" % val,
		start_score,
		end_score,
		duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT) 
	
	return tween

func handle_modifier_durations() -> void:
	for i in range(GameStats.activeModifiers.size() - 1, -1, -1):
		var modifier = GameStats.activeModifiers[i]
		
		modifier["currentDuration"] += 1
		
		if modifier["currentDuration"] >= modifier["duration"]:
			%battleManager.remove_modifier(modifier["id"])
