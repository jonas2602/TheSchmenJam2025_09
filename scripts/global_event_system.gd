extends Node

static var hovered_tile_pos      = Vector2i(255, 255)
static var last_clicked_tile_pos = Vector2i(255, 255)

signal hovered_tile_changed(tile_pos : Vector2i)
signal clicked_tile(tile_pos : Vector2i)


func _init() -> void:
	hovered_tile_changed.connect(_on_hovered_tile_changed)
	clicked_tile.connect(_on_tile_clicked)
	pass

func _on_hovered_tile_changed(tile_pos : Vector2i):
	print("Changing hovered tile from ", hovered_tile_pos, " to ", tile_pos)
	hovered_tile_pos = tile_pos
	pass

func _on_tile_clicked(tile_pos : Vector2i):
	print("Last clicked tile changed from ", last_clicked_tile_pos, " to ", tile_pos)
	last_clicked_tile_pos = tile_pos
	pass
