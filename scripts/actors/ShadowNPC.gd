## ShadowNPC.gd
## 그림자 생명체 (부정적인 생각 / 의심 보스 공통 기반)
extends Node2D

@export var thought_id: String = ""
@export var is_doubt_boss: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

var _phase: int = 0
var _is_interacted: bool = false

func _ready() -> void:
	if sprite:
		sprite.sprite_frames = _create_shadow_frames()
		sprite.play("float")
	_refresh_from_state()

func _refresh_from_state() -> void:
	if is_doubt_boss:
		_phase = GameState.boss_state
	elif GameState.is_event_done("thought_done_" + thought_id):
		_is_interacted = true
		scale = Vector2(0.5, 0.5)  # 작아진 상태 유지

func on_interact() -> void:
	if _is_interacted and not is_doubt_boss:
		# 이미 상호작용한 생각 — 다시 옆에 있음
		DialogueManager.start_lines(["..."], "")
		return
	if is_doubt_boss:
		_start_doubt_encounter()
	else:
		_start_thought_encounter()

func _start_thought_encounter() -> void:
	var data: Dictionary = _get_thought_data()
	var lines: Array[String] = []
	for line in data.get("lines", []):
		lines.append(str(line))
	# 부정적인 생각의 대사
	DialogueManager.start_lines(lines, data.get("display_name", ""))
	DialogueManager.dialogue_end.connect(_on_thought_dialogue_done, CONNECT_ONE_SHOT)

func _on_thought_dialogue_done() -> void:
	# 아이템 선택 UI로 이어짐 (InventoryUI에서 처리)
	# 올바른 아이템 사용 시 크기 축소, 그림자로 변환
	_is_interacted = true
	GameState.complete_event("thought_done_" + thought_id)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.45, 0.45), 1.0)
	# 옆으로 이동
	tween.parallel().tween_property(self, "position:x", position.x + 30.0, 1.0)
	SaveManager.auto_save()

func _start_doubt_encounter() -> void:
	var dialogue_data: Dictionary = _get_doubt_dialogue()
	var lines: Array[String] = []
	for line in dialogue_data.get("lines", []):
		lines.append(str(line))
	DialogueManager.start_lines(lines, "의심")
	DialogueManager.dialogue_end.connect(_on_doubt_phase_done, CONNECT_ONE_SHOT)

func _on_doubt_phase_done() -> void:
	_phase += 1
	GameState.boss_state = _phase
	if _phase >= 4:
		_finish_doubt()
	else:
		var tween = create_tween()
		tween.tween_property(self, "scale",
			Vector2(1.0 - float(_phase) * 0.2, 1.0 - float(_phase) * 0.2), 1.5)

func _finish_doubt() -> void:
	# 의심이 작은 그림자가 되어 남음 — 사라지지 않음
	GameState.boss_state = 5
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.3, 0.3), 2.0)
	tween.tween_property(self, "modulate:a", 0.5, 1.0)
	DialogueManager.start_lines(["그래도 또 나타날 거야."], "의심")
	SaveManager.auto_save()

func _get_thought_data() -> Dictionary:
	# dialogues.json에서 로드 (DialogueManager의 캐시 활용)
	return {}  # DialogueManager._dialogue_data.get("negative_thoughts", [])에서 찾음

func _get_doubt_dialogue() -> Dictionary:
	return {}  # DialogueManager._dialogue_data.get("doubt_boss", {}).get(...)

func _create_shadow_frames() -> SpriteFrames:
	var frames = SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("float")
	frames.set_animation_loop("float", true)
	frames.set_animation_speed("float", 4.0)
	for i in range(4):
		frames.add_frame("float", _make_shadow_texture(i))
	return frames

func _make_shadow_texture(frame_idx: int) -> ImageTexture:
	var size = 24 if is_doubt_boss else 16
	var img = Image.create(size, size + 8, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var alpha = 0.7 + float(frame_idx % 2) * 0.1
	var shadow_color = Color(0.1, 0.1, 0.15, alpha)
	# 둥근 그림자 형태
	var cx = size / 2
	var cy = size / 2
	for y in range(size + 8):
		for x in range(size):
			var dx = float(x - cx)
			var dy = float(y - cy)
			if (dx * dx) / float(cx * cx) + (dy * dy) / float(cy * cy) <= 1.0:
				img.set_pixel(x, y, shadow_color)
	# 눈 (약하게)
	if size >= 24:
		img.set_pixel(cx - 3, cy - 2, Color(0.8, 0.8, 1.0, 0.5))
		img.set_pixel(cx + 3, cy - 2, Color(0.8, 0.8, 1.0, 0.5))
	return ImageTexture.create_from_image(img)
