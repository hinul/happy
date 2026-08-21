## InteractableObject.gd
## 조사 가능한 일반 오브젝트 (악보, 표지판, 가구 등)
## 절차적 픽셀아트 스프라이트 + 충돌 영역 자동 생성 + 부유 효과
extends Node2D

@export var object_id: String = ""
@export var one_time_only: bool = false
@export var unlocks_score_ui: bool = false

var _interacted = false
var _bob_timer: float = 0.0
var _sprite: Sprite2D = null
var _area: Area2D = null

func _ready() -> void:
	add_to_group("interactable")
	if one_time_only and GameState.is_event_done("obj_" + object_id):
		_interacted = true

	_build_sprite()
	_build_interaction_area()

func _build_sprite() -> void:
	# 이미 Sprite2D 자식이 있으면 텍스처만 갱신
	_sprite = get_node_or_null("Sprite2D")
	if not _sprite:
		_sprite = Sprite2D.new()
		_sprite.name = "Sprite2D"
		add_child(_sprite)
	_sprite.texture = _create_object_texture()

func _build_interaction_area() -> void:
	_area = get_node_or_null("InteractionArea")
	if not _area:
		_area = Area2D.new()
		_area.name = "InteractionArea"
		add_child(_area)
	_area.collision_layer = 4
	_area.collision_mask = 0
	var shape_node = _area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not shape_node:
		shape_node = CollisionShape2D.new()
		shape_node.name = "CollisionShape2D"
		_area.add_child(shape_node)
	if not shape_node.shape:
		var shape = CircleShape2D.new()
		shape.radius = 18.0
		shape_node.shape = shape

func _process(delta: float) -> void:
	if _interacted:
		return
	# 부유 효과
	_bob_timer += delta
	if _sprite:
		_sprite.position.y = sin(_bob_timer * 1.8) * 2.5

# ─────────────────────────────────────────────
# 상호작용
# ─────────────────────────────────────────────

func on_interact() -> void:
	if one_time_only and _interacted:
		return
	DialogueManager.start_interactable_dialogue(object_id)
	DialogueManager.dialogue_end.connect(_on_dialogue_done, CONNECT_ONE_SHOT)

func _on_dialogue_done() -> void:
	if one_time_only:
		_interacted = true
		GameState.complete_event("obj_" + object_id)
	if unlocks_score_ui:
		GameState.score_ui_unlocked = true
		var ui = get_tree().get_first_node_in_group("score_ui")
		if ui:
			if ui.has_method("animate_icon"):
				ui.animate_icon()
			ui.show()
			if ui.has_method("_rebuild"):
				ui._rebuild()

# ─────────────────────────────────────────────
# 절차적 텍스처 생성
# ─────────────────────────────────────────────

func _create_object_texture() -> ImageTexture:
	match object_id:
		"old_score":
			return _make_score_texture()
		"forest_path_sign", "village_sign", "lake_sign", _:
			return _make_sign_texture()

## 낡은 악보 픽셀아트 (16×18)
func _make_score_texture() -> ImageTexture:
	var img = Image.create(16, 18, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	# 악보 배경 (낡은 크림색)
	var paper = Color(0.85, 0.80, 0.65)
	var edge = Color(0.55, 0.48, 0.35)
	var ink  = Color(0.18, 0.14, 0.12)
	# 종이 본체
	for y in range(2, 17):
		for x in range(1, 15):
			img.set_pixel(x, y, paper)
	# 테두리
	for x in range(1, 15):
		img.set_pixel(x, 2, edge)
		img.set_pixel(x, 16, edge)
	for y in range(2, 17):
		img.set_pixel(1, y, edge)
		img.set_pixel(14, y, edge)
	# 악보 선 4개
	for y in [5, 7, 9, 11]:
		for x in range(3, 13):
			img.set_pixel(x, y, ink)
	# 음표 하나
	for px in [[6, 6], [6, 7], [7, 8], [8, 8], [8, 7], [8, 6], [8, 5]]:
		img.set_pixel(px[0], px[1], ink)
	# 상단 꼬임 (구겨진 느낌)
	img.set_pixel(2, 2, Color.TRANSPARENT)
	img.set_pixel(13, 2, Color.TRANSPARENT)
	return ImageTexture.create_from_image(img)

## 표지판 픽셀아트 (14×18)
func _make_sign_texture() -> ImageTexture:
	var img = Image.create(14, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var wood = Color(0.50, 0.36, 0.22)
	var dark = Color(0.30, 0.20, 0.12)
	var text_c = Color(0.90, 0.85, 0.70)
	# 기둥
	for y in range(12, 20):
		for x in range(5, 9):
			img.set_pixel(x, y, dark)
	# 표지판 판
	for y in range(1, 13):
		for x in range(0, 14):
			img.set_pixel(x, y, wood)
	# 테두리
	for x in range(0, 14):
		img.set_pixel(x, 1, dark)
		img.set_pixel(x, 12, dark)
	for y in range(1, 13):
		img.set_pixel(0, y, dark)
		img.set_pixel(13, y, dark)
	# 문자 대신 직선 세 줄 (텍스트 모사)
	for x in range(3, 11):
		img.set_pixel(x, 4, text_c)
		img.set_pixel(x, 7, text_c)
		img.set_pixel(x, 10, text_c)
	return ImageTexture.create_from_image(img)
