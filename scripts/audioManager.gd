extends Node

@onready var buttonClick = $UI/ButtonClick
@onready var buttonHover = $UI/ButtonHover
@onready var buttonBack = $UI/ButtonBack
@onready var whoosh = $UI/Whoosh
@onready var slotSpin = $UI/SlotSpin
@onready var slotStop = $UI/SlotStop
@onready var clickerCry = $UI/ClickerCry
@onready var rationsCollected = $UI/RationsCollected
@onready var badgeThud = $UI/BadgeThud

@onready var takeDamage = $Effects/TakeDamage
@onready var cardHover = $Effects/CardHover
@onready var cardLock = $Effects/CardLock
@onready var cardDraw = $Effects/CardDraw
@onready var cardShuffle = $Effects/CardShuffle

@onready var music1 = $Music/layer1
@onready var music2 = $Music/layer2

@onready var background = $Music/background

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

var rationCollectionSounds = [
	preload("res://assets/sounds/ui/rationsCollected.wav"),
	preload("res://assets/sounds/ui/rationsCollected2.wav"),
	preload("res://assets/sounds/ui/rationsCollected3.wav"),
	preload("res://assets/sounds/ui/rationsCollected4.wav")
]

var suspenseBackground = [
	"res://assets/sounds/music/Suspense/Suspense #2.mp3",
	"res://assets/sounds/music/Suspense/Shiver.mp3",
	"res://assets/sounds/music/Suspense/Poluted Horizons.mp3",
	"res://assets/sounds/music/Suspense/Undercurrent.mp3",
	"res://assets/sounds/music/Suspense/Suspense #1.mp3",
	"res://assets/sounds/music/Suspense/Undertone.mp3",
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

func _ready() -> void:
	background.finished.connect(_on_background_finished)

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

func play_random_rations_collected() -> void:
	rationsCollected.stream = rationCollectionSounds.pick_random()
	rationsCollected.play()

func play_badge_thud() -> void:
	badgeThud.pitch_scale = randf_range(0.9, 1.1)
	badgeThud.play()

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

func play_beyondTheThreshold(maxVolume1: float = -10.0, maxVolume2: float = -10.0, duration: float = 5.0) -> void:
	_transition_to_track(beyondTheThreshold[0], beyondTheThreshold[1], maxVolume1, maxVolume2, duration)

func play_carving_the_path(maxVolume1: float = -10.0, maxVolume2: float = -10.0, duration: float = 5.0) -> void:
	_transition_to_track(carvingThePath[0], carvingThePath[1], maxVolume1, maxVolume2, duration)

func play_quickening_stride(maxVolume1: float = -10.0, maxVolume2: float = -10.0, duration: float = 5.0) -> void:
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
	if not ResourceLoader.exists(pathLayer1) or not ResourceLoader.exists(pathLayer2):
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

# Playlist state variables
var current_playlist: Array = []
var current_playlist_index: int = 0
var background_target_volume: float = -35.0
var background_fade_time: float = 10.0
var backgroundFadeTween: Tween

func start_background_playlist(playlist: Array = suspenseBackground, targetVolume: float = -35.0, fadeTime: float = 10.0) -> void:
	if playlist.is_empty():
		return
	
	current_playlist = playlist
	background_target_volume = targetVolume
	background_fade_time = fadeTime
	
	current_playlist_index = randi() % current_playlist.size()
	
	_play_current_background_track(fadeTime)

func _play_current_background_track(fadeTime: float = 0.0) -> void:
	var track_path = current_playlist[current_playlist_index]
	
	if not ResourceLoader.exists(track_path):
		push_error("Audio file not found: " + track_path)
		return
	
	background.stream = load(track_path)
	
	if fadeTime > 0:
		background.volume_db = -80.0
		background.play()
		change_volume_background(background_target_volume, fadeTime)
	else:
		background.volume_db = background_target_volume
		background.play()

func _on_background_finished() -> void:
	if current_playlist.is_empty():
		return
	
	current_playlist_index = (current_playlist_index + 1) % current_playlist.size()
	
	_play_current_background_track(background_fade_time)

func change_volume_background(targetVolume: float = -35.0, duration: float = 1.0) -> void:
	background_target_volume = targetVolume
	
	if backgroundFadeTween and backgroundFadeTween.is_valid():
		backgroundFadeTween.kill()
	
	backgroundFadeTween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	backgroundFadeTween.tween_property(background, "volume_db", targetVolume, duration)

func stop_background(fadeTime: float = 2.0) -> void:
	current_playlist = []
	
	if backgroundFadeTween and backgroundFadeTween.is_valid():
		backgroundFadeTween.kill()
		
	if not background.playing:
		return
	
	backgroundFadeTween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	backgroundFadeTween.tween_property(background, "volume_db", -80.0, fadeTime)
	
	await backgroundFadeTween.finished
	background.stop()
