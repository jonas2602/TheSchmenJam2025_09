extends AudioStreamPlayer

@export var main_menu_music : AudioStreamWAV
@export var level_music     : AudioStreamWAV


func _ready() -> void:
	stream = main_menu_music
	GlobalEventSystem.game_started.connect(_on_game_started)
	play()
	pass

func _on_game_started():
	stream = level_music
	play()
	pass
