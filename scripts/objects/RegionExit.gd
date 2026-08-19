## RegionExit.gd
## 지역 이동 트리거 (걸어서 접근 시 자동 전환 또는 확인 후 전환)
extends Area2D

@export var target_region: String = ""
@export var spawn_point: String = "default"
@export var requires_confirmation: bool = false

var _player_inside = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# CollisionShape2D 없으면 자동 생성
	if get_child_count() == 0 or not (get_child(0) is CollisionShape2D):
		var sh = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(16, 32)
		sh.shape = rect
		add_child(sh)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = true
	if not requires_confirmation:
		_try_travel()
	else:
		# 잠긴 지역이면 힌트만 표시
		if target_region not in GameState.unlocked_region_ids:
			_show_locked_hint()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func _try_travel() -> void:
	if target_region in GameState.unlocked_region_ids:
		SceneTransitionManager.travel_to(target_region, spawn_point)
	else:
		_show_locked_hint()

func _show_locked_hint() -> void:
	# 지역이 잠겨 있어도 갈 수 없다는 메시지를 표시하지 않음
	# 그냥 통과 불가 (환경으로만 암시)
	pass
