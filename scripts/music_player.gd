extends AudioStreamPlayer

@export var main_menu_music : AudioStreamWAV
@export var level_music     : AudioStreamWAV
@export var level_win_music : AudioStreamWAV
@export var level_lost_music : AudioStreamWAV

var _previous_track : AudioStream

func _ready() -> void:
	GlobalEventSystem.game_started.connect(_on_game_started)
	GlobalEventSystem.level_complete.connect(_on_level_complete)
	GlobalEventSystem.level_failed.connect(_on_level_failed)
	_play_music(main_menu_music)
	pass

func _play_music(music : AudioStreamWAV) -> bool:
	if music == null:
		print("Attempted to play music that was not set!")
		return false
	
	_previous_track = stream
	stream = music
	play()
	return true

func _play_music_one_shot(music : AudioStreamWAV):
	if not _play_music(music):
		return
		
	# wait for the finish event
	finished.connect(_on_music_done)
	return true

func _on_game_started():
	_play_music(level_music)
	pass

func _on_level_complete():
	_play_music_one_shot(level_win_music)
	pass

func _on_level_failed():
	_play_music_one_shot(level_lost_music)
	pass

func _on_music_done():
	_play_music(level_music)
	
	if finished.is_connected(_on_music_done):
		finished.disconnect(_on_music_done)
	
	pass
