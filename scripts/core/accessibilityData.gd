extends Node

enum CardStyle { DEFAULT, NO_ARTWORK, MINIMAL }

enum CardUISize { SMALL, MEDIUM, LARGE }

var currentCardStyle: CardStyle = CardStyle.DEFAULT
var currentCardUISize: CardUISize = CardUISize.MEDIUM
var useColorblindAccents: bool = false
var animationsDisabled: bool = false

func _ready() -> void:
	var saveData = SaveManager.load_main_state()
	
	if saveData.has("accessibility"):
		currentCardStyle = saveData["accessibility"].get("currentCardStyle", currentCardStyle)
		currentCardUISize = saveData["accessibility"].get("currentCardUISize", currentCardUISize)
		animationsDisabled = saveData["accessibility"].get("animationsDisabled", animationsDisabled)

func save_to_file() -> void:
	var saveData = SaveManager.load_main_state() 
	
	saveData["accessibility"] = {
		"currentCardStyle": currentCardStyle,
		"currentCardUISize": currentCardUISize,
		"useColorblindAccents": useColorblindAccents,
		"animationsDisabled": animationsDisabled
	}
	SaveManager.save_main_state(saveData)
