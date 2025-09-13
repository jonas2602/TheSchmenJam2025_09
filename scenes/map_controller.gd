extends Node2D

@onready var tile_map_layer = $TileMapLayer


func _input(event):
# need to detect mouse over
	if 	event is InputEventMouseMotion:
		#print("Mouse is at: ", event.position)
		var tile_pos	 = tile_map_layer.local_to_map(event.position)
		if (tile_pos != GlobalEventSystem.hovered_tile_pos):
			print("Tile ", tile_pos, " is selected")
			GlobalEventSystem.hovered_tile_changed.emit(tile_pos)
	pass
	

# need to modify the grid state
