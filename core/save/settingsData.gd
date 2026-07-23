extends Node

enum WindowMode { FULLSCREEN, BORDERLESS, WINDOWED }

var currentWindowMode: WindowMode = WindowMode.BORDERLESS
var currentResolution: Vector2 = Vector2(1920, 1080)
var vsyncEnabled: bool = true
var maxFps: int = 60

var masterVolume: float = 1.0
var musicVolume: float = 1.0
var sfxVolume: float = 1.0
var uiVolume: float = 1.0

func _ready() -> void:
	var saveData = SaveManager.load_main_state()
	
	if saveData.has("settings"):
		var settings = saveData["settings"]
		
		currentWindowMode = settings.get("currentWindowMode", currentWindowMode) as WindowMode
		
		var res = settings.get("currentResolution", {"x": 1920, "y": 1080})
		if typeof(res) == TYPE_DICTIONARY:
			currentResolution = Vector2(res.get("x", 1920), res.get("y", 1080))
			
		vsyncEnabled = settings.get("vsyncEnabled", vsyncEnabled)
		maxFps = settings.get("maxFps", maxFps)
		
		masterVolume = settings.get("masterVolume", masterVolume)
		musicVolume = settings.get("musicVolume", musicVolume)
		sfxVolume = settings.get("sfxVolume", sfxVolume)
		uiVolume = settings.get("uiVolume", uiVolume)
		
		_apply_boot_settings()

func _apply_boot_settings() -> void:
	match currentWindowMode:
		WindowMode.FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		WindowMode.BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		WindowMode.WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(currentResolution)
			DisplayServer.window_set_position(DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() / 2) - (Vector2i(currentResolution) / 2))

	if vsyncEnabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		Engine.max_fps = 0
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = maxFps

func save_to_file() -> void:
	var saveData = SaveManager.load_main_state() 
	
	saveData["settings"] = {
		"currentWindowMode": currentWindowMode,
		"currentResolution": {"x": currentResolution.x, "y": currentResolution.y},
		"vsyncEnabled": vsyncEnabled,
		"maxFps": maxFps,
		
		"masterVolume": masterVolume,
		"musicVolume": musicVolume,
		"sfxVolume": sfxVolume,
		"uiVolume": uiVolume,
	}
	
	SaveManager.save_main_state(saveData)
