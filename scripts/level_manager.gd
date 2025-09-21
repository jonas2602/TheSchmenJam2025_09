extends Node

@export var level_lookup : Dictionary[String, Node2D] = {}
@export_range(0.01, 1.0) var conquer_tiles_percentage : float = 0.9

@onready var terrain_base_layer    : TileMapLayer = $GameMap/BaseTerrain
@onready var terrain_feature_layer : TileMapLayer = $GameMap/TerrainFeatures
@onready var occupation_layer      : TileMapLayer = $GameMap/Occupation
@onready var guards_root           : Node2D       = $GameMap/Guards
@onready var main_map              : Node2D       = $GameMap
@onready var game_hud              : Control      = $Camera/CanvasLayer/Hud

var active_level_flag : Node2D = null

var _tiles_to_conquer_list      : Array[Vector2i]
var _total_tiles_to_conquer     : int = 0
var _remaining_tiles_to_conquer : int = 0
var _max_player_detects_allowed : int = 0
var _current_player_detects     : int = 0
var _current_level : int = 0

func _ready() -> void:
	GlobalEventSystem.conquered_tile.connect(_on_conquered_tile)
	GlobalEventSystem.level_complete.connect(_on_level_complete)
	GlobalEventSystem.level_failed.connect(_on_level_failed)
	GlobalEventSystem.player_conquer_stopped.connect(_on_conquer_aborted)
	
	_activate_map("menu")

func _copy_cell(source_layer : TileMapLayer, source_coords : Vector2i, target_layer : TileMapLayer, target_coords : Vector2i) -> void:
	var source_id : int = source_layer.get_cell_source_id(source_coords)
	var atlas_coords : Vector2i = source_layer.get_cell_atlas_coords(source_coords)
	var alternative_tile : int = source_layer.get_cell_alternative_tile(source_coords)
	target_layer.set_cell(target_coords, source_id, atlas_coords, alternative_tile)

func _count_occupation_cell(coords : Vector2i) -> void:
	var tile_data : TileData = occupation_layer.get_cell_tile_data(coords)
	var faction_id : int = tile_data.get_custom_data("faction_id")
	if faction_id == GlobalEventSystem.faction_id_neutral or faction_id == GlobalEventSystem.faction_id_player:
		return # tile is not conquerable

	_total_tiles_to_conquer += 1
	
	# sorted insert into the list
	var index : int = _tiles_to_conquer_list.bsearch(coords)
	_tiles_to_conquer_list.insert(index, coords)

func copy_prefab_node(source_node : Node2D, new_parent_node) -> Node2D:
		var global_transform : Transform2D = source_node.get_global_transform()
		var new_node : Node2D = source_node.duplicate()
		new_parent_node.add_child(new_node)
		new_node.global_transform = global_transform
		return new_node

func _activate_map(map_name : String) -> void:
	var level_prefab : Node   = level_lookup.get(map_name)
	if (level_prefab == null):
		print("trying to activate unknown map: ", map_name)
		return
	
	var goal_flag : Node2D = level_prefab.find_child("Flag", true, false)
	var is_gameplay_map : bool = goal_flag.visible
	
	var level_offset : Vector2i = main_map._get_coords_for_world_pos(level_prefab.position)
	
	# copy terrain over
	var prefab_terrain_base_layer    : TileMapLayer = level_prefab.find_child(terrain_base_layer.name, true, false)
	var prefab_terrain_feature_layer : TileMapLayer = level_prefab.find_child(terrain_feature_layer.name, true, false)
	var prefab_occupation_layer      : TileMapLayer = level_prefab.find_child(occupation_layer.name, true, false)
	
	if (is_gameplay_map):
		_total_tiles_to_conquer = 0
		_tiles_to_conquer_list.clear()
	
	for source_coords : Vector2i in prefab_terrain_base_layer.get_used_cells():
		_copy_cell(prefab_terrain_base_layer, source_coords, terrain_base_layer, source_coords + level_offset)
	for source_coords : Vector2i in prefab_terrain_base_layer.get_used_cells():
		_copy_cell(prefab_terrain_feature_layer, source_coords, terrain_feature_layer, source_coords + level_offset)
	for source_coords : Vector2i in prefab_terrain_base_layer.get_used_cells():
		# NOTE: the following behaviour doesn't work with level resets as we don't know what tiles also exist in other levels
		# if (occupation_layer.get_cell_source_id(source_coords + level_offset) != -1):
		# 	continue # do not change the state of occupation tiles that already exist in the target layer
		_copy_cell(prefab_occupation_layer, source_coords, occupation_layer, source_coords + level_offset)
		
		if (is_gameplay_map):
			_count_occupation_cell(source_coords + level_offset)
	
	# spawn guards
	var prefab_guards_root : Node2D = level_prefab.find_child("Guards", true, false)
	for guard : Node2D in prefab_guards_root.get_children():
		var new_guard : Node2D = copy_prefab_node(guard, guards_root)
		new_guard._initialize_guard()
		
		# guard tiles cannot be conquered so decrement
		if (is_gameplay_map):
			_total_tiles_to_conquer -= 1
			_tiles_to_conquer_list.erase(occupation_layer.local_to_map(new_guard.global_transform.get_origin()))
	
	
	# multiply by the required percentage to get the goal
	if (is_gameplay_map):
		_total_tiles_to_conquer = floori(_total_tiles_to_conquer * conquer_tiles_percentage)
		_remaining_tiles_to_conquer = _total_tiles_to_conquer
		GlobalEventSystem.remaining_tiles_to_conquer = _remaining_tiles_to_conquer
	
		print("Tile to win: ", _total_tiles_to_conquer)
	
	@warning_ignore("integer_division") # suppress warning here as this is intentional
	_max_player_detects_allowed = _total_tiles_to_conquer / 10 + 1
	_current_player_detects     = 0
	print("Detects to lose: ", _max_player_detects_allowed)
	GlobalEventSystem.remaining_detections = _max_player_detects_allowed
	GlobalEventSystem.remaining_detections_changed.emit()
	
	# spawn the goal flag if it is not explicitly hidden by th designer
	if goal_flag.visible:
		var new_flag : Node2D = copy_prefab_node(goal_flag, self)
		new_flag.set_flag_tile(occupation_layer.local_to_map(new_flag.global_transform.get_origin()))
		active_level_flag = new_flag

