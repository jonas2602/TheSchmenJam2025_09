extends Node

@export var rotation_speed  : float = 4.0
@export var target_rotation : float = 0

@export var rotation_delay_min    : float = 2
@export var rotation_delay_max    : float = 5
@export var rotation_delay_active : float = 0



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


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

func _on_area_2d_area_entered(area: Area2D) -> void:
	print("hit area: " + area.get_parent().name)


func _on_area_2d_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	# print("hit area shape: %s, %d, %d" % [area.name, area_shape_index, local_shape_index])
	pass # Replace with function body.


func _on_area_2d_body_entered(body: Node2D) -> void:
	# print("hit body: " + body.name)
	pass # Replace with function body.


func _on_area_2d_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	# print("hit body shape: %s, %d, %d" % [body.name, body_shape_index, local_shape_index])
	pass # Replace with function body.
