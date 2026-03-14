extends Node

const MENU_MUSIC_PATH := "res://assets/sprites/music/menu.mp3"
const GAME_MUSIC_PATH := "res://assets/sprites/music/ongoing.mp3"
const SFX_PATHS := {
	"ui": "res://assets/sprites/music/paper.mp3",
	"card_add": "res://assets/sprites/music/pop.mp3",
	"card_remove": "res://assets/sprites/music/paper.mp3",
	"confirm": "res://assets/sprites/music/stab.mp3",
	"resolve": "res://assets/sprites/music/thud.mp3",
	"result": "res://assets/sprites/music/faaah.mp3",
}

@onready var bgm_player := AudioStreamPlayer.new()

var current_bgm_key := ""
var stream_cache: Dictionary = {}


func _ready() -> void:
	add_child(bgm_player)
	bgm_player.volume_db = -13.0
	bgm_player.bus = "Master"


func play_menu_music() -> void:
	_play_bgm("menu", _load_mp3_stream(MENU_MUSIC_PATH), -11.0)


func play_game_music() -> void:
	_play_bgm("game", _load_mp3_stream(GAME_MUSIC_PATH), -15.0)


func play_bgm() -> void:
	play_game_music()


func play_sfx(stream_name: String, pitch_variance: float = 0.04) -> void:
	var source := _load_mp3_stream(str(SFX_PATHS.get(stream_name, "")))
	if source == null:
		return

	var player := AudioStreamPlayer.new()
	player.stream = source
	player.bus = "Master"
	player.volume_db = _sfx_volume_db(stream_name)
	player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func set_heartbeat_active(active: bool) -> void:
	pass


func stop_music() -> void:
	bgm_player.stop()
	current_bgm_key = ""


func _play_bgm(track_key: String, stream: AudioStream, volume_db: float) -> void:
	if stream == null:
		return
	if current_bgm_key == track_key and bgm_player.playing:
		return

	current_bgm_key = track_key
	bgm_player.volume_db = volume_db
	bgm_player.stream = _duplicate_looped_stream(stream)
	bgm_player.play()


func _duplicate_looped_stream(stream: AudioStream) -> AudioStream:
	var duplicate_stream := stream.duplicate(true)
	if duplicate_stream is AudioStreamMP3:
		duplicate_stream.loop = true
	return duplicate_stream


func _load_mp3_stream(path: String) -> AudioStreamMP3:
	if path.is_empty():
		return null
	if stream_cache.has(path):
		return stream_cache[path]

	var bytes := FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(path))
	if bytes.is_empty():
		return null

	var stream := AudioStreamMP3.new()
	stream.data = bytes
	stream_cache[path] = stream
	return stream


func _sfx_volume_db(stream_name: String) -> float:
	match stream_name:
		"card_add":
			return -9.0
		"card_remove":
			return -12.0
		"confirm":
			return -11.0
		"resolve":
			return -8.0
		"result":
			return -10.0
	return -12.0
