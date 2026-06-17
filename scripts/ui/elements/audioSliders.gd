extends Control

@export_enum("Master", "Music", "Effects", "UI") var busName: String = "Master"

@onready var slider = $HSlider
@onready var label = $DescriptionLabel

var busIndex: int
var defaultSliderPercentage: float = 70.0

func _ready() -> void:
	slider.focus_mode = Control.FOCUS_NONE
	busIndex = AudioServer.get_bus_index(busName)
	
	var savedLinearVolume: float = 1.0
	match busName:
		"Master": savedLinearVolume = SettingsData.masterVolume
		"Music": savedLinearVolume = SettingsData.musicVolume
		"Effects": savedLinearVolume = SettingsData.sfxVolume
		"UI": savedLinearVolume = SettingsData.uiVolume
	
	var startingSliderValue = savedLinearVolume * defaultSliderPercentage
	
	slider.set_value_no_signal(startingSliderValue)
	_update_label(startingSliderValue)
	_apply_audio_volume(startingSliderValue)
	
	slider.value_changed.connect(_on_slider_value_changed)
	
	if not slider.mouse_entered.is_connected(AudioManager.play_button_hover):
		slider.mouse_entered.connect(AudioManager.play_button_hover)

func _on_slider_value_changed(newValue: float) -> void:
	_update_label(newValue)
	_apply_audio_volume(newValue)
	
	var linearValue = newValue / defaultSliderPercentage
	match busName:
		"Master": SettingsData.masterVolume = linearValue
		"Music": SettingsData.musicVolume = linearValue
		"Effects": SettingsData.sfxVolume = linearValue
		"UI": SettingsData.uiVolume = linearValue

func _apply_audio_volume(sliderValue: float) -> void:
	var linearValue: float
	
	if sliderValue <= defaultSliderPercentage:
		# SMOOTH LOW END: Normal linear math from 0 to 70
		linearValue = sliderValue / defaultSliderPercentage
	else:
		# PUNCHY HIGH END: Exponential boost from 70 to 100
		var baseLinear = sliderValue / defaultSliderPercentage
		linearValue = pow(baseLinear, 3.0)
	
	var dbVolume = linear_to_db(linearValue)
	AudioServer.set_bus_volume_db(busIndex, dbVolume)
	
	AudioServer.set_bus_mute(busIndex, sliderValue == 0)

func _update_label(sliderValue: float) -> void:
	# Cast to int to permanently strip the decimal before turning to text
	label.text = str(int(sliderValue))
