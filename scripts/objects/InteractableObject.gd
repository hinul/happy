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
		"traveler_note_01", "gardener_diary", "bottle_letter":
			return _make_paper_texture()
		"forest_bench", "fishing_chair":
			return _make_bench_texture()
		"stone_pile":
			return _make_stone_texture()
		"whispering_tree":
			return _make_tree_relic_texture()
		"rusty_mailbox":
			return _make_mailbox_texture()
		"village_streetlamp":
			return _make_lamp_texture()
		"broken_keyboard":
			return _make_piano_texture()
		"theater_poster":
			return _make_poster_texture()
		"garden_fountain":
			return _make_fountain_texture()
		"forest_path_sign", "village_sign", "lake_sign", _:
			return _make_sign_texture()

## 낡은 쪽지/일기/편지 픽셀아트 (14×16)
func _make_paper_texture() -> ImageTexture:
	var img = Image.create(14, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var paper = Color(0.92, 0.88, 0.76)
	var fold  = Color(0.75, 0.70, 0.58)
	var ink   = Color(0.35, 0.30, 0.25)
	for y in range(2, 14):
		for x in range(2, 12):
			img.set_pixel(x, y, paper)
	# 글씨 선
	for y in [5, 8, 11]:
		for x in range(4, 10):
			img.set_pixel(x, y, ink)
	# 테두리 및 접힌 모서리
	for x in range(2, 12):
		img.set_pixel(x, 2, fold)
		img.set_pixel(x, 13, fold)
	for y in range(2, 14):
		img.set_pixel(2, y, fold)
		img.set_pixel(11, y, fold)
	return ImageTexture.create_from_image(img)

## 나무 벤치 (20×14)
func _make_bench_texture() -> ImageTexture:
	var img = Image.create(20, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var wood = Color(0.55, 0.38, 0.24)
	var dark = Color(0.35, 0.22, 0.14)
	for x in range(2, 18):
		img.set_pixel(x, 4, wood)
		img.set_pixel(x, 7, wood)
	for x in [3, 4, 15, 16]:
		for y in range(7, 13):
			img.set_pixel(x, y, dark)
	return ImageTexture.create_from_image(img)

## 소원 돌탑 (14×18)
func _make_stone_texture() -> ImageTexture:
	var img = Image.create(14, 18, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var stone = Color(0.58, 0.60, 0.62)
	var dark = Color(0.38, 0.40, 0.42)
	# 하단 돌 (넓음)
	for x in range(2, 12):
		for y in range(12, 17):
			img.set_pixel(x, y, stone)
	# 중단 돌
	for x in range(3, 11):
		for y in range(7, 12):
			img.set_pixel(x, y, stone.lightened(0.1))
	# 상단 돌 (작음)
	for x in range(5, 9):
		for y in range(2, 7):
			img.set_pixel(x, y, stone.lightened(0.2))
	return ImageTexture.create_from_image(img)

## 속삭이는 나무 성물 (16×20)
func _make_tree_relic_texture() -> ImageTexture:
	var img = Image.create(16, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var trunk = Color(0.38, 0.28, 0.20)
	var glow_c = Color(0.60, 0.85, 0.65)
	for y in range(4, 19):
		for x in range(5, 11):
			img.set_pixel(x, y, trunk)
	# 중앙 빛나는 문양
	img.set_pixel(8, 10, glow_c)
	img.set_pixel(7, 11, glow_c)
	img.set_pixel(9, 11, glow_c)
	img.set_pixel(8, 12, glow_c)
	return ImageTexture.create_from_image(img)

## 빨간 우체통 (14×18)
func _make_mailbox_texture() -> ImageTexture:
	var img = Image.create(14, 18, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var red = Color(0.85, 0.30, 0.25)
	var dark = Color(0.25, 0.25, 0.25)
	for x in range(6, 8):
		for y in range(10, 18):
			img.set_pixel(x, y, dark)
	for x in range(3, 11):
		for y in range(2, 10):
			img.set_pixel(x, y, red)
	# 투입구
	for x in range(5, 9):
		img.set_pixel(x, 4, dark)
	return ImageTexture.create_from_image(img)

## 따뜻한 가로등 (12×22)
func _make_lamp_texture() -> ImageTexture:
	var img = Image.create(12, 22, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var pole = Color(0.30, 0.30, 0.35)
	var light = Color(1.0, 0.92, 0.50)
	for y in range(6, 22):
		img.set_pixel(5, y, pole)
		img.set_pixel(6, y, pole)
	# 등불
	for x in range(3, 9):
		for y in range(2, 6):
			img.set_pixel(x, y, light)
	return ImageTexture.create_from_image(img)

## 피아노 건반 (18×14)
func _make_piano_texture() -> ImageTexture:
	var img = Image.create(18, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var white = Color(0.95, 0.95, 0.95)
	var black = Color(0.15, 0.15, 0.15)
	for x in range(1, 17):
		for y in range(4, 12):
			img.set_pixel(x, y, white)
	# 검은 건반
	for bx in [3, 5, 9, 11, 13]:
		for by in range(4, 8):
			img.set_pixel(bx, by, black)
	return ImageTexture.create_from_image(img)

## 공연 포스터 (14×18)
func _make_poster_texture() -> ImageTexture:
	var img = Image.create(14, 18, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var bg = Color(0.85, 0.78, 0.60)
	var red = Color(0.75, 0.25, 0.20)
	for x in range(1, 13):
		for y in range(1, 17):
			img.set_pixel(x, y, bg)
	for x in range(3, 11):
		for y in range(3, 6):
			img.set_pixel(x, y, red)
	return ImageTexture.create_from_image(img)

## 작은 분수대 (20×18)
func _make_fountain_texture() -> ImageTexture:
	var img = Image.create(20, 18, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var stone = Color(0.60, 0.62, 0.65)
	var water = Color(0.40, 0.70, 0.90)
	for x in range(2, 18):
		for y in range(10, 17):
			img.set_pixel(x, y, stone)
	for x in range(4, 16):
		for y in range(10, 13):
			img.set_pixel(x, y, water)
	# 물줄기
	for y in range(3, 10):
		img.set_pixel(9, y, water)
		img.set_pixel(10, y, water)
	return ImageTexture.create_from_image(img)

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
