extends Node2D

const PLAYER_CARD_SCENE_PATH = "res://scenes/card.tscn"
const OPPONENT_CARD_SCENE_PATH = "res://scenes/opponentCard.tscn"
const CARD_DRAW_SPEED = 0.2

const SUPPORT_DECK_Y_POSITION = 600
const DECK_X_POSITION = 150

var deck = [
	"SmokeBombRare",
	"SmokeBomb",
	"RageRare",
	"Rage",
	"TrapMine",
	"Silencer",
	"ResilienceRare",
	"Resilience",
	"AdrenalineRare",
	"ShotgunShells",
	"PoisonDart",
	"CloakRare",
	"Cloak",
	"ScavengedPartsRare",
	"ScavengedParts",
	"Barricade",
	"MedKitRare",
	"MedKit",
	"Armor",
	"MolotovRare",
	"Molotov",
	"SupplyCacheRare",
	"Shield"
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
	newCard.position = Vector2(DECK_X_POSITION, SUPPORT_DECK_Y_POSITION)
	
	newCard.get_node("image").texture = load(cardImagePath)
	newCard.get_node("value").text = str(cardDatabaseReference.SUPPORTS[cardDrawn][0])
	newCard.value = cardDatabaseReference.SUPPORTS[cardDrawn][0]
	newCard.type = cardDatabaseReference.SUPPORTS[cardDrawn][1]
	
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
	newCard.position = Vector2(DECK_X_POSITION, SUPPORT_DECK_Y_POSITION)
	
	newCard.get_node("image").texture = load(cardImagePath)
	newCard.get_node("value").text = str(cardDatabaseReference.SUPPORTS[cardDrawn][0])
	newCard.value = cardDatabaseReference.SUPPORTS[cardDrawn][0]
	newCard.type = cardDatabaseReference.SUPPORTS[cardDrawn][1]
	
	$"../cardManager".add_child(newCard)
	newCard.name = "Card"
	$"../opponentHand".add_card_to_hand(newCard, CARD_DRAW_SPEED)
	
	# Delete this line later to hide the opponents cards / on for now for debugging
	#newCard.get_node("AnimationPlayer").play("cardFlip")
	newCard.get_node("image").visible = false
