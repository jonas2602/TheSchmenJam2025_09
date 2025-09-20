extends Node

@export var level_lookup : Dictionary[String, Node2D] = {}

@onready var terrain_base_layer    : TileMapLayer = $GameMap/BaseTerrain
@onready var terrain_feature_layer : TileMapLayer = $GameMap/TerrainFeatures
@onready var occupation_layer      : TileMapLayer = $GameMap/Occupation
@onready var guards_root           : Node2D       = $GameMap/Guards
@onready var main_map              : Node2D       = $GameMap

func _ready() -> void:
	GlobalEventSystem.conquered_tile.connect(_on_conquered_tile)
	
	_activate_map("menu")

func _copy_cell(source_layer : TileMapLayer, source_coords : Vector2i, target_layer : TileMapLayer, target_coords : Vector2i) -> void:
	var source_id : int = source_layer.get_cell_source_id(source_coords)
	var atlas_coords : Vector2i = source_layer.get_cell_atlas_coords(source_coords)
	var alternative_tile : int = source_layer.get_cell_alternative_tile(source_coords)
	target_layer.set_cell(target_coords, source_id, atlas_coords, alternative_tile)
	
func _activate_map(name : String) -> void:
	var level_prefab : Node2D   = level_lookup.get(name)
	var level_offset : Vector2i = main_map._get_coords_for_world_pos(level_prefab.position)
	
	# copy terrain over
	var prefab_terrain_base_layer    : TileMapLayer = level_prefab.find_child(terrain_base_layer.name, true, false)
	var prefab_terrain_feature_layer : TileMapLayer = level_prefab.find_child(terrain_feature_layer.name, true, false)
	var prefab_occupation_layer      : TileMapLayer = level_prefab.find_child(occupation_layer.name, true, false)
	
	for source_coords : Vector2i in prefab_terrain_base_layer.get_used_cells():
		_copy_cell(prefab_terrain_base_layer, source_coords, terrain_base_layer, source_coords + level_offset)
	for source_coords : Vector2i in prefab_terrain_base_layer.get_used_cells():
		_copy_cell(prefab_terrain_feature_layer, source_coords, terrain_feature_layer, source_coords + level_offset)
	for source_coords : Vector2i in prefab_terrain_base_layer.get_used_cells():
		_copy_cell(prefab_occupation_layer, source_coords, occupation_layer, source_coords + level_offset)
		
	# spawn guards
	var prefab_guards_root : Node2D = level_prefab.find_child("Guards", true, false)
	for guard : Node2D in prefab_guards_root.get_children():
		var global_transform : Transform2D = guard.get_global_transform()
		var new_guard : Node2D = guard.duplicate()
		guards_root.add_child(new_guard)
		new_guard.global_transform = global_transform
		new_guard._initialize_guard(main_map)

func _on_conquered_tile(attack_origin_pos : Vector2i, attack_target_pos : Vector2i):
	var activate_name : String = main_map._get_cell_activate_name(attack_target_pos)
	if (activate_name.is_empty()):
		return
	print("activate: ", activate_name)
	if (activate_name == "quit"):
		get_tree().quit()
	
	if (level_lookup.get(activate_name) != null):
		_activate_map(activate_name)
