extends Node2D

@export var base_capture_time : float = 3.0

@onready var tile_map_layer = $TileMapLayer
@onready var camera = $Camera

func _input(event):
	# need to detect mouse over
	if event is InputEventMouseMotion:
		#print("Mouse is at: ", event.position)
		var topLeft = camera.position - get_viewport_rect().size / 2;
		var tile_pos	 = tile_map_layer.local_to_map(event.position + topLeft)
		if (tile_pos != GlobalEventSystem.hovered_tile_pos):
			print("Tile ", tile_pos, " is selected")
			GlobalEventSystem.hovered_tile_changed.emit(tile_pos)
	pass
	
	var is_left_click_pressed = event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT
	if is_left_click_pressed:
		var tile_pos  = tile_map_layer.local_to_map(event.position)
		var tile_data = tile_map_layer.get_cell_tile_data(tile_pos)
		if not tile_data:
			return # not a valid cell
			
		# start conquering the tile if not already in progress
		_start_conquering(tile_pos, tile_data)

		# emit tile click event
		if (tile_pos != GlobalEventSystem.last_clicked_tile_pos):
			#print("Tile ", tile_pos, " is clicked")
			GlobalEventSystem.clicked_tile.emit(tile_pos)
		pass
	pass


func _start_conquering(tile_pos : Vector2i, tile_data : TileData):
	
	if tile_pos in GlobalEventSystem.conquering_tile_timers:
		return # already being conquered
		
	if tile_data.get_custom_data("conquered"):
		print("Tile: ", tile_pos, " is already conquered!")
		return # already conquered
	
	print("Beginning to conquer tile: ", tile_pos)

	var conquered_timer = Timer.new()
	add_child(conquered_timer)
	conquered_timer.wait_time = base_capture_time
	conquered_timer.timeout.connect(func(): self._conquer_tile(tile_pos, tile_data))
	conquered_timer.one_shot = true
	conquered_timer.start()
	
	# add the timer to global list so it can be aborted
	GlobalEventSystem.conquering_tile_timers[tile_pos] = conquered_timer
	pass


func _conquer_tile(tile_pos : Vector2i, tile_data : TileData):
	# TODO: Pool the timers somehow?
	GlobalEventSystem.conquering_tile_timers[tile_pos].queue_free()
	GlobalEventSystem.conquering_tile_timers.erase(tile_pos)
	
	tile_data.set_custom_data("conquered", true)
	
	# TODO: modify tile map layer
	
	GlobalEventSystem.conquered_tile.emit(tile_pos)
	
	pass
