extends TextureButton

@export var cardKey: String

func _on_toggled(toggled_on: bool):
	if toggled_on:
		$"../../../../MarginContainer/HBoxContainer/DescLabel".show()
		owner.update_preview_card(cardKey)
	else:
		$"../../../../MarginContainer/HBoxContainer/DescLabel".hide()
