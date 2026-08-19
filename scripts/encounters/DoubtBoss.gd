## DoubtBoss.gd
## 최종 보스 「의심」 씬 스크립트
## 주인공과 똑같이 생긴 검은 그림자, 이동을 따라 함
extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var interaction_area: Area2D = $InteractionArea if has_node("InteractionArea") else null

var _phase: int = 0
var _player_ref: Node2D = null
var _follow_timer: float = 0.0
var _follow_delay: float = 0.4  # 플레이어보다 늦게 따라옴

# 플레이어 위치 기록
var _player_positions: Array[Vector2] = []
const RECORD_INTERVAL := 0.05

func _ready() -> void:
	_phase = GameState.boss_state
	if sprite:
		sprite.sprite_frames = _create_shadow_frames()
		sprite.play("idle")
	_player_ref = get_tree().get_first_node_in_group("player")
	if _phase >= 5:
		# 이미 완료된 보스 — 작은 그림자로 따라다님
		scale = Vector2(0.3, 0.3)
		modulate.a = 0.45

func _process(delta: float) -> void:
	if not _player_ref:
		return
	# 플레이어 위치 기록
	_follow_timer += delta
	if _follow_timer >= RECORD_INTERVAL:
		_follow_timer = 0.0
		_player_positions.append(_player_ref.global_position)
		# 최대 40개 유지 (2초 지연)
		if _player_positions.size() > 40:
			_player_positions.pop_front()

	# 늦은 간격으로 플레이어 위치 추적
	if _player_positions.size() > 0:
		var target := _player_positions[0]
		global_position = global_position.lerp(target, delta * 2.0)

	# 스프라이트 방향
	if _player_ref.velocity.x < -1.0 and sprite:
		sprite.flip_h = true
	elif _player_ref.velocity.x > 1.0 and sprite:
		sprite.flip_h = false

func on_interact() -> void:
	if _phase >= 5:
		DialogueManager.start_lines(["..."], "의심")
		return
	_start_phase_dialogue()

func _start_phase_dialogue() -> void:
	var lines := _get_phase_lines()
	DialogueManager.start_lines(lines, "의심")
	DialogueManager.dialogue_end.connect(_on_phase_done, CONNECT_ONE_SHOT)

func _on_phase_done() -> void:
	_phase += 1
	GameState.boss_state = _phase
	if _phase >= 4:
		_finish()
		return
	# 크기 축소
	var new_scale := 1.0 - float(_phase) * 0.18
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(new_scale, new_scale), 1.5)
	# 다음 단계 자동 시작 (잠시 후)
	var t := get_tree().create_timer(2.0)
	t.timeout.connect(_start_phase_dialogue)

func _finish() -> void:
	GameState.boss_state = 5
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.3, 0.3), 2.0)
	tween.parallel().tween_property(self, "modulate:a", 0.45, 2.0)
	DialogueManager.start_lines(["그래도 또 나타날 거야."], "의심")
	# 주인공은 대답하지 않고 걸어간다 (입력 해제)
	DialogueManager.dialogue_end.connect(func():
		GameState.unlock_input()
		SaveManager.auto_save()
	, CONNECT_ONE_SHOT)

func _get_phase_lines() -> Array[String]:
	var f := FileAccess.open("res://data/dialogues.json", FileAccess.READ)
	if not f:
		return ["..."]
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		f.close()
		return ["..."]
	f.close()
	var boss_data: Dictionary = json.data.get("doubt_boss", {})
	var phases: Array = boss_data.get("phase_dialogues", [])
	for phase_data in phases:
		if phase_data.get("phase", -1) == (_phase + 1):
			var result: Array[String] = []
			for line in phase_data.get("lines", []):
				result.append(str(line))
			return result
	return ["..."]

func _create_shadow_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 4.0)
	for i in range(4):
		var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		var alpha := 0.65 + float(i % 2) * 0.1
		# 주인공과 같은 실루엣
		for y in range(2, 20):
			for x in range(4, 12):
				img.set_pixel(x, y, Color(0.1, 0.1, 0.15, alpha))
		# 눈: 약하게 빛나는 파란빛
		img.set_pixel(6, 5, Color(0.6, 0.6, 1.0, 0.4))
		img.set_pixel(9, 5, Color(0.6, 0.6, 1.0, 0.4))
		# 다리
		for y in range(20, 24):
			img.set_pixel(5, y, Color(0.08, 0.08, 0.12, alpha))
			img.set_pixel(10, y, Color(0.08, 0.08, 0.12, alpha))
		frames.add_frame("idle", ImageTexture.create_from_image(img))
	return frames
