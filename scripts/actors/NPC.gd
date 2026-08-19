## NPC.gd
## NPC 기반 스크립트 (대화, 상태 변화, 지도 등록)
extends Node2D

@export var npc_id: String = ""
@export var initial_face_direction: String = "down"  # down/up/left/right

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var interaction_area: Area2D = $InteractionArea if has_node("InteractionArea") else null
@onready var exclamation: Node2D = $Exclamation if has_node("Exclamation") else null

var _dialogue_stage: int = 0

func _ready() -> void:
	if sprite:
		sprite.sprite_frames = _create_npc_frames()
		sprite.play("idle_" + initial_face_direction)

	GameState.progress_stage_changed.connect(_on_stage_changed)
	_refresh_stage()

	# 지도 아이콘 등록
	if not npc_id.is_empty():
		var cell := Vector2i(int(global_position.x / 32), int(global_position.y / 32))
		MapDiscoveryManager.add_icon(cell, "npc")

func on_interact() -> void:
	if DialogueManager.is_active():
		return
	_refresh_stage()
	DialogueManager.start_npc_dialogue(npc_id)
	GameState.set_npc_state(npc_id, "met", true)

func _on_stage_changed(_stage: int) -> void:
	_refresh_stage()

func _refresh_stage() -> void:
	_dialogue_stage = WorldStateManager.get_npc_dialogue_stage(npc_id)
	# 마지막 단계 NPC는 느낌표 숨김
	if exclamation:
		exclamation.visible = (_dialogue_stage < 3)

## 절차적 NPC 스프라이트 (16×24, 색상으로 구별)
func _create_npc_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	var color := _get_npc_color()
	for dir in ["down", "up", "left", "right"]:
		var anim := "idle_" + dir
		frames.add_animation(anim)
		frames.set_animation_loop(anim, true)
		frames.set_animation_speed(anim, 4.0)
		for i in range(2):
			frames.add_frame(anim, _make_npc_texture(color, i))
		var walk := "walk_" + dir
		frames.add_animation(walk)
		frames.set_animation_loop(walk, true)
		frames.set_animation_speed(walk, 6.0)
		for i in range(4):
			frames.add_frame(walk, _make_npc_texture(color, i))
	# 댄스 애니메이션
	frames.add_animation("dance")
	frames.set_animation_loop("dance", true)
	frames.set_animation_speed("dance", 8.0)
	for i in range(8):
		frames.add_frame("dance", _make_npc_texture(color, i % 4))
	return frames

func _get_npc_color() -> Color:
	match npc_id:
		"forest_wanderer":  return Color(0.4, 0.5, 0.45)
		"village_elder":    return Color(0.55, 0.45, 0.35)
		"village_kid":      return Color(0.5, 0.55, 0.6)
		"lake_fisherman":   return Color(0.35, 0.45, 0.55)
		"garden_keeper":    return Color(0.45, 0.55, 0.40)
		"theater_musician": return Color(0.50, 0.40, 0.55)
		_: return Color(0.5, 0.5, 0.5)

func _make_npc_texture(color: Color, frame_idx: int) -> ImageTexture:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	# 몸통
	for y in range(10, 20):
		for x in range(4, 12):
			img.set_pixel(x, y, color.darkened(0.1))
	# 머리
	for y in range(2, 10):
		for x in range(4, 12):
			img.set_pixel(x, y, color)
	# 눈
	img.set_pixel(6, 5, Color(0.1, 0.1, 0.1))
	img.set_pixel(9, 5, Color(0.1, 0.1, 0.1))
	# 다리
	var leg_offset := [0, 1, 0, -1][frame_idx % 4]
	for y in range(20, 24):
		var py := clampi(y + leg_offset, 0, 23)
		img.set_pixel(5, py, color.darkened(0.2))
		py = clampi(y - leg_offset, 0, 23)
		img.set_pixel(10, py, color.darkened(0.2))
	return ImageTexture.create_from_image(img)

func play_dance(dance_type: String = "side_step") -> void:
	if sprite:
		sprite.play("dance")
