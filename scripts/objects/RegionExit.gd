## RegionExit.gd
## 지역 이동 트리거 (걸어서 접근 시 자동 전환 또는 확인 후 전환)
extends Area2D

@export var target_region: String = ""
@export var spawn_point: String = "default"
@export var requires_confirmation: bool = false

var _player_inside = false
var _hint_label: Label = null

func _ready() -> void:
	add_to_group("region_exit")
	collision_layer = 0
	collision_mask = 2  # 플레이어 감지

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# CollisionShape2D 설정 보장
	var sh = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not sh:
		sh = CollisionShape2D.new()
		sh.name = "CollisionShape2D"
		add_child(sh)
	if not sh.shape:
		var rect = RectangleShape2D.new()
		rect.size = Vector2(40, 80)
		sh.shape = rect

	# 출구 안내 라벨
	_hint_label = Label.new()
	_hint_label.text = "➡️ 마을로 가는 길"
	_hint_label.position = Vector2(-40, -35)
	_hint_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 0.9))
	_hint_label.add_theme_font_size_override("font_size", 9)
	add_child(_hint_label)

func _process(_delta: float) -> void:
	# 플레이어가 영역 안에 있으면 지속적으로 체크
	if _player_inside and not SceneTransitionManager._is_transitioning:
		_try_travel()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = true
	_try_travel()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func _try_travel() -> void:
	# 잿빛 숲 -> 마을 이동 시 필요한 음표 체크 (마을은 음표 2개 필요)
	var stage = GameState.get_progress_stage()
	WorldStateManager.check_region_unlocks(stage)

	if target_region in GameState.unlocked_region_ids:
		SceneTransitionManager.travel_to(target_region, spawn_point)
	else:
		_show_locked_hint()

func _show_locked_hint() -> void:
	var needed = 2
	match target_region:
		"small_village": needed = 2
		"rain_lake":     needed = 4
		"memory_garden": needed = 5
		"old_theater":   needed = 6
		"dawn_hill":     needed = 8

	var current = GameState.collected_note_ids.size()
	var notif = get_tree().get_first_node_in_group("notification_ui")
	if notif and notif.has_method("show_item_pickup"):
		notif.show_item_pickup(
			"안개가 자욱하다",
			"음표를 %d개 모아야 지나갈 수 있다. (현재 %d/%d)" % [needed, current, needed]
		)
