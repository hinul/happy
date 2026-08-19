## MusicManager.gd
## 배경음악 시스템
## - 진행 단계별 음악 크로스페이드
## - AudioStreamGenerator로 절차적 사운드 생성 (외부 파일 의존 최소화)
## - 웹 환경: 첫 사용자 입력 후에만 재생
extends Node

# ─────────────────────────────────────────────
# 음악 단계 정의
# ─────────────────────────────────────────────
# stage 0: 거의 무음 (낮은 지속음 + 바람)
# stage 1: 단음 하나 추가
# stage 3: 짧은 불완전 멜로디
# stage 5: 반주 + 리듬 추가
# stage 7: 방향이 명확한 멜로디
# stage 8: 완성 직전
# stage 9: 캉캉 전체

const CROSSFADE_DURATION = 2.0
const MASTER_VOLUME_DB = 0.0

# 캉캉 멜로디 음정 (주파수 Hz, 캉캉 주제 기반)
# E4-D4-E4-C4 / E4-D4-B3-G3 패턴
const CANCAN_MELODY: Array[float] = [
	329.63, 293.66, 329.63, 261.63,  # E4 D4 E4 C4
	329.63, 293.66, 246.94, 196.00,  # E4 D4 B3 G3
	329.63, 293.66, 329.63, 261.63,
	293.66, 261.63, 246.94, 196.00
]

# 각 진행 단계에서 추가되는 음정 레이어
const STAGE_NOTES: Dictionary = {
	1: [196.00],                                          # G3 단음
	2: [196.00, 246.94],                                  # G3 B3
	3: [196.00, 246.94, 261.63],                          # +C4
	4: [196.00, 246.94, 261.63, 293.66],                  # +D4
	5: [196.00, 246.94, 261.63, 293.66, 329.63],          # +E4
	6: [196.00, 246.94, 261.63, 293.66, 329.63, 349.23],  # +F4
	7: [196.00, 246.94, 261.63, 293.66, 329.63, 349.23, 392.00],  # +G4
	8: [196.00, 246.94, 261.63, 293.66, 329.63, 349.23, 392.00, 440.00],  # +A4
}

# ─────────────────────────────────────────────
# 노드
# ─────────────────────────────────────────────
var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer

var _current_player: AudioStreamPlayer
var _next_player: AudioStreamPlayer

var _audio_enabled: bool = false
var _current_stage: int = 0
var _is_crossfading: bool = false
var _cancan_playing: bool = false

# 절차적 음악 타이머
var _note_timer: float = 0.0
var _note_interval: float = 2.0
var _melody_index: int = 0
var _tween: Tween

# ─────────────────────────────────────────────
# 초기화
# ─────────────────────────────────────────────
func _ready() -> void:
	_player_a = AudioStreamPlayer.new()
	_player_b = AudioStreamPlayer.new()
	_ambient_player = AudioStreamPlayer.new()
	_sfx_player = AudioStreamPlayer.new()

	_player_a.bus = "Music"
	_player_b.bus = "Music"
	_ambient_player.bus = "Ambient"
	_sfx_player.bus = "SFX"

	add_child(_player_a)
	add_child(_player_b)
	add_child(_ambient_player)
	add_child(_sfx_player)

	_current_player = _player_a
	_next_player = _player_b

	GameState.progress_stage_changed.connect(_on_stage_changed)
	GameState.ending_started.connect(_on_ending_started)

func _process(delta: float) -> void:
	if not _audio_enabled or _cancan_playing:
		return
	_note_timer += delta
	if _note_timer >= _note_interval:
		_note_timer = 0.0
		_play_stage_note()

# ─────────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────────

## 첫 사용자 입력 후 오디오 활성화 (브라우저 자동재생 정책 대응)
func enable_audio() -> void:
	if _audio_enabled:
		return
	_audio_enabled = true
	_apply_volumes()
	_play_ambient()
	_note_timer = 0.0

func set_music_volume(vol: float) -> void:
	GameState.music_volume = vol
	_apply_volumes()

func set_sound_volume(vol: float) -> void:
	GameState.sound_volume = vol
	_apply_volumes()

func play_sfx_beep(freq: float = 440.0, duration: float = 0.1) -> void:
	if not _audio_enabled:
		return
	var stream = _create_tone_stream(freq, duration, 0.3)
	_sfx_player.stream = stream
	_sfx_player.play()

func play_note_pickup(note_index: int) -> void:
	if not _audio_enabled:
		return
	# 캉캉 멜로디의 해당 음 재생
	var freq = CANCAN_MELODY[note_index % CANCAN_MELODY.size()]
	var stream = _create_tone_stream(freq, 0.5, 0.4)
	_sfx_player.stream = stream
	_sfx_player.play()

