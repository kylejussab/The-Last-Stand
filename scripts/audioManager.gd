extends Node

@onready var buttonClick = $UI/ButtonClick
@onready var buttonHover = $UI/ButtonHover
@onready var buttonBack = $UI/ButtonBack
@onready var whoosh = $UI/Whoosh
@onready var slotSpin = $UI/SlotSpin
@onready var slotStop = $UI/SlotStop
@onready var clickerCry = $UI/ClickerCry

@onready var takeDamage = $Effects/TakeDamage
@onready var cardHover = $Effects/CardHover
@onready var cardLock = $Effects/CardLock
@onready var cardDraw = $Effects/CardDraw
@onready var cardShuffle = $Effects/CardShuffle

@onready var music1 = $Music/layer1
@onready var music2 = $Music/layer2

@onready var rainAmbience = $Music/rainyAmbience
@onready var sunAmbience = $Music/sunnyAmbience

var whooshSounds = [
	preload("res://assets/sounds/ui/whoosh.wav"),
	preload("res://assets/sounds/ui/whoosh2.wav")
]

var drawSounds = [
	preload("res://assets/sounds/cards/deal_1.wav"),
	preload("res://assets/sounds/cards/deal_2.wav"),
	preload("res://assets/sounds/cards/deal_3.wav"),
	preload("res://assets/sounds/cards/deal_4.wav"),
	preload("res://assets/sounds/cards/deal_5.wav"),
	preload("res://assets/sounds/cards/deal_6.wav"),
	preload("res://assets/sounds/cards/deal_7.wav")
]

var shuffleSounds = [
	preload("res://assets/sounds/cards/shuffle_1.wav"),
	preload("res://assets/sounds/cards/shuffle_2.wav"),
	preload("res://assets/sounds/cards/shuffle_3.wav"),
	preload("res://assets/sounds/cards/shuffle_4.wav")
]

var beyondTheThreshold = [
	"res://assets/sounds/music/The Perilous Path/1 Beyond the Threshold - Layer 1.wav",
	"res://assets/sounds/music/The Perilous Path/1 Beyond the Threshold - Layer 2.wav"
]

var carvingThePath = [
	"res://assets/sounds/music/The Perilous Path/2 Carving the Path - Layer 1.wav",
	"res://assets/sounds/music/The Perilous Path/2 Carving the Path - Layer 2.wav"
]

var quickeningStride = [
	"res://assets/sounds/music/The Perilous Path/3 Quickening Stride - Layer 1.wav",
	"res://assets/sounds/music/The Perilous Path/3 Quickening Stride - Layer 2.wav"
]

var canPlayCardHover: bool = true

func play_button_click() -> void:
	buttonClick.play()

func play_button_hover() -> void:
	buttonHover.play()

func play_button_back() -> void:
	buttonBack.play()

func play_whoosh(alternate: bool = false) -> void:
	if alternate:
		whoosh.stream = whooshSounds[1]
	else:
		whoosh.stream = whooshSounds[0]
	
	whoosh.play()

func play_slot_spin() -> void:
	slotSpin.play()

func play_slot_stop() -> void:
	slotStop.play()

func play_clicker_cry() -> void:
	clickerCry.play()

func play_take_damage() -> void:
	takeDamage.play()

func play_card_hover() -> void:
	if !canPlayCardHover:
		return
	
	cardHover.play()
	canPlayCardHover = false
	
	await get_tree().create_timer(0.1).timeout
	
	canPlayCardHover = true

func play_card_lock() -> void:
	cardLock.play()

func play_random_card_draw() -> void:
	cardDraw.stream = drawSounds.pick_random()
	cardDraw.play()

func play_random_card_shuffle() -> void:
	cardShuffle.stream = shuffleSounds.pick_random()
	cardShuffle.play()

func play_beyondTheThreshold(maxVolume1: float = 0.0, maxVolume2: float = 0.0, duration: float = 5.0) -> void:
	_transition_to_track(beyondTheThreshold[0], beyondTheThreshold[1], maxVolume1, maxVolume2, duration)

