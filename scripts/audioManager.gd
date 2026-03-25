extends Node

@onready var buttonClick = $UI/ButtonClick
@onready var buttonHover = $UI/ButtonHover
@onready var buttonBack = $UI/ButtonBack
@onready var whoosh = $UI/Whoosh
@onready var slotSpin = $UI/SlotSpin
@onready var slotStop = $UI/SlotStop

@onready var takeDamage = $Effects/TakeDamage
@onready var cardHover = $Effects/CardHover
@onready var cardLock = $Effects/CardLock
@onready var cardDraw = $Effects/CardDraw
@onready var cardShuffle = $Effects/CardShuffle

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
