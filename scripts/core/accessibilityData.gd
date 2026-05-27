extends Node

enum CardStyle { DEFAULT, STENCIL }

enum CardUISize { SMALL, MEDIUM, LARGE }

var currentCardStyle: CardStyle = CardStyle.STENCIL
var currentCardUISize: CardUISize = CardUISize.MEDIUM
var useColorblindAccents: bool = false
var animationsDisabled: bool = false

func _ready() -> void:
	var saveData = SaveManager.load_main_state()
	
	if saveData.has("accessibility"):
		currentCardStyle = saveData["accessibility"].get("currentCardStyle", currentCardStyle)
		currentCardUISize = saveData["accessibility"].get("currentCardUISize", currentCardUISize)
		useColorblindAccents = saveData["accessibility"].get("useColorblindAccents", useColorblindAccents)
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
