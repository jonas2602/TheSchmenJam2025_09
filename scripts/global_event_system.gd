extends Node

static var hovered_tile_pos = Vector2i(255, 255)

signal hovered_tile_changed(tile_pos : Vector2i)
signal clicked_tile(tile_pos : Vector2i)

func _init() -> void:
	hovered_tile_changed.connect(_on_hovered_tile_changed)
	pass

func _on_hovered_tile_changed(tile_pos : Vector2i):
	print("Changing hovered tile from ", hovered_tile_pos, " to ", tile_pos)
	hovered_tile_pos = tile_pos
	pass
