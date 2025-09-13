extends Node
	
static var hovered_tile_pos        = Vector2i(255, 255)
static var last_clicked_tile_pos   = Vector2i(255, 255)
static var last_conquered_tile_pos = Vector2i(255, 255)
static var conquering_tile_timers  = {}


signal hovered_tile_changed(tile_pos : Vector2i)
signal clicked_tile(tile_pos : Vector2i)
signal conquered_tile(tile_pos : Vector2i)

# Various handlers to cache the state global state for other scripts

func _init() -> void:
	hovered_tile_changed.connect(_on_hovered_tile_changed)
	clicked_tile.connect(_on_tile_clicked)
	conquered_tile.connect(_on_tile_conquered)
	pass

func _on_hovered_tile_changed(tile_pos : Vector2i):
	print("Changing hovered tile from ", hovered_tile_pos, " to ", tile_pos)
	hovered_tile_pos = tile_pos
	pass

func _on_tile_clicked(tile_pos : Vector2i):
	print("Last clicked tile changed from ", last_clicked_tile_pos, " to ", tile_pos)
	last_clicked_tile_pos = tile_pos
	pass

func _on_tile_conquered(tile_pos : Vector2i):
	print("Last conquered tile changed from ", last_conquered_tile_pos, " to ", tile_pos)
	last_conquered_tile_pos = tile_pos
	pass
