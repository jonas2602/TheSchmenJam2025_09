extends Node

@export var level_lookup : Dictionary[String, Node2D] = {}
@export_range(0.01, 1.0) var conquer_tiles_percentage : float = 0.9

@onready var terrain_base_layer    : TileMapLayer = $GameMap/BaseTerrain
@onready var terrain_feature_layer : TileMapLayer = $GameMap/TerrainFeatures
@onready var occupation_layer      : TileMapLayer = $GameMap/Occupation
@onready var guards_root           : Node2D       = $GameMap/Guards
@onready var main_map              : Node2D       = $GameMap
@onready var game_hud              : Control      = $Camera/CanvasLayer/Hud

var _tiles_to_conquer_list      : Array[Vector2i]
var _total_tiles_to_conquer     : int = 0
var _remaining_tiles_to_conquer : int = 0

func _ready() -> void:
	GlobalEventSystem.conquered_tile.connect(_on_conquered_tile)
	
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

func _activate_map(map_name : String) -> void:
	var level_prefab : Node   = level_lookup.get(map_name)
	var level_offset : Vector2i = main_map._get_coords_for_world_pos(level_prefab.position)
	
	# copy terrain over
	var prefab_terrain_base_layer    : TileMapLayer = level_prefab.find_child(terrain_base_layer.name, true, false)
	var prefab_terrain_feature_layer : TileMapLayer = level_prefab.find_child(terrain_feature_layer.name, true, false)
	var prefab_occupation_layer      : TileMapLayer = level_prefab.find_child(occupation_layer.name, true, false)
	
	_total_tiles_to_conquer = 0
	_tiles_to_conquer_list.clear()
	
	for source_coords : Vector2i in prefab_terrain_base_layer.get_used_cells():
		_copy_cell(prefab_terrain_base_layer, source_coords, terrain_base_layer, source_coords + level_offset)
	for source_coords : Vector2i in prefab_terrain_base_layer.get_used_cells():
		_copy_cell(prefab_terrain_feature_layer, source_coords, terrain_feature_layer, source_coords + level_offset)
	for source_coords : Vector2i in prefab_terrain_base_layer.get_used_cells():
		if (occupation_layer.get_cell_source_id(source_coords + level_offset) != -1):
			continue # do not change the state of occupation tiles that already exist in the target layer
		_copy_cell(prefab_occupation_layer, source_coords, occupation_layer, source_coords + level_offset)
		_count_occupation_cell(source_coords + level_offset)
	
	# spawn guards
	var prefab_guards_root : Node2D = level_prefab.find_child("Guards", true, false)
	for guard : Node2D in prefab_guards_root.get_children():
		var global_transform : Transform2D = guard.get_global_transform()
		var new_guard : Node2D = guard.duplicate()
		guards_root.add_child(new_guard)
		new_guard.global_transform = global_transform
		new_guard._initialize_guard(main_map)
		
		# guard tiles cannot be conquered so decrement
		_total_tiles_to_conquer -= 1
		_tiles_to_conquer_list.erase(occupation_layer.local_to_map(global_transform.get_origin()))
	
	# multiply by the required percentage to get the goal
	_total_tiles_to_conquer = floori(_total_tiles_to_conquer * conquer_tiles_percentage)
	_remaining_tiles_to_conquer = _total_tiles_to_conquer
	
	print("Tile to win: ", _total_tiles_to_conquer)

func _on_conquered_tile(_attack_origin_pos : Vector2i, attack_target_pos : Vector2i):
	var activate_name : String = main_map._get_cell_activate_name(attack_target_pos)
	if (not activate_name.is_empty()):
		return _handle_activation_tile(activate_name)
	
	# non-activation, enemy territory was conquered
	_process_conquered_tile(attack_target_pos)

func _process_conquered_tile(attack_target_pos : Vector2i):
	# Check if the tile is within the level bounds
	var index : int = _tiles_to_conquer_list.bsearch(attack_target_pos)
	if _tiles_to_conquer_list[index] != attack_target_pos:
		return  # not in list
	
	_remaining_tiles_to_conquer -= 1
	_tiles_to_conquer_list.remove_at(index)
	
	if (_remaining_tiles_to_conquer != 0):
		print("Tile to win: ", _remaining_tiles_to_conquer)
		GlobalEventSystem.remaining_tiles_to_conquer_changed.emit(_remaining_tiles_to_conquer)
		pass
	else: # player has achieved the goal, emit win event
		print("You win!")
		GlobalEventSystem.level_complete.emit()
		pass

func _handle_activation_tile(activate_name : String):
	print("activate: ", activate_name)
	
	if (activate_name == "quit"):
		get_tree().quit()
		return
	
	if (activate_name.begins_with("map_")):
		var map_name : String = activate_name.substr(len("map_"))
		if (level_lookup.get(map_name) == null):
			print("trying to activate unknown map: ", map_name)
			return
			
		_activate_map(map_name)
		return
	
	if (activate_name.begins_with("credit_")):
		var contributor_name : String = activate_name.substr(len("credit_"))
		game_hud._play_credit_quote(contributor_name)
		return
	
	print("unknown action for: ", activate_name)
