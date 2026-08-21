## CollectibleItem.gd
## 수집 가능한 아이템 오브젝트
extends Node2D

@export var item_id: String = ""
@export var map_cell: Vector2i = Vector2i.ZERO

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var glow: Node2D = $Glow if has_node("Glow") else null
@onready var interaction_area: Area2D = $InteractionArea if has_node("InteractionArea") else null

var _hint_node: Label = null

func _ready() -> void:
	add_to_group("interactable")
	z_index = 10
	if GameState.has_item(item_id):
		queue_free()
		return
	# Sprite2D 없으면 자동 생성
	if not sprite:
		var s = Sprite2D.new()
		s.name = "Sprite2D"
		add_child(s)
		sprite = s
	sprite.texture = _create_item_texture()
	# InteractionArea 설정 보장
	var area = get_node_or_null("InteractionArea") as Area2D
	if not area:
		area = Area2D.new()
		area.name = "InteractionArea"
		add_child(area)
	area.collision_layer = 4
	area.collision_mask = 0
	var sh = area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not sh:
		sh = CollisionShape2D.new()
		sh.name = "CollisionShape2D"
		area.add_child(sh)
	if not sh.shape:
		var circ = CircleShape2D.new()
		circ.radius = 24.0
		sh.shape = circ

	# 머리 위 아이템 이름 + [E] 라벨 추가 (눈에 확 띄는 밝은 노란색 패널)
	var display_name = InventoryManager.get_display_name(item_id)
	if display_name.is_empty():
		display_name = "아이템"

	_hint_node = Label.new()
	_hint_node.text = "[ %s ]" % display_name
	_hint_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_node.position = Vector2(-40, -26)
	_hint_node.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4, 1.0))
	_hint_node.add_theme_color_override("font_shadow_color", Color(0.1, 0.1, 0.1, 0.9))
	_hint_node.add_theme_font_size_override("font_size", 10)
	add_child(_hint_node)

	# 지도에 아이템 아이콘 등록
	if map_cell != Vector2i.ZERO:
		MapDiscoveryManager.add_icon(map_cell, "item")

func _process(delta: float) -> void:
	if _collected:
		return
	# 위아래로 살짝 떠 있는 효과
	_bob_timer += delta
	if sprite:
		sprite.position.y = sin(_bob_timer * 2.5) * 3.0
	if _hint_node:
		_hint_node.position.y = -26.0 + sin(_bob_timer * 2.5) * 3.0

	# 근접 시 자동 줍기 (반경 32px)
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		if global_position.distance_to(player.global_position) <= 32.0:
			on_interact()

func on_interact() -> void:
	if _collected:
		return
	_collected = true
	GameState.collect_item(item_id)
	_show_pickup_notification()
	_play_pickup_effect()
	if map_cell != Vector2i.ZERO:
		MapDiscoveryManager.remove_icon(map_cell)
	# 음표 단서 확인 및 음표 등장
	var item_data = InventoryManager.get_item_data(item_id)
	var linked_note: String = item_data.get("linked_note_id", "")
	if not linked_note.is_empty():
		_reveal_linked_note(linked_note)
	# 자동 저장
	SaveManager.auto_save()
	# 오브젝트 제거 (애니메이션 후)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _show_pickup_notification() -> void:
	var name_ = InventoryManager.get_display_name(item_id)
	var desc = InventoryManager.get_description(item_id)
	# NotificationUI에 전달
	var ui = get_tree().get_first_node_in_group("notification_ui")
	if ui and ui.has_method("show_item_pickup"):
		ui.show_item_pickup(name_, desc)

func _play_pickup_effect() -> void:
	MusicManager.play_sfx_beep(523.25, 0.15)  # C5

func _reveal_linked_note(note_id: String) -> void:
	# 주변에서 작은 소리가 들리고 음표가 나타남
	await get_tree().create_timer(1.2).timeout
	# 부모 씬에서 해당 음표 오브젝트 활성화
	var note_node = get_tree().get_first_node_in_group("note_" + note_id)
	if note_node:
		note_node.visible = true
		note_node.set_meta("revealed", true)
	else:
		# 음표를 즉시 수집 (단순 모드)
		if not GameState.has_note(note_id):
			GameState.collect_note(note_id)

