## MusicNote.gd
## 수집 가능한 음표 오브젝트
## 아이템 조사 후 주변에 작은 소리와 함께 나타남
extends Node2D

@export var note_id: String = ""
@export var map_cell: Vector2i = Vector2i.ZERO

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var interaction_area: Area2D = $InteractionArea if has_node("InteractionArea") else null

var _collected = false
var _revealed = false
var _float_timer = 0.0

func _ready() -> void:
	if GameState.has_note(note_id):
		queue_free()
		return
	# 처음엔 숨겨져 있음 (아이템 수집 후 reveal)
	visible = false
	# 스프라이트 텍스처 생성
	if sprite:
		sprite.texture = _create_note_texture()
	# 상호작용 영역 자동 생성
	if not has_node("InteractionArea"):
		var area = Area2D.new()
		area.name = "InteractionArea"
		area.collision_layer = 4
		area.collision_mask = 0
		var sh = CollisionShape2D.new()
		var circ = CircleShape2D.new()
		circ.radius = 12.0
		sh.shape = circ
		area.add_child(sh)
		add_child(area)
	if map_cell != Vector2i.ZERO:
		MapDiscoveryManager.add_icon(map_cell, "note")

func _process(delta: float) -> void:
	if not _revealed or _collected:
		return
	# 떠다니는 효과
	_float_timer += delta
	if sprite:
		sprite.position.y = sin(_float_timer * 3.0) * 3.0
		sprite.rotation = sin(_float_timer * 1.5) * 0.1

func reveal() -> void:
	_revealed = true
	visible = true
	# 등장 효과
	scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.4)
	# 음 재생
	var index = _get_note_index()
	MusicManager.play_note_pickup(index)

func on_interact() -> void:
	if _collected or not _revealed:
		return
	_collected = true
	GameState.collect_note(note_id)
	if map_cell != Vector2i.ZERO:
		MapDiscoveryManager.remove_icon(map_cell)
	_play_collect_effect()
	SaveManager.auto_save()
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func _play_collect_effect() -> void:
	var index = _get_note_index()
	MusicManager.play_note_pickup(index)
	# ScoreUI 업데이트 신호는 GameState.note_collected 신호로 처리됨

func _get_note_index() -> int:
	var ids = ["note_01","note_02","note_03","note_04","note_05",
				"note_06","note_07","note_08","note_09"]
	return ids.find(note_id)

func _create_note_texture() -> ImageTexture:
	var img = Image.create(10, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var c = Color(0.95, 0.92, 0.6, 1.0)
	# 음표 머리 (타원)
	for y in range(8, 12):
		for x in range(1, 7):
			img.set_pixel(x, y, c)
	# 음표 기둥
	for y in range(0, 9):
		img.set_pixel(6, y, c)
	# 음표 깃발
	img.set_pixel(7, 1, c)
	img.set_pixel(8, 2, c)
	img.set_pixel(7, 3, c)
	return ImageTexture.create_from_image(img)

