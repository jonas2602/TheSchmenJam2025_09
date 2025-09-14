extends Node2D

# These need to be set by the spawning script
var info : VehicleInfo = VehicleInfo.new()
var _time : float = 0

func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# move towards the destination
	_time += delta
	# TODO: Make this slow start/stop
	global_position = global_position.lerp(info.dst_position, _time/info.seconds_to_destination)
	
	if (position.distance_squared_to(info.dst_position) < 0.0001):
		_on_reach_destination()

	pass

func initialize_vehicle(vehicle_info : VehicleInfo):
	info     = vehicle_info
	global_position = vehicle_info.src_position
	pass

func _on_reach_destination():
	# conquer the tile and destroy this
	GlobalEventSystem.conquered_tile.emit(info.src_tile_coords, info.dst_tile_coords)
	queue_free()

	pass

func _on_area_2d_area_entered(area : Area2D):
	var other : Node = area.get_owner()
	print(name, " from ", info.src_tile_coords, " to ", info.dst_tile_coords, " caught by " + other.name)
	assert(other.name.begins_with("Guard"))

	# Handle "collision" with player
	GlobalEventSystem.player_conquer_stopped.emit(info.src_tile_coords, info.dst_tile_coords)
	queue_free()
