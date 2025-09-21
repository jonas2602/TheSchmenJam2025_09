extends Node2D

@onready var goal_label  : Label = $Label
@onready var flag_sprite : AnimatedSprite2D = $AnimatedSprite2D

var _flag_tile_coords    : Vector2i = GlobalEventSystem.invalid_tile_pos

func _ready() -> void:
	flag_sprite.play("faction_1")
	update_flag_text()
	
	GlobalEventSystem.conquered_tile.connect(_on_tile_conquered)
	GlobalEventSystem.level_complete.connect(_on_level_complete)
	GlobalEventSystem.remaining_detections_changed.connect(_on_text_conditions_changed)
	GlobalEventSystem.remaining_tiles_to_conquer_changed.connect(_on_text_conditions_changed)

func set_flag_tile(coords : Vector2i):
	_flag_tile_coords = coords

func _on_tile_conquered(_src_tile_pos : Vector2i, dst_tile_pos : Vector2i):
	if dst_tile_pos != _flag_tile_coords:
		return
	
	flag_sprite.play("allied")
	
	# disconnect from the event and update the text if the level hasn't been completed
	if GlobalEventSystem.conquered_tile.is_connected(_on_tile_conquered):
		update_flag_text()
		GlobalEventSystem.conquered_tile.disconnect(_on_tile_conquered)
	pass

func _on_text_conditions_changed():
	update_flag_text()

func update_flag_text():
	var flag_captured : bool = flag_sprite.animation.begins_with("allied")
	if (flag_captured):
		goal_label.text = "Capture " + str(GlobalEventSystem.remaining_tiles_to_conquer) + " more territories!"
	else:
		goal_label.text = "Capture the flag!"
	
	goal_label.text += "\nDetections remaining: " + str(GlobalEventSystem.remaining_detections)

func _on_level_complete():
	goal_label.text = "Area captured!"
	
	# disconnect from all events
	if GlobalEventSystem.conquered_tile.is_connected(_on_tile_conquered):
		GlobalEventSystem.conquered_tile.disconnect(_on_tile_conquered)
	if GlobalEventSystem.level_complete.is_connected(_on_level_complete):
		GlobalEventSystem.level_complete.disconnect(_on_level_complete)
	if GlobalEventSystem.remaining_tiles_to_conquer_changed.is_connected(_on_text_conditions_changed):
		GlobalEventSystem.remaining_tiles_to_conquer_changed.disconnect(_on_text_conditions_changed)
	if GlobalEventSystem.remaining_detections_changed.is_connected(_on_text_conditions_changed):
		GlobalEventSystem.remaining_detections_changed.disconnect(_on_text_conditions_changed)
