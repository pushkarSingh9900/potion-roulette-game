extends Node

# Procedural Audio Manager for testing without actual assets
@onready var bgm_player = AudioStreamPlayer.new()
@onready var heartbeat_player = AudioStreamPlayer.new()

var playback: AudioStreamGeneratorPlayback
var sample_hz = 44100.0

func _ready():
	add_child(bgm_player)
	bgm_player.volume_db = -10.0
	
	add_child(heartbeat_player)
	heartbeat_player.volume_db = 5.0
	
	# Setup a generic procedural generator for SFX
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = sample_hz
	
func play_sfx(stream_name: String, pitch_variance: float = 0.1):
	var player = AudioStreamPlayer.new()
	add_child(player)
	
	# Procedural sound generation based on type
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_hz
	stream.buffer_length = 0.5 # 0.5 second buffer
	player.stream = stream
	player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	player.play()
	
	var pb = player.get_stream_playback()
	_fill_buffer_procedural(pb, stream_name)
	
	# Cleanup
	await get_tree().create_timer(0.6).timeout
	player.queue_free()

func _fill_buffer_procedural(pb: AudioStreamGeneratorPlayback, type: String):
	var frames_available = pb.get_frames_available()
	var phase = 0.0
	
	for i in range(frames_available):
		var val = 0.0
		var time = float(i) / sample_hz
		
		match type:
			"glass_clink":
				# High click, fast decay
				val = sin(time * 2000.0 * PI * 2.0) * exp(-time * 50.0)
			"flesh_impact":
				# Low thud, fast decay
				val = sin(time * 100.0 * PI * 2.0) * exp(-time * 20.0)
			"ethereal_chime":
				# Medium tone, slow decay
				val = sin(time * 600.0 * PI * 2.0) * exp(-time * 5.0)
			"poison_hiss":
				# White noise with decay
				val = randf_range(-1.0, 1.0) * exp(-time * 10.0)
			"wheel_start":
				# Mechanical click sequence
				val = sin(time * 400.0 * PI * 2.0) * exp(-time * 30.0) * (1.0 if int(time * 10) % 2 == 0 else 0.0)
		
		# Prevent horrific clipping
		val = clamp(val, -1.0, 1.0)
		pb.push_frame(Vector2(val, val))

func set_heartbeat_active(active: bool):
	if active and not heartbeat_player.playing:
		var stream = AudioStreamGenerator.new()
		stream.mix_rate = sample_hz
		stream.buffer_length = 1.0
		heartbeat_player.stream = stream
		heartbeat_player.play()
		
		var pb = heartbeat_player.get_stream_playback()
		# Simple repeating thump
		var frames = pb.get_frames_available()
		for i in range(frames):
			var time = float(i) / sample_hz
			# Thump thump ... wait ... thump thump
			var thump_env = clamp(sin(time * PI * 2.0), 0.0, 1.0) * exp(-fmod(time, 1.0) * 5.0)
			var val = sin(time * 60.0 * PI * 2.0) * thump_env
			pb.push_frame(Vector2(val, val))
			
	elif not active and heartbeat_player.playing:
		heartbeat_player.stop()

func play_bgm():
	pass