func play_carving_the_path(maxVolume1: float = 0.0, maxVolume2: float = 0.0, duration: float = 5.0) -> void:
	_transition_to_track(carvingThePath[0], carvingThePath[1], maxVolume1, maxVolume2, duration)

func play_quickening_stride(maxVolume1: float = 0.0, maxVolume2: float = 0.0, duration: float = 5.0) -> void:
	_transition_to_track(quickeningStride[0], quickeningStride[1], maxVolume1, maxVolume2, duration)

# Music helpers
var musicTransitionTween: Tween

func stop_music(fadeTime: float = 2.0) -> void:
	if musicTransitionTween and musicTransitionTween.is_valid():
		musicTransitionTween.kill()
		
	if not music1.playing and not music2.playing:
		return
	
	musicTransitionTween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	musicTransitionTween.tween_property(music1, "volume_db", -80.0, fadeTime)
	musicTransitionTween.tween_property(music2, "volume_db", -80.0, fadeTime)
	
	await musicTransitionTween.finished
	
	music1.stop()
	music2.stop()

func _transition_to_track(pathLayer1: String, pathLayer2: String, maxVolume1: float = 0.0, maxVolume2: float = 0.0, fadeTime: float = 1.5) -> void:
	if not FileAccess.file_exists(pathLayer1) or not FileAccess.file_exists(pathLayer2):
		return
	
	var streamLayer1 = load(pathLayer1)
	var streamLayer2 = load(pathLayer2)
	
	if music1.stream == streamLayer1 and music1.playing:
		return
		
	if musicTransitionTween and musicTransitionTween.is_valid():
		musicTransitionTween.kill()

	if music1.playing or music2.playing:
		musicTransitionTween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		musicTransitionTween.tween_property(music1, "volume_db", -80.0, fadeTime)
		musicTransitionTween.tween_property(music2, "volume_db", -80.0, fadeTime)
		
		await musicTransitionTween.finished
		
		music1.stream = streamLayer1
		music2.stream = streamLayer2
		
		music1.play()
		music2.play()
		
		musicTransitionTween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		musicTransitionTween.tween_property(music1, "volume_db", maxVolume1, fadeTime)
		musicTransitionTween.tween_property(music2, "volume_db", maxVolume2, fadeTime)
	
	else:
		music1.stream = streamLayer1
		music2.stream = streamLayer2
		
		music1.volume_db = maxVolume1
		music2.volume_db = maxVolume2
		
		music1.play()
		music2.play()

# Music Layer adjustments
var fadeTween1: Tween
var fadeTween2: Tween

func change_volume_layer1(targetVolume: float, duration: float = 1.5) -> void:
	if fadeTween1:
		fadeTween1.kill()
	
	fadeTween1 = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fadeTween1.tween_property(music1, "volume_db", targetVolume, duration)

func change_volume_layer2(targetVolume: float, duration: float = 1.5) -> void:
	if fadeTween2:
		fadeTween2.kill()
	
	fadeTween2 = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fadeTween2.tween_property(music2, "volume_db", targetVolume, duration)

#Ambience adjustments
var rainyPosition: float = 0.0
var sunnyPosition: float = 0.0

var ambienceTween: Tween
var activeAmbience: String = "none"
var ambienceVolumeTween: Tween

func play_rainy(maxVolume: float = 0.0, fadeTime: float = 2.0) -> void:
	activeAmbience = "rain"
	
	if sunLoopTimer and sunLoopTimer.is_valid():
		sunLoopTimer.kill()
		
	if ambienceTween and ambienceTween.is_valid():
		ambienceTween.kill()
		
	ambienceTween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	ambienceTween.tween_property(sunAmbience, "volume_db", -80.0, fadeTime)
	
	if not rainAmbience.playing:
		rainAmbience.volume_db = -80.0
		rainAmbience.play(rainyPosition) 
		_scheduleAmbienceLoop(rainAmbience, "rain")
	
	ambienceTween.tween_property(rainAmbience, "volume_db", maxVolume, fadeTime)
	
	ambienceTween.chain().tween_callback(func():
		sunnyPosition = sunAmbience.get_playback_position()
		sunAmbience.stop()
	)

