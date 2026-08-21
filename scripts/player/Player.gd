## Player.gd
## CharacterBody2D 기반 탑다운 플레이어
## - 방향별 걷기 애니메이션 (상/하/좌/우)
## - 대화/전환 중 입력 잠금
## - 초반: 작은 보폭, 후반: 자세가 펴진 것처럼 보이게
## - 달리기는 엔딩에서만 자연스럽게 등장
extends CharacterBody2D

# ─────────────────────────────────────────────
# 노드 참조
# ─────────────────────────────────────────────
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var footstep_player: AudioStreamPlayer2D = $FootstepPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# ─────────────────────────────────────────────
# 이동 설정
# ─────────────────────────────────────────────
const BASE_SPEED = 80.0
const LATE_SPEED_BONUS = 8.0   # 후반 진행 시 약간 빠른 느낌

var _speed = BASE_SPEED
var _direction = Vector2.ZERO
var _last_direction = Vector2.DOWN
var _is_running = false   # 엔딩 연출 전용

# 발걸음 타이머
var _footstep_timer = 0.0
const FOOTSTEP_INTERVAL = 0.35

# ─────────────────────────────────────────────
# 독백 시스템 (진행 단계별)
# ─────────────────────────────────────────────
const MONOLOGUE_EARLY: Array[String] = [
	"굳이 해야 하나.",
	"돌아갈 길도 모르겠네.",
]
const MONOLOGUE_MIDDLE: Array[String] = [
	"일단 가보자.",
	"조금 더 둘러볼까.",
]
const MONOLOGUE_LATE: Array[String] = [
	"한번 해볼까.",
	"저쪽에도 길이 있었나?",
]

var _monologue_timer = 0.0
const MONOLOGUE_INTERVAL = 45.0
var _last_monologue = ""

# ─────────────────────────────────────────────
# 초기화
# ─────────────────────────────────────────────
func _ready() -> void:
	add_to_group("player")
	_setup_animations()
	GameState.progress_stage_changed.connect(_on_stage_changed)
	GameState.ending_started.connect(_on_ending_started)
	_update_speed()
	# InteractionArea 설정 보장
	if interaction_area:
		interaction_area.collision_layer = 0
		interaction_area.collision_mask = 4  # layer 4 감지
		interaction_area.monitoring = true
		interaction_area.monitorable = false
		var sh = interaction_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if sh and not sh.shape:
			var circ = CircleShape2D.new()
			circ.radius = 24.0
			sh.shape = circ

func _setup_animations() -> void:
	if not sprite:
		return
	sprite.sprite_frames = _create_sprite_frames()
	sprite.animation = "idle_down"
	sprite.play("idle_down")   # 게임 시작 직후 캐릭터가 즉시 표시되도록

## 절차적으로 스프라이트 프레임 생성 (픽셀아트 스타일)
func _create_sprite_frames() -> SpriteFrames:
	var frames = SpriteFrames.new()
	# 애니메이션 목록 초기화 (기본 'default' 제거)
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var anims = ["walk_down", "walk_up", "walk_left", "walk_right",
				  "idle_down", "idle_up", "idle_left", "idle_right",
				  "dance", "run_right"]
	for anim in anims:
		frames.add_animation(anim)
		frames.set_animation_loop(anim, true)
		frames.set_animation_speed(anim, 6.0 if anim.begins_with("walk") else 8.0)

	# 각 애니메이션에 프레임 추가
	_add_walk_frames(frames, "walk_down",  Color(0.6, 0.5, 0.4), Vector2i(0, 0))
	_add_walk_frames(frames, "walk_up",    Color(0.5, 0.4, 0.35), Vector2i(0, 1))
	_add_walk_frames(frames, "walk_left",  Color(0.55, 0.45, 0.38), Vector2i(0, 2))
	_add_walk_frames(frames, "walk_right", Color(0.55, 0.45, 0.38), Vector2i(0, 3))
	_add_idle_frames(frames, "idle_down",  Color(0.6, 0.5, 0.4))
	_add_idle_frames(frames, "idle_up",    Color(0.5, 0.4, 0.35))
	_add_idle_frames(frames, "idle_left",  Color(0.55, 0.45, 0.38))
	_add_idle_frames(frames, "idle_right", Color(0.55, 0.45, 0.38))
	_add_dance_frames(frames)
	_add_run_frames(frames)
	return frames

func _add_walk_frames(frames: SpriteFrames, anim: String, color: Color, _dir: Vector2i) -> void:
	for i in range(4):
		var tex = _create_player_texture(color, i, false)
		frames.add_frame(anim, tex)

func _add_idle_frames(frames: SpriteFrames, anim: String, color: Color) -> void:
	var tex = _create_player_texture(color, 0, false)
	frames.add_frame(anim, tex)
	frames.add_frame(anim, tex)

func _add_dance_frames(frames: SpriteFrames) -> void:
	frames.set_animation_speed("dance", 8.0)
	for i in range(8):
		var tex = _create_player_texture(Color(0.65, 0.55, 0.45), i % 4, i >= 4)
		frames.add_frame("dance", tex)

func _add_run_frames(frames: SpriteFrames) -> void:
	frames.set_animation_speed("run_right", 10.0)
	for i in range(4):
		var tex = _create_player_texture(Color(0.6, 0.5, 0.4), i, false)
		frames.add_frame("run_right", tex)

