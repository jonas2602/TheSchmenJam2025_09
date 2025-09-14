extends Node2D

@export var base_capture_time : float = 3.0
@export var self_faction_id : int = 2

@onready var interaction_layer : TileMapLayer = $Interaction
@onready var hover_layer       : TileMapLayer = $Hover
@onready var occupation_layer  : TileMapLayer = $Occupation

const atlas_coords_hovered_other   : Vector2i = Vector2i( 9, 4)
const atlas_coords_hovered_self    : Vector2i = Vector2i(10, 4)
const atlas_coords_hovered_neutral : Vector2i = Vector2i(11, 4)

const atlas_coords_selected_self  : Vector2i = Vector2i(11, 5)
const atlas_coords_selected_other : Vector2i = Vector2i( 9, 5)

const atlas_coords_active_attack_self  : Vector2i = Vector2i(11, 6)
const atlas_coords_active_attack_other : Vector2i = Vector2i( 9, 6)

const faction_id_neutral : int = -1

var attack_cell_origin : Vector2i = GlobalEventSystem.invalid_tile_pos
var attack_cell_target : Vector2i = GlobalEventSystem.invalid_tile_pos

func _get_cell_faction(cell_pos : Vector2i) -> int:
	var cell_data : TileData = occupation_layer.get_cell_tile_data(cell_pos)
	if (cell_data == null):
		return faction_id_neutral # cell is not marked up for a faction
	
	var faction_id : int = cell_data.get_custom_data("faction_id")
	return faction_id

func _involved_in_attack(cell_pos : Vector2i) -> bool:
	var cell_data : TileData = interaction_layer.get_cell_tile_data(cell_pos)
	if (cell_data == null):
		return false # cell is not marked up for a faction
	
	var active_attack : bool = cell_data.get_custom_data("active_attack")
	return active_attack

func _update_hovered_tile(old_cell_pos : Vector2i, new_cell_pos : Vector2i) -> void:
	# reset the old hover location
	if (old_cell_pos != GlobalEventSystem.invalid_tile_pos):
		hover_layer.set_cell(old_cell_pos, -1)
	
	var new_cell_faction : int = _get_cell_faction(new_cell_pos)
	var hovered_atlas_coords : Vector2i = atlas_coords_hovered_self
	if (new_cell_faction == faction_id_neutral):
		hovered_atlas_coords = atlas_coords_hovered_neutral # hovered cell is not marked up for a faction
	elif (new_cell_faction != self_faction_id):
		hovered_atlas_coords = atlas_coords_hovered_other # hovered cell is occupied by an enemy faction
	
	hover_layer.set_cell(new_cell_pos, 0, hovered_atlas_coords, 0)

func _is_neighbor_cell(cell_pos_a : Vector2i, cell_pos_b : Vector2i) -> bool:
	var offset : Vector2i = abs(cell_pos_b - cell_pos_a)
	if (offset.x == 0 && offset.y == 1):
		return true
	if (offset.x == 1 && offset.y == 0):
		return true
	return false

func _is_border_tile(cell_pos : Vector2i, other_faction_id : int, other_faction_match : bool) -> bool:
	var cell_faction_id : int = _get_cell_faction(cell_pos)
	
	var faction_id_right = _get_cell_faction(cell_pos + Vector2i(1, 0))
	if (cell_faction_id != faction_id_right && faction_id_right != faction_id_neutral && ((faction_id_right == other_faction_id) == other_faction_match)):
		return true
	
	var faction_id_down = _get_cell_faction(cell_pos + Vector2i(0, 1))
	if (cell_faction_id != faction_id_down && faction_id_down != faction_id_neutral && ((faction_id_down == other_faction_id) == other_faction_match)):
		return true
	
	var faction_id_left = _get_cell_faction(cell_pos + Vector2i(1, 0))
	if (cell_faction_id != faction_id_left && faction_id_left != faction_id_neutral && ((faction_id_left == other_faction_id) == other_faction_match)):
		return true
	
	var faction_id_up = _get_cell_faction(cell_pos + Vector2i(0, -1))
	if (cell_faction_id != faction_id_up && faction_id_up != faction_id_neutral && ((faction_id_up == other_faction_id) == other_faction_match)):
		return true
	return false