## 20×20 크기의 선명하고 화려한 픽셀아트 생성
func _create_item_texture() -> ImageTexture:
	var img = Image.create(20, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	# 뒤쪽 반짝이는 황금빛 후광 오라
	var glow_c = Color(1.0, 0.9, 0.4, 0.25)
	for y in range(20):
		for x in range(20):
			var dist = Vector2(x - 9.5, y - 9.5).length()
			if dist <= 9.0:
				img.set_pixel(x, y, glow_c)

	match item_id:
		"warm_tea":
			# 따뜻한 찻잔 (김 모락모락)
			var cup = Color(0.95, 0.90, 0.80)
			var tea = Color(0.80, 0.45, 0.20)
			var steam = Color(1.0, 1.0, 1.0, 0.6)
			# 찻잔 몸체
			for y in range(9, 16):
				for x in range(5, 15):
					img.set_pixel(x, y, cup)
			# 차 내용물
			for x in range(6, 14):
				img.set_pixel(x, 10, tea)
			# 손잡이
			for y in range(10, 14):
				img.set_pixel(15, y, cup)
			# 김 모락모락
			img.set_pixel(8, 6, steam)
			img.set_pixel(7, 4, steam)
			img.set_pixel(11, 5, steam)
			img.set_pixel(12, 3, steam)

		"small_flower":
			# 분홍빛 활짝 핀 꽃송이
			var petal = Color(1.0, 0.55, 0.75)
			var center = Color(1.0, 0.90, 0.30)
			var stem = Color(0.40, 0.80, 0.35)
			# 줄기 & 잎
			for y in range(12, 17):
				img.set_pixel(10, y, stem)
			img.set_pixel(9, 14, stem)
			img.set_pixel(11, 13, stem)
			# 꽃잎 4방향
			for y in range(5, 12):
				for x in range(7, 14):
					img.set_pixel(x, y, petal)
			# 꽃 중심
			img.set_pixel(10, 8, center)
			img.set_pixel(10, 9, center)

		"old_photo":
			# 오래된 액자 사진
			var frame = Color(0.60, 0.45, 0.30)
			var photo_bg = Color(0.90, 0.85, 0.70)
			var figure = Color(0.35, 0.30, 0.25)
			for y in range(4, 16):
				for x in range(4, 16):
					img.set_pixel(x, y, frame)
			for y in range(6, 14):
				for x in range(6, 14):
					img.set_pixel(x, y, photo_bg)
			img.set_pixel(10, 8, figure)
			for x in range(9, 12):
				img.set_pixel(x, 11, figure)

		"short_letter":
			# 접힌 편지 봉투
			var env = Color(0.95, 0.92, 0.82)
			var seal = Color(0.85, 0.30, 0.30)
			for y in range(6, 15):
				for x in range(4, 16):
					img.set_pixel(x, y, env)
			img.set_pixel(10, 10, seal)

		"clean_water":
			# 푸른 물방울 보틀
			var glass = Color(0.85, 0.95, 1.0, 0.8)
			var water = Color(0.35, 0.70, 0.95)
			for y in range(5, 16):
				for x in range(6, 14):
					img.set_pixel(x, y, water)
			img.set_pixel(10, 3, glass)
			img.set_pixel(10, 4, glass)

		"new_pencil":
			# 노란 연필
			var yellow = Color(0.95, 0.80, 0.20)
			var lead = Color(0.20, 0.20, 0.20)
			for i in range(10):
				img.set_pixel(5 + i, 15 - i, yellow)
				img.set_pixel(6 + i, 15 - i, yellow)
			img.set_pixel(4, 16, lead)

		"small_sprout":
			# 파릇파릇 새싹
			var green = Color(0.45, 0.85, 0.35)
			var soil = Color(0.50, 0.35, 0.20)
			for x in range(6, 14):
				img.set_pixel(x, 15, soil)
			for y in range(8, 15):
				img.set_pixel(10, y, green)
			img.set_pixel(8, 8, green)
			img.set_pixel(7, 7, green)
			img.set_pixel(12, 8, green)
			img.set_pixel(13, 7, green)

		"candle":
			# 촛불
			var wax = Color(0.90, 0.85, 0.75)
			var flame = Color(1.0, 0.65, 0.20)
			for y in range(8, 16):
				for x in range(8, 13):
					img.set_pixel(x, y, wax)
			img.set_pixel(10, 5, flame)
			img.set_pixel(10, 4, Color(1.0, 0.95, 0.4))

		_:
			# 기본 빛나는 보석
			var gem = Color(0.85, 0.75, 0.30)
			for y in range(4, 16):
				for x in range(4, 16):
					if abs(x - 9.5) + abs(y - 9.5) <= 6.0:
						img.set_pixel(x, y, gem)

	return ImageTexture.create_from_image(img)