## 16×24 픽셀 캐릭터 텍스처 생성
func _create_player_texture(skin_color: Color, frame_idx: int, is_jump: bool) -> ImageTexture:
	var img = Image.create(16, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	# 몸통 (8×10)
	var body_color = skin_color.darkened(0.1)
	for y in range(10, 20):
		for x in range(4, 12):
			img.set_pixel(x, y, body_color)

	# 머리 (8×8)
	for y in range(2, 10):
		for x in range(4, 12):
			img.set_pixel(x, y, skin_color)

	# 눈
	img.set_pixel(6, 5, Color(0.1, 0.1, 0.1))
	img.set_pixel(9, 5, Color(0.1, 0.1, 0.1))

	# 다리 애니메이션
	var leg_offset = [0, 1, 0, -1][frame_idx % 4]
	if is_jump:
		leg_offset = -2
	# 왼쪽 다리
	for y in range(20, 24):
		img.set_pixel(5, y + leg_offset, body_color.darkened(0.2))
	# 오른쪽 다리
	for y in range(20, 24):
		img.set_pixel(10, y - leg_offset, body_color.darkened(0.2))

	return ImageTexture.create_from_image(img)

# ─────────────────────────────────────────────
# 이동 처리
# ─────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	# input_locked 중에도 interact 키는 처리 (대화 진행을 위해)
	if Input.is_action_just_pressed("interact"):
		_try_interact()

	if GameState.input_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# 입력 수집
	var input_vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_direction = input_vec.normalized()

	if _direction != Vector2.ZERO:
		_last_direction = _direction
		velocity = _direction * _speed
		_update_walk_animation()
		_handle_footstep(delta)
	else:
		velocity = Vector2.ZERO
		_update_idle_animation()
		_footstep_timer = 0.0

	move_and_slide()

	# 지도 탐험 기록 (매 프레임 처리하지 않음)
	if Engine.get_physics_frames() % 30 == 0:
		MapDiscoveryManager.visit_position(global_position)

	# 독백 타이머
	_monologue_timer += delta
	if _monologue_timer >= MONOLOGUE_INTERVAL:
		_monologue_timer = 0.0
		_try_monologue()

func _handle_footstep(delta: float) -> void:
	_footstep_timer += delta
	if _footstep_timer >= FOOTSTEP_INTERVAL:
		_footstep_timer = 0.0
		_play_footstep()

func _play_footstep() -> void:
	MusicManager.play_sfx_beep(120.0 + randf() * 20.0, 0.05)

# ─────────────────────────────────────────────
# 애니메이션
# ─────────────────────────────────────────────
func _update_walk_animation() -> void:
	if not sprite:
		return
	var anim = "walk_"
	if _is_running:
		anim = "run_right"
	elif abs(_direction.x) > abs(_direction.y):
		anim += "right" if _direction.x > 0 else "left"
	elif _direction.y > 0:
		anim += "down"
	else:
		anim += "up"

	if sprite.animation != anim:
		sprite.play(anim)
	elif not sprite.is_playing():
		sprite.play()

func _update_idle_animation() -> void:
	if not sprite:
		return
	var anim = "idle_"
	if abs(_last_direction.x) > abs(_last_direction.y):
		anim += "right" if _last_direction.x > 0 else "left"
	elif _last_direction.y > 0:
		anim += "down"
	else:
		anim += "up"

	if sprite.animation != anim or sprite.is_playing():
		sprite.play(anim)

func play_dance() -> void:
	if sprite:
		sprite.play("dance")
	_is_running = false

# ─────────────────────────────────────────────
# 조사 / 상호작용
# ─────────────────────────────────────────────
func _try_interact() -> void:
	if DialogueManager.is_active():
		DialogueManager.advance()
		return

	# 1차: Overlapping areas 탐색
	if interaction_area:
		var areas = interaction_area.get_overlapping_areas()
		for area in areas:
			var parent = area.get_parent()
			if parent and parent.has_method("on_interact"):
				parent.on_interact()
				return
		var bodies = interaction_area.get_overlapping_bodies()
		for body in bodies:
			if body != self and body.has_method("on_interact"):
				body.on_interact()
				return

	# 2차 Fallback: 반경 80픽셀 내의 가장 가까운 interactable 오브젝트 탐색
	var interactables = get_tree().get_nodes_in_group("interactable")
	var closest_target: Node = null
	var closest_dist: float = 80.0
	for node in interactables:
		if node is Node2D and is_instance_valid(node) and node.visible:
			var d = global_position.distance_to(node.global_position)
			if d < closest_dist:
				if node.has_method("on_interact"):
					closest_dist = d
					closest_target = node
				elif node.get_parent() and node.get_parent().has_method("on_interact"):
					closest_dist = d
					closest_target = node.get_parent()
	if closest_target and closest_target.has_method("on_interact"):
		closest_target.on_interact()

# ─────────────────────────────────────────────
# 독백
# ─────────────────────────────────────────────
func _try_monologue() -> void:
	if DialogueManager.is_active():
		return
	var stage = GameState.get_progress_stage()
	var pool: Array[String]
	if stage <= 2:
		pool = MONOLOGUE_EARLY
	elif stage <= 5:
		pool = MONOLOGUE_MIDDLE
	else:
		pool = MONOLOGUE_LATE

	var line = pool[randi() % pool.size()]
	if line == _last_monologue and pool.size() > 1:
		line = pool[(pool.find(line) + 1) % pool.size()]
	_last_monologue = line
	DialogueManager.start_lines([line], "")

# ─────────────────────────────────────────────
# 진행 단계 반응
# ─────────────────────────────────────────────
func _on_stage_changed(stage: int) -> void:
	_update_speed()

func _update_speed() -> void:
	var stage = GameState.get_progress_stage()
	# 진행할수록 조금 빠른 느낌 (UI에 수치 노출 없음)
	_speed = BASE_SPEED + float(mini(stage, 5)) * (LATE_SPEED_BONUS / 5.0)

func _on_ending_started() -> void:
	_is_running = true
	_speed = BASE_SPEED * 1.4
	if sprite:
		sprite.play("run_right")
