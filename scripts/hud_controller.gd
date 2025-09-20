extends Node

@export var portrait_lookup : Dictionary[String, AnimatedTexture] = {}
@export var contributor_quote_lookup : Dictionary[String, String] = {}

@onready var face_texture_rect : TextureRect = $DialogBox/FaceSurrounding/Face
@onready var quote_label : Label = $DialogBox/Panel/Label
@onready var dialog_box : Node2D = $DialogBox

func _ready() -> void:
	dialog_box.visible = false

func _play_quote(character_name : String, quote : String) -> void:
	var portrait : AnimatedTexture = portrait_lookup.get(character_name)
	if (portrait == null):
		print("Can't find portrait for ", character_name)
		return
	
	dialog_box.visible = true
	face_texture_rect.texture = portrait
	quote_label.text = quote
	await get_tree().create_timer(2.0).timeout
	dialog_box.visible = false
	

func _play_credit_quote(contributor_name : String) -> void:
	var quote : String = contributor_quote_lookup.get(contributor_name, "")
	if (len(quote) == 0):
		print("Can't find credit quote for ", contributor_name)
		return

	_play_quote(contributor_name, quote)
