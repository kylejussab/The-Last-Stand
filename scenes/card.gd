extends Node2D

signal on
signal off

func _ready() -> void:
	get_parent().connect_card_signals(self)

func _on_area_2d_mouse_entered() -> void:
	emit_signal("on", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("off", self)
