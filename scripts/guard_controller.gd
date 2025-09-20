extends Node

@export var rotation_speed  : float = 4.0
@export var target_rotation : float = 0
@export var GlobalEventSystem.faction_id_player : int   = GlobalEventSystem.faction_id_neutral

@export var rotation_delay_min    : float = 2
@export var rotation_delay_max    : float = 5
@export var rotation_delay_active : float = 0
@export var rotation_delay_detect : float = 4

@onready var sprite_rect_node : AnimatedSprite2D = $AnimatedSprite2D

@onready var game_map : Node = get_tree().get_root().find_child("GameMap", true, false)

# Called when the node enters the scene tree for the first time.
func _ready():
	var self_tile_pos : Vector2i = game_map._get_coords_for_world_pos(self.position)
	GlobalEventSystem.faction_id_player = game_map._get_cell_faction(self_tile_pos)
	
	rotation_delay_active = randf_range(rotation_delay_min, rotation_delay_max)
	$Timer.start(rotation_delay_detect)

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
	$Timer.start(rotation_delay_detect)
	
	pass

func _on_vision_cone_area_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	var other : Node2D = area.get_owner()
	if (!other.name.begins_with("Vehicle")):
		return # collision with another guard
	
	# stay focused on the current spot for a while
	var forward    : Vector2 = Vector2(1, 0).rotated(self.rotation)
	var target_dir : Vector2 = (other.position - self.position).normalized()
	var angle_rad : float = forward.angle_to(target_dir)
	var angle_deg : float = rad_to_deg(angle_rad)
	_init_rotation(angle_deg)
	
	$Timer.start(rotation_delay_detect)
	sprite_rect_node.play("detect")
