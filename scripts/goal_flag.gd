extends Node2D

@onready var goal_label  : Label = $Label
@onready var flag_sprite : AnimatedSprite2D = $AnimatedSprite2D

var _is_flagged_captured : bool     = false
var _flag_tile_coords    : Vector2i = GlobalEventSystem.invalid_tile_pos
var _captured_flag_text : String = ""

func _ready() -> void:
	goal_label.text = "Capture the flag!"
	flag_sprite.play("faction_1")
	
	GlobalEventSystem.conquered_tile.connect(_on_tile_conquered)
	GlobalEventSystem.remaining_tiles_to_conquer_changed.connect(_on_remaining_tiles_to_conquer_changed)

func set_flag_tile(coords : Vector2i):
	_flag_tile_coords = coords

func _on_tile_conquered(_src_tile_pos : Vector2i, dst_tile_pos : Vector2i):
	if _is_flagged_captured: 
		return
	
	if dst_tile_pos != _flag_tile_coords:
		return
	
	flag_sprite.play("allied")
	_is_flagged_captured = true
	update_flag_text()
	pass

func _on_remaining_tiles_to_conquer_changed():
	if _is_flagged_captured:
		update_flag_text()

func update_flag_text():
	goal_label.text = "Capture " + str(GlobalEventSystem.remaining_tiles_to_conquer) + " more territories!"
