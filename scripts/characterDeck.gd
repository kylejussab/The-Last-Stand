extends Node2D

const PLAYER_CARD_SCENE_PATH = "res://scenes/card.tscn"
const OPPONENT_CARD_SCENE_PATH = "res://scenes/opponentCard.tscn"
const CARD_DRAW_SPEED = 0.2

const CHARACTER_DECK_POSITION = Vector2(135, 796)

var deck = [
	"TheProphet",
	"Emily",
	"Ezra",
	"Lyra",
	"SeraphiteBrute",
	"Alice",
	"Eugene",
	"Riley",
	"Bill",
	"Runner",
	"Tommy",
	"Nora",
	"Lev",
	"RatKing",
	"Stalker",
	"Clicker",
	"Stalker",
	"Yara",
	"Dina",
	"Bloater",
	"Joel",
	"Marlene",
	"Malik",
	"Jessie",
	"Ellie",
	"Abby",
	"FireflySoldier",
	"FireflySoldier",
	"Isaac",
	"WLFSoldier",
	"TommyFirefly",
	"Manny",
	"Li",
	"Runner",
	"Runner",
	"Stalker",
]

var cardDatabaseReference

func _ready() -> void:
	deck.shuffle()
	
	$RichTextLabel.text = str(deck.size())
	cardDatabaseReference = preload("res://scripts/database.gd")
	
	# Start the player with 4 cards
	for i in range(4):
		draw_card()
	
	# Start the opponent with 4 cards
	for i in range(4):
		draw_opponent_card()

func draw_card():
	var cardDrawn = deck[0]
	deck.erase(cardDrawn)
	
	if deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$image.visible = false
	
	$RichTextLabel.text = str(deck.size())
	var cardScene = preload(PLAYER_CARD_SCENE_PATH)
	var newCard = cardScene.instantiate()
	var cardImagePath = str("res://assets/" + cardDrawn + "Card.png")
	newCard.cardKey = cardDrawn
	newCard.position = CHARACTER_DECK_POSITION
	
	# Add the perk
	if cardDatabaseReference.PERKS.has(cardDrawn):
		newCard.perk = load(cardDatabaseReference.PERKS[cardDrawn]).new()
	
	newCard.get_node("image").texture = load(cardImagePath)
	newCard.get_node("value").text = str(cardDatabaseReference.CHARACTERS[cardDrawn][0])
	newCard.value = cardDatabaseReference.CHARACTERS[cardDrawn][0]
	newCard.type = cardDatabaseReference.CHARACTERS[cardDrawn][1]
	newCard.faction = cardDatabaseReference.CHARACTERS[cardDrawn][2]
	newCard.role = cardDatabaseReference.CHARACTERS[cardDrawn][3]
	newCard.canBePlayed = true
	
	$"../cardManager".add_child(newCard)
	newCard.name = "Card"
	$"../playerHand".add_card_to_hand(newCard, CARD_DRAW_SPEED)
	
	newCard.get_node("AnimationPlayer").play("cardFlip")

func draw_opponent_card():
	var cardDrawn = deck[0]
	deck.erase(cardDrawn)
	
	if deck.size() == 0:
		$image.visible = false
	
	$RichTextLabel.text = str(deck.size())
	var cardScene = preload(OPPONENT_CARD_SCENE_PATH)
	var newCard = cardScene.instantiate()
	var cardImagePath = str("res://assets/" + cardDrawn + "Card.png")
	newCard.cardKey = cardDrawn
	newCard.position = CHARACTER_DECK_POSITION
	
	# Add the perk
	if cardDatabaseReference.PERKS.has(cardDrawn):
		newCard.perk = load(cardDatabaseReference.PERKS[cardDrawn]).new()
	
	newCard.get_node("image").texture = load(cardImagePath)
	newCard.get_node("value").text = str(cardDatabaseReference.CHARACTERS[cardDrawn][0])
	newCard.value = cardDatabaseReference.CHARACTERS[cardDrawn][0]
	newCard.type = cardDatabaseReference.CHARACTERS[cardDrawn][1]
	newCard.faction = cardDatabaseReference.CHARACTERS[cardDrawn][2]
	newCard.role = cardDatabaseReference.CHARACTERS[cardDrawn][3]
	newCard.canBePlayed = true
	
	$"../cardManager".add_child(newCard)
	newCard.name = "Card"
	$"../opponentHand".add_card_to_hand(newCard, CARD_DRAW_SPEED)
	
	# This if statement hides and shows the cards (In place for now, for debugging)
	if $"../battleManager".showOpponentsCards:
		newCard.get_node("AnimationPlayer").play("cardFlip")
	else:
		newCard.get_node("image").visible = false

func reshuffle_from_discards(discardedCards):
	for card in discardedCards:
		deck.append(card.cardKey)
		
		await move_card_back_to_deck(card)
		
		card.queue_free()

	deck.shuffle()
	
	$RichTextLabel.text = str(deck.size())

func move_card_back_to_deck(card):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", CHARACTER_DECK_POSITION, 0.1)
	await tween.finished