func play_sunny(maxVolume: float = 0.0, fadeTime: float = 2.0) -> void:
	activeAmbience = "sun"
	
	if rainLoopTimer and rainLoopTimer.is_valid():
		rainLoopTimer.kill()
		
	if ambienceTween and ambienceTween.is_valid():
		ambienceTween.kill()
		
	ambienceTween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	ambienceTween.tween_property(rainAmbience, "volume_db", -80.0, fadeTime)
	
	if not sunAmbience.playing:
		sunAmbience.stream = load("res://assets/sounds/music/SunnyAmbience.ogg")
		sunAmbience.volume_db = -80.0
		sunAmbience.play(sunnyPosition)
		_scheduleAmbienceLoop(sunAmbience, "sun")
	
	ambienceTween.tween_property(sunAmbience, "volume_db", maxVolume, fadeTime)
	
	ambienceTween.chain().tween_callback(func():
		rainyPosition = rainAmbience.get_playback_position()
		rainAmbience.stop()
	)

func stop_ambience(fadeTime: float = 2.0) -> void:
	if rainLoopTimer and rainLoopTimer.is_valid(): 
		rainLoopTimer.kill()
	if sunLoopTimer and sunLoopTimer.is_valid(): 
		sunLoopTimer.kill()
	
	if ambienceTween and ambienceTween.is_valid():
		ambienceTween.kill()
		
	ambienceTween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if rainAmbience.playing:
		ambienceTween.tween_property(rainAmbience, "volume_db", -80.0, fadeTime)
	if sunAmbience.playing:
		ambienceTween.tween_property(sunAmbience, "volume_db", -80.0, fadeTime)
		
	ambienceTween.chain().tween_callback(func():
		if rainAmbience.playing:
			rainyPosition = rainAmbience.get_playback_position()
			rainAmbience.stop()
		if sunAmbience.playing:
			sunnyPosition = sunAmbience.get_playback_position()
			sunAmbience.stop()
	)

# Ambience Looping script
var rainLoopTimer: Tween
var sunLoopTimer: Tween
var customLoopFadeTime: float = 3.0

func _scheduleAmbienceLoop(player: AudioStreamPlayer2D, type: String) -> void:
	var totalLength = player.stream.get_length()
	var currentPos = player.get_playback_position()
	var waitTime = (totalLength - currentPos) - customLoopFadeTime
	
	if waitTime <= 0: return
	
	if type == "rain":
		if rainLoopTimer and rainLoopTimer.is_valid(): 
			rainLoopTimer.kill()
		rainLoopTimer = create_tween()
		rainLoopTimer.tween_interval(waitTime)
		rainLoopTimer.tween_callback(func(): _customLoopAmbience(player, type))
		
	elif type == "sun":
		if sunLoopTimer and sunLoopTimer.is_valid(): 
			sunLoopTimer.kill()
		sunLoopTimer = create_tween()
		sunLoopTimer.tween_interval(waitTime)
		sunLoopTimer.tween_callback(func(): _customLoopAmbience(player, type))

func _customLoopAmbience(player: AudioStreamPlayer2D, type: String) -> void:
	if ambienceTween and ambienceTween.is_valid():
		ambienceTween.kill()
	
	ambienceTween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ambienceTween.tween_property(player, "volume_db", -80.0, customLoopFadeTime)
	
	await ambienceTween.finished
	if not player.playing: return

	player.play(0.0)
	_scheduleAmbienceLoop(player, type)

	ambienceTween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ambienceTween.tween_property(player, "volume_db", 0.0, customLoopFadeTime)

func change_ambience_volume(targetVolume: float, fadeTime: float = 0.5) -> void:
	if activeAmbience == "none":
		return
		
	if ambienceVolumeTween and ambienceVolumeTween.is_valid():
		ambienceVolumeTween.kill()
		
	ambienceVolumeTween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if activeAmbience == "rain":
		ambienceVolumeTween.tween_property(rainAmbience, "volume_db", targetVolume, fadeTime)
	elif activeAmbience == "sun":
		ambienceVolumeTween.tween_property(sunAmbience, "volume_db", targetVolume, fadeTime)
