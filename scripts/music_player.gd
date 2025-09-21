extends AudioStreamPlayer

@export var main_menu_music : AudioStreamWAV
@export var level_music     : AudioStreamWAV
@export var level_win_music : AudioStreamWAV

func _ready() -> void:
	stream = main_menu_music
	GlobalEventSystem.game_started.connect(_on_game_started)
	GlobalEventSystem.level_complete.connect(_on_level_complete)
	play()
	pass

func _play_music(music : AudioStreamWAV):
	if music == null:
		print("Attempted to play music that was not set!")
		return
	
	stream = music
	play()

func _on_game_started():
	_play_music(level_music)
	pass

func _on_level_complete():
	_play_music(level_win_music)
	
	# wait for the finish event
	finished.connect(_on_music_done)
	pass

func _on_music_done():
	_play_music(level_music)
	
	if finished.is_connected(_on_music_done):
		finished.disconnect(_on_music_done)
	
	pass
