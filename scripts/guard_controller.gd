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
	print("new target: %f" % (target_rotation))

func _on_timer_timeout():
	var delta_degrees : float = randf_range(-180.0, 180.0)
	_init_rotation(delta_degrees)
	
	rotation_delay_active = randf_range(rotation_delay_min, rotation_delay_max)
	$Timer.set_wait_time(rotation_delay_active)
	
	pass
