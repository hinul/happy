## SceneTransitionManager.gd
## 지역 간 이동: 페이드아웃 → 씬 교체 → 위치 복원 → 페이드인
extends Node

signal transition_started(region_id: String)
signal transition_finished(region_id: String)

const FADE_DURATION := 0.4

# 지역 ID → 씬 경로 매핑
const REGION_SCENES: Dictionary = {
	"ash_forest":    "res://scenes/regions/AshForest.tscn",
	"small_village": "res://scenes/regions/SmallVillage.tscn",
	"rain_lake":     "res://scenes/regions/RainLake.tscn",
	"memory_garden": "res://scenes/regions/MemoryGarden.tscn",
	"old_theater":   "res://scenes/regions/OldTheater.tscn",
	"dawn_hill":     "res://scenes/regions/DawnHill.tscn",
}

var _fade_layer: CanvasLayer = null
var _fade_rect: ColorRect = null
var _is_transitioning: bool = false
var _main_game: Node = null

func _ready() -> void:
	# 페이드 레이어 생성
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.05, 0.05, 0.08, 1.0)
	_fade_rect.modulate.a = 0.0
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.visible = false
	_fade_layer.add_child(_fade_rect)
	add_child(_fade_layer)

## MainGame 씬 참조 등록
func register_main_game(node: Node) -> void:
	_main_game = node

## 지역 이동 요청
func travel_to(region_id: String, spawn_point: String = "default") -> void:
	if _is_transitioning:
		return
	if region_id not in REGION_SCENES:
		push_error("[SceneTransitionManager] 알 수 없는 지역: " + region_id)
		return
	if region_id not in GameState.unlocked_region_ids:
		push_warning("[SceneTransitionManager] 잠긴 지역 접근 시도: " + region_id)
		return

	_is_transitioning = true
	GameState.is_transitioning = true
	GameState.lock_input()
	transition_started.emit(region_id)

	_fade_out(func():
		_load_region(region_id, spawn_point)
	)

## 씬 전환 없이 현재 지역에서 위치만 이동
func teleport_player(pos: Vector2) -> void:
	if _main_game and _main_game.has_method("set_player_position"):
		_main_game.set_player_position(pos)

# ─────────────────────────────────────────────
# 내부
# ─────────────────────────────────────────────

func _load_region(region_id: String, spawn_point: String) -> void:
	GameState.current_region = region_id
	var scene_path := REGION_SCENES[region_id]

	if not ResourceLoader.exists(scene_path):
		push_error("[SceneTransitionManager] 씬 파일 없음: " + scene_path)
		_finish_transition(region_id)
		return

	if _main_game and _main_game.has_method("load_region"):
		_main_game.load_region(region_id, spawn_point)
	else:
		# 폴백: 씬 직접 전환
		get_tree().change_scene_to_file(scene_path)

	GameState.discover_region(region_id)
	_fade_in(func(): _finish_transition(region_id))

func _finish_transition(region_id: String) -> void:
	_is_transitioning = false
	GameState.is_transitioning = false
	GameState.unlock_input()
	transition_finished.emit(region_id)

func _fade_out(callback: Callable) -> void:
	_fade_rect.visible = true
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_callback(callback)

func _fade_in(callback: Callable) -> void:
	_fade_rect.visible = true
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(func():
		_fade_rect.visible = false
		if callback.is_valid():
			callback.call()
	)

## 화면 즉시 검게 (게임 시작 연출용)
func set_fade(alpha: float) -> void:
	_fade_rect.modulate.a = alpha
	_fade_rect.visible = (alpha > 0.0)

## 페이드인 애니메이션
func fade_in(duration: float = FADE_DURATION, callback: Callable = Callable()) -> void:
	_fade_rect.visible = true
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, duration)
	tween.tween_callback(func():
		_fade_rect.visible = false
		if callback.is_valid():
			callback.call()
	)

## 페이드아웃 애니메이션
func fade_out(duration: float = FADE_DURATION, callback: Callable = Callable()) -> void:
	_fade_rect.visible = true
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, duration)
	if callback.is_valid():
		tween.tween_callback(callback)
