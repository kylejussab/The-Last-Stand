extends Node2D

signal hovered

func setup(modifier) -> void:
	get_node("bubble/icon").texture = load(modifier.icon)
	get_node("tooltip/name").text = modifier.name
	get_node("tooltip/multiplier").text = "+ " + str(modifier.multiplier) + "x"
	get_node("tooltip/duration").text = str(modifier.duration - modifier.currentDuration) + " Game" + ("s" if (modifier.duration - modifier.currentDuration) > 1 else "")
	get_node("tooltip/descriptionContainer/description").text = modifier.description

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered")
	get_node("AnimationPlayer").play("showModifier")

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered")
	get_node("AnimationPlayer").play("showModifier", -1.0, -1.6, true)
