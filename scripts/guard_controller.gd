extends Node

@export var rotation_speed  : float = 4.0
@export var target_rotation : float = 0
@export var self_faction_id : int   = GlobalEventSystem.faction_id_neutral

@export var rotation_delay_min    : float = 2
@export var rotation_delay_max    : float = 5
@export var rotation_delay_active : float = 0

@onready var game_map : Node = get_tree().get_root().find_child("GameMap", true, false)

# Called when the node enters the scene tree for the first time.
func _ready():
	var self_tile_pos : Vector2i = game_map._get_cell_pos_from_world_pos(self.position)
	self_faction_id = game_map._get_cell_faction(self_tile_pos)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (self.rotation_degrees == target_rotation):
		return
	
	self.rotation_degrees = lerp(self.rotation_degrees, target_rotation, rotation_speed * delta)

func _init_rotation(delta_degrees : float):
	target_rotation    = target_rotation + delta_degrees
	# print("new target: %f" % (target_rotation))

func _on_timer_timeout():
	var delta_degrees : float = randf_range(-180.0, 180.0)
	_init_rotation(delta_degrees)
	
	rotation_delay_active = randf_range(rotation_delay_min, rotation_delay_max)
	$Timer.set_wait_time(rotation_delay_active)
	
	pass

func _on_area_2d_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	var cell_pos : Vector2i = game_map._get_coords_for_body_rid(body_rid)
	if (!game_map._involved_in_attack(cell_pos)):
		return # only care about attacked tiles
	
	var cell_faction_id : int = game_map._get_cell_faction(cell_pos)
	if (cell_faction_id != self_faction_id):
		return # only care about attacks to tiles of my own faction
	
	print("hit body shape: %d, (%d, %d), %s, %d, %d" % [body_rid.get_id(), cell_pos.x, cell_pos.y, body.name, body_shape_index, local_shape_index])
	pass # Replace with function body.
