extends Node2D

const PLAYER_CARD_SCENE_PATH = "res://scenes/card.tscn"
const OPPONENT_CARD_SCENE_PATH = "res://scenes/opponentCard.tscn"
const CARD_DRAW_SPEED = 0.2

const SUPPORT_DECK_POSITION = Vector2(135, 548)

@onready var soundPlayer = $AudioStreamPlayer2D

var shuffleSounds = [
	preload("res://assets/sounds/cards/shuffle_1.wav"),
	preload("res://assets/sounds/cards/shuffle_2.wav"),
	preload("res://assets/sounds/cards/shuffle_3.wav"),
	preload("res://assets/sounds/cards/shuffle_4.wav")
]

var deck = [
	"Molotov",
	"Rage",
	"ReinforcedMelee",
	"ReinforcedMelee",
	"TrapMine",
	"TrapMine",
	"SmokeBomb",
	"SmokeBomb",
	"Silencer",
	"MedKit",
	"MedKit",
	"Resilience",
	"Retreat",
	"ScavengedParts",
	"ScavengedParts",
	"ShotgunShells",
	"TrainingManual",
	"Supplements",
	"SupplyCache",
	"Brick",
	"Bottle",
	"Brick",
	"Bottle",
]

var cardDatabaseReference

func _ready() -> void:
	deck.shuffle()
	
	$RichTextLabel.text = str(deck.size())
	cardDatabaseReference = preload("res://scripts/database.gd")

func draw_card():
	var cardDrawn = deck[0]
	deck.erase(cardDrawn)
	
	if deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$image.visible = false
	
	$RichTextLabel.text = str(deck.size())
	var cardScene = preload(PLAYER_CARD_SCENE_PATH)
	var newCard = cardScene.instantiate()
	var cardImagePath = str("res://assets/cards/" + cardDrawn + "Card.png")
	newCard.cardKey = cardDrawn
	newCard.position = SUPPORT_DECK_POSITION
	
	# Add the perk
	if cardDatabaseReference.PERKS.has(cardDrawn):
		newCard.perk = load(cardDatabaseReference.PERKS[cardDrawn]).new()
	
	newCard.get_node("image").texture = load(cardImagePath)
	newCard.get_node("imageBack").texture = load("res://assets/cards/CardBackBlank.png")
	newCard.get_node("value").text = str(cardDatabaseReference.SUPPORTS[cardDrawn][0])
	newCard.value = cardDatabaseReference.SUPPORTS[cardDrawn][0]
	newCard.type = cardDatabaseReference.SUPPORTS[cardDrawn][1]
	newCard.role = cardDatabaseReference.SUPPORTS[cardDrawn][2]
	newCard.canBePlayed = false
	
	$"../cardManager".add_child(newCard)
	newCard.name = "Card"
	$"../playerHand".add_card_to_hand(newCard, CARD_DRAW_SPEED)
	
	newCard.get_node("AnimationPlayer").play("cardFlip")
	newCard.play_draw_sound()

func draw_opponent_card():
	var cardDrawn = deck[0]
	deck.erase(cardDrawn)
	
	if deck.size() == 0:
		$image.visible = false
	
	$RichTextLabel.text = str(deck.size())
	var cardScene = preload(OPPONENT_CARD_SCENE_PATH)
	var newCard = cardScene.instantiate()
	var cardImagePath = str("res://assets/cards/" + cardDrawn + "Card.png")
	newCard.cardKey = cardDrawn
	newCard.position = SUPPORT_DECK_POSITION
	
	# Add the perk
	if cardDatabaseReference.PERKS.has(cardDrawn):
		newCard.perk = load(cardDatabaseReference.PERKS[cardDrawn]).new()
	
	newCard.get_node("image").texture = load(cardImagePath)
	newCard.get_node("imageBack").texture = load("res://assets/cards/CardBackBlank.png")
	newCard.get_node("value").text = str(cardDatabaseReference.SUPPORTS[cardDrawn][0])
	newCard.value = cardDatabaseReference.SUPPORTS[cardDrawn][0]
	newCard.type = cardDatabaseReference.SUPPORTS[cardDrawn][1]
	newCard.role = cardDatabaseReference.SUPPORTS[cardDrawn][2]
	newCard.canBePlayed = false
	
	$"../cardManager".add_child(newCard)
	newCard.name = "Card"
	$"../opponentHand".add_card_to_hand(newCard, CARD_DRAW_SPEED)
	newCard.play_draw_sound()
	
	# This if statement hides and shows the cards (In place for now, for debugging)
	if $"../battleManager".showOpponentsCards:
		newCard.get_node("AnimationPlayer").play("cardFlip")
	else:
		newCard.get_node("image").visible = false

func reshuffle_from_discards(discardedCards):
	for card in discardedCards:
		deck.append(card.cardKey)
		
		card.play_draw_sound()
		await move_card_back_to_deck(card)
		
		card.queue_free()
	
	deck.shuffle()
	
	z_index = 100
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property($image, "scale", Vector2(0.288, 0.288), 0.15)
	await tween.finished
	
	play_shuffle_sound()
	
	await get_tree().create_timer(0.2).timeout
	var tween_back = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween_back.tween_property($image, "scale", Vector2(0.188, 0.188), 0.2)
	z_index = -2
	
	$RichTextLabel.text = str(deck.size())

func move_card_back_to_deck(card):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", SUPPORT_DECK_POSITION, 0.1)
	await tween.finished

func play_shuffle_sound():
	var randomSound = shuffleSounds.pick_random()
	soundPlayer.stream = randomSound
	soundPlayer.play()