func activate_next_level() -> void:
	_current_level += 1
	var map_name : String = "level0" + str(_current_level)
	_activate_map(map_name)
	pass

func activate_same_level() -> void:
	var map_name : String = "level0" + str(_current_level)
	_activate_map(map_name)
	pass

func _on_conquered_tile(_attack_origin_pos : Vector2i, attack_target_pos : Vector2i):
	var activate_name : String = main_map._get_cell_activate_name(attack_target_pos)
	if (not activate_name.is_empty()):
		return _handle_activation_tile(activate_name)
	
	# non-activation, enemy territory was conquered
	_process_conquered_tile(attack_target_pos)

func _process_conquered_tile(attack_target_pos : Vector2i):
	# Check if the tile is within the level bounds
	var index : int = _tiles_to_conquer_list.bsearch(attack_target_pos)
	if index >= _tiles_to_conquer_list.size() || _tiles_to_conquer_list[index] != attack_target_pos:
		return  # not in list
	
	_remaining_tiles_to_conquer -= 1
	_tiles_to_conquer_list.remove_at(index)
	
	if (_remaining_tiles_to_conquer != 0):
		print("Tile to win: ", _remaining_tiles_to_conquer)
		GlobalEventSystem.remaining_tiles_to_conquer = _remaining_tiles_to_conquer
		GlobalEventSystem.remaining_tiles_to_conquer_changed.emit()
		pass
	else: # player has achieved the goal, emit win event
		print("You win!")
		GlobalEventSystem.level_complete.emit()
		pass

func _delete_guard(guard : Node2D):
	var guard_pos : Vector2 = guard.global_position
	var guard_tile_coord : Vector2i = occupation_layer.local_to_map(guard_pos)
	# just append here as this list will be cleared afterwards
	main_map._toggle_cell_blocked(guard_tile_coord, false)
	_tiles_to_conquer_list.append(guard_tile_coord)
	guard.queue_free()

func _on_level_complete():
	for guard : Node2D in guards_root.get_children():
		_delete_guard(guard)

	active_level_flag = null

	main_map.set_tiles_as_conquered(_tiles_to_conquer_list)
	_tiles_to_conquer_list.clear()
	_remaining_tiles_to_conquer = 0
	
	activate_next_level()

func _on_level_failed():
	for guard : Node2D in guards_root.get_children():
		_delete_guard(guard)
	
	if (active_level_flag != null):
		active_level_flag.queue_free()
		active_level_flag = null
	
	_tiles_to_conquer_list.clear()
	_remaining_tiles_to_conquer = 0
	
	activate_same_level()

func _handle_activation_tile(activate_name : String):
	print("activate: ", activate_name)
	
	if (activate_name == "quit"):
		get_tree().quit()
		return
	
	if (activate_name.begins_with("map_")):
		var map_name : String = activate_name.substr(len("map_"))
			
		_activate_map(map_name)
		GlobalEventSystem.game_started.emit()
		return
	
	if (activate_name.begins_with("credit_")):
		var contributor_name : String = activate_name.substr(len("credit_"))
		game_hud._play_credit_quote(contributor_name)
		return
	
	print("unknown action for: ", activate_name)

func _on_conquer_aborted(_attack_origin_pos : Vector2i, _attack_target_pos : Vector2i):
	_current_player_detects += 1
	GlobalEventSystem.remaining_detections = _max_player_detects_allowed - _current_player_detects
	print("Detects left: ", GlobalEventSystem.remaining_detections)
	game_hud._play_random_enemy_quote()
	
	GlobalEventSystem.remaining_detections_changed.emit()
	
	if (GlobalEventSystem.remaining_detections < 0):
		print("You lose!")
		GlobalEventSystem.level_failed.emit()
