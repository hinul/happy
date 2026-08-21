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

	# 머리 위 [E] 힌트 라벨 추가
	_hint_node = Label.new()
	_hint_node.text = "[E]"
	_hint_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_node.position = Vector2(-15, -20)
	_hint_node.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6, 0.9))
	_hint_node.add_theme_font_size_override("font_size", 9)
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
		_hint_node.position.y = -20.0 + sin(_bob_timer * 2.5) * 3.0

	# 근접 시 자동 줍기 (반경 22px)
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		if global_position.distance_to(player.global_position) <= 24.0:
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

func _create_item_texture() -> ImageTexture:
	# 아이템별 픽셀 아이콘 (12×12)
	var img = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var color = _get_item_color()
	# 기본 다이아몬드 형태
	for y in range(12):
		for x in range(12):
			var cx = abs(x - 5.5)
			var cy = abs(y - 5.5)
			if cx + cy <= 5.0:
				img.set_pixel(x, y, color)
	# 테두리
	for y in range(12):
		for x in range(12):
			var cx = abs(x - 5.5)
			var cy = abs(y - 5.5)
			if abs(cx + cy - 5.0) < 0.8:
				img.set_pixel(x, y, color.lightened(0.3))
	return ImageTexture.create_from_image(img)

func _get_item_color() -> Color:
	match item_id:
		"warm_tea":        return Color(0.8, 0.6, 0.3)
		"small_flower":    return Color(0.8, 0.5, 0.7)
		"old_photo":       return Color(0.7, 0.65, 0.55)
		"short_letter":    return Color(0.9, 0.85, 0.7)
		"clean_water":     return Color(0.5, 0.7, 0.85)
		"new_pencil":      return Color(0.9, 0.8, 0.3)
		"small_sprout":    return Color(0.5, 0.75, 0.4)
		"candle":          return Color(0.95, 0.85, 0.4)
		"laughter_bottle": return Color(0.7, 0.8, 0.9)
		_:                 return Color(0.7, 0.7, 0.7)