func play_cancan() -> void:
	if not _audio_enabled:
		return
	_cancan_playing = true
	_stop_all_music()
	# OGG 파일이 있으면 재생, 없으면 절차적 생성
	var ogg_path = "res://audio/bgm/cancan_final.ogg"
	if ResourceLoader.exists(ogg_path):
		var stream = load(ogg_path)
		_current_player.stream = stream
		_current_player.volume_db = _volume_to_db(GameState.music_volume)
		_current_player.play()
	else:
		_play_procedural_cancan()

func stop_music(fade_duration: float = 1.0) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_current_player, "volume_db", -80.0, fade_duration)
	_tween.tween_callback(_current_player.stop)

# ─────────────────────────────────────────────
# 내부: 단계별 음악
# ─────────────────────────────────────────────
func _on_stage_changed(stage: int) -> void:
	_current_stage = stage
	if not _audio_enabled:
		return
	_note_interval = _get_note_interval(stage)

func _get_note_interval(stage: int) -> float:
	match stage:
		0: return 4.0
		1: return 3.5
		2: return 3.0
		3: return 2.5
		4: return 2.0
		5: return 1.8
		6: return 1.5
		7: return 1.2
		8: return 1.0
		_: return 0.8

func _play_stage_note() -> void:
	var stage = _current_stage
	if stage == 0:
		# 낮은 지속음 하나만
		var stream = _create_tone_stream(98.0, 1.5, 0.1)
		_player_a.stream = stream
		_player_a.play()
		return

	var notes: Array[float] = []
	if stage in STAGE_NOTES:
		notes = STAGE_NOTES[stage]
	elif stage >= 9:
		return  # 캉캉 재생 중

	if notes.is_empty():
		return

	# 단계가 높을수록 더 많은 음 동시 재생
	var count = mini(stage, notes.size())
	for i in range(count):
		if i == 0 or stage >= 5:
			var freq = notes[i % notes.size()]
			var vol = 0.15 + (float(i) / float(count)) * 0.1
			var dur = 0.3 + float(stage) * 0.05
			var s = _create_tone_stream(freq, dur, vol)
			if i == 0:
				_player_a.stream = s
				_player_a.play()
			elif i == 1 and stage >= 5:
				_player_b.stream = s
				_player_b.play()

func _play_ambient() -> void:
	# 바람 소리 절차적 생성 (짧은 버퍼로 즉시 생성 후 무한 루프)
	var stream = _create_noise_stream(0.5, 0.05)
	_ambient_player.stream = stream
	_ambient_player.volume_db = _volume_to_db(GameState.sound_volume * 0.3)
	_ambient_player.play()

func _play_procedural_cancan() -> void:
	# 캉캉 멜로디를 절차적으로 순차 재생
	_play_cancan_sequence(0)

func _play_cancan_sequence(index: int) -> void:
	if index >= CANCAN_MELODY.size():
		index = 0  # 루프
	var freq = CANCAN_MELODY[index]
	var stream = _create_tone_stream(freq, 0.22, 0.6)
	_current_player.stream = stream
	_current_player.play()
	var t = get_tree().create_timer(0.24)
	t.timeout.connect(func(): _play_cancan_sequence(index + 1))

func _stop_all_music() -> void:
	_player_a.stop()
	_player_b.stop()
	_ambient_player.stop()

func _on_ending_started() -> void:
	play_cancan()

# ─────────────────────────────────────────────
# 절차적 오디오 생성
# ─────────────────────────────────────────────

## 단순 사인파 톤 생성
func _create_tone_stream(freq: float, duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(num_samples * 2)  # 16-bit mono

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var envelope = 1.0
		# 어택/릴리즈 엔벨로프
		var attack = 0.02
		var release = 0.1
		if t < attack:
			envelope = t / attack
		elif t > duration - release:
			envelope = (duration - t) / release
		var sample = sin(2.0 * PI * freq * t) * volume * envelope
		# 약간의 배음 추가 (2배음)
		sample += sin(2.0 * PI * freq * 2.0 * t) * volume * 0.2 * envelope
		var s16 = int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	return stream

## 노이즈(바람 소리) 생성
func _create_noise_stream(duration: float, volume: float = 0.05) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var prev = 0.0
	for i in range(num_samples):
		# 저역 통과 필터링으로 부드러운 바람 소리
		var raw = rng.randf_range(-1.0, 1.0)
		var filtered = prev * 0.97 + raw * 0.03
		prev = filtered
		var s16 = int(clampf(filtered * volume, -1.0, 1.0) * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples - 1
	return stream

func _apply_volumes() -> void:
	_player_a.volume_db = _volume_to_db(GameState.music_volume)
	_player_b.volume_db = _volume_to_db(GameState.music_volume)
	_ambient_player.volume_db = _volume_to_db(GameState.sound_volume * 0.4)
	_sfx_player.volume_db = _volume_to_db(GameState.sound_volume)

func _volume_to_db(linear: float) -> float:
	if linear <= 0.001:
		return -80.0
	return 20.0 * log(linear) / log(10.0)