func _update_attack_tiles(new_cell_pos : Vector2i) -> void:
	var cell_faction : int = _get_cell_faction(new_cell_pos)
	if (cell_faction == faction_id_neutral):
		return
	
	# reset attack tiles when selecting them again
	if (new_cell_pos == attack_cell_origin):
		attack_cell_origin = GlobalEventSystem.invalid_tile_pos
		interaction_layer.set_cell(attack_cell_origin, -1)
		return
	if (new_cell_pos == attack_cell_target):
		# reset attack tile when selecting it again
		attack_cell_target = GlobalEventSystem.invalid_tile_pos
		interaction_layer.set_cell(attack_cell_target, -1)
		return
	
	if (_involved_in_attack(new_cell_pos)):
		return # can't reselect tiles while they are involved in an attack
	
	if (cell_faction == self_faction_id):
		# TODO: is adjacent to the already selected target tile / any enemy tile adjacent to self tile
		if (attack_cell_target != GlobalEventSystem.invalid_tile_pos && !_is_neighbor_cell(attack_cell_target, new_cell_pos)):
			return # not a neighbor of the already selected target tile
		if (!_is_border_tile(new_cell_pos, self_faction_id, false)):
			return # you can only attack tiles at your border
		
		interaction_layer.set_cell(attack_cell_origin, -1)
		attack_cell_origin = new_cell_pos
		interaction_layer.set_cell(attack_cell_origin, 0, atlas_coords_selected_self, 0)
		
	else:
		if (attack_cell_origin != GlobalEventSystem.invalid_tile_pos && !_is_neighbor_cell(attack_cell_origin, new_cell_pos)):
			return # not a neighbor of the already selected origin tile
		if (!_is_border_tile(new_cell_pos, self_faction_id, true)):
			return # you can only attack tiles at your border
		
		interaction_layer.set_cell(attack_cell_target, -1)
		attack_cell_target = new_cell_pos
		interaction_layer.set_cell(attack_cell_target, 0, atlas_coords_selected_other, 0)
	
	if (attack_cell_origin == GlobalEventSystem.invalid_tile_pos):
		return # origin not set yet
	if (attack_cell_target == GlobalEventSystem.invalid_tile_pos):
		return # target not set yet

	# start conquering the tile if not already in progress
	_start_conquering(attack_cell_origin, attack_cell_target)
	
	# reset attack tile cache
	attack_cell_origin = GlobalEventSystem.invalid_tile_pos
	attack_cell_target = GlobalEventSystem.invalid_tile_pos

func _input(event : InputEvent):
	# need to detect mouse over
	if event is InputEventMouseMotion:
		#print("Mouse is at: ", event.position)
		var topLeft := Vector2(0, 0);
		if get_viewport().get_camera_2d():
			topLeft = get_viewport().get_camera_2d().position - get_viewport_rect().size / 2;
		
		var cell_pos : Vector2i = occupation_layer.local_to_map(event.position + topLeft)
		if (cell_pos != GlobalEventSystem.hovered_tile_pos):
			print("Tile ", cell_pos, " is hovered")
			_update_hovered_tile(GlobalEventSystem.hovered_tile_pos, cell_pos)
			GlobalEventSystem.hovered_tile_changed.emit(cell_pos)
	pass
	
	var is_left_click_pressed : bool = event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT
	if is_left_click_pressed:
		var cell_pos : Vector2i = occupation_layer.local_to_map(event.position)
		_update_attack_tiles(cell_pos)

		# emit tile click event
		if (cell_pos != GlobalEventSystem.last_clicked_tile_pos):
			#print("Tile ", tile_pos, " is clicked")
			GlobalEventSystem.clicked_tile.emit(cell_pos)
		pass
	pass


func _start_conquering(attack_origin_pos : Vector2i, attack_target_pos : Vector2i):
	interaction_layer.set_cell(attack_origin_pos, 0, atlas_coords_active_attack_self, 0)
	interaction_layer.set_cell(attack_target_pos, 0, atlas_coords_active_attack_other, 0)
	
	print("Beginning to conquer tile: ", attack_target_pos)

	var conquered_timer = Timer.new()
	add_child(conquered_timer)
	conquered_timer.wait_time = base_capture_time
	conquered_timer.timeout.connect(func(): self._conquer_tile(attack_origin_pos, attack_target_pos))
	conquered_timer.one_shot = true
	conquered_timer.start()
	
	# add the timer to global list so it can be aborted
	GlobalEventSystem.conquering_tile_timers[attack_target_pos] = conquered_timer
	pass


func _conquer_tile(attack_origin_pos : Vector2i, attack_target_pos : Vector2i):
	# TODO: Pool the timers somehow?
	GlobalEventSystem.conquering_tile_timers[attack_target_pos].queue_free()
	GlobalEventSystem.conquering_tile_timers.erase(attack_target_pos)
	
	interaction_layer.set_cell(attack_origin_pos, -1)
	interaction_layer.set_cell(attack_target_pos, -1)
	
	var faction_atlas_coords : Vector2i = occupation_layer.get_cell_atlas_coords(attack_origin_pos)
	occupation_layer.set_cell(attack_target_pos, 0, faction_atlas_coords)
	
	GlobalEventSystem.conquered_tile.emit(attack_target_pos)
	
	pass
