extends Node

enum CardStyle { DEFAULT, STENCIL }

enum CardUISize { SMALL, MEDIUM, LARGE }

var currentCardStyle: CardStyle = CardStyle.DEFAULT
var currentCardUISize: CardUISize = CardUISize.MEDIUM
var useVisualAssistIcons: bool = false
var animationsDisabled: bool = false
var showCardTooltips: bool = true

func _ready() -> void:
	var saveData = SaveManager.load_main_state()
	
	if saveData.has("accessibility"):
		currentCardStyle = saveData["accessibility"].get("currentCardStyle", currentCardStyle)
		currentCardUISize = saveData["accessibility"].get("currentCardUISize", currentCardUISize)
		useVisualAssistIcons = saveData["accessibility"].get("useVisualAssistIcons", useVisualAssistIcons)
		animationsDisabled = saveData["accessibility"].get("animationsDisabled", animationsDisabled)
		showCardTooltips = saveData["accessibility"].get("showCardTooltips", showCardTooltips)

func save_to_file() -> void:
	var saveData = SaveManager.load_main_state() 
	
	saveData["accessibility"] = {
		"currentCardStyle": currentCardStyle,
		"currentCardUISize": currentCardUISize,
		"useVisualAssistIcons": useVisualAssistIcons,
		"animationsDisabled": animationsDisabled,
		"showCardTooltips": showCardTooltips
	}
	SaveManager.save_main_state(saveData)
