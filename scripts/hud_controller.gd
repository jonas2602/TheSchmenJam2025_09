extends Node

@export var portrait_lookup : Dictionary[String, AnimatedTexture] = {}
@export var contributor_quote_lookup : Dictionary[String, String] = {}

@export var arr_enemy_quotes : Array[String] = []

@onready var face_texture_rect : TextureRect = $DialogBox/FaceSurrounding/Face
@onready var quote_label : Label = $DialogBox/Panel/Label
@onready var dialog_box : Node2D = $DialogBox

@onready var _reset_dialog_timer : Timer = $Timer

func _ready() -> void:
	dialog_box.visible = false

func _play_quote(character_name : String, quote : String) -> void:
	var portrait : AnimatedTexture = portrait_lookup.get(character_name)
	if (portrait == null):
		print("Can't find portrait for ", character_name)
		return
	
	_reset_dialog_timer.stop()
	
	dialog_box.visible = true
	face_texture_rect.texture = portrait
	quote_label.text = quote
	_reset_dialog_timer.wait_time = 2.0
	_reset_dialog_timer.start()

func _reset_dialog():
	dialog_box.visible = false

func _play_credit_quote(contributor_name : String) -> void:
	var quote : String = contributor_quote_lookup.get(contributor_name, "")
	if (len(quote) == 0):
		print("Can't find credit quote for ", contributor_name)
		return

	_play_quote(contributor_name, quote)
	
func _play_random_enemy_quote() -> void:
	if (arr_enemy_quotes.is_empty()):
		print("no enemy quotes setup")
		return

	var quote_index : int = randi_range(0, arr_enemy_quotes.size() - 1)
	var quote : String = arr_enemy_quotes[quote_index]
	_play_quote("oldman", quote)

func _on_timer_timeout() -> void:
	_reset_dialog()
