class_name VehicleInfo

var src_tile_coords : Vector2i = GlobalEventSystem.invalid_tile_pos
var dst_tile_coords : Vector2i = GlobalEventSystem.invalid_tile_pos
var src_position    : Vector2  = Vector2()
var dst_position    : Vector2  = Vector2()
var seconds_to_destination : float = 3.0 # some reasonable default
var target_faction_id : int = 0
