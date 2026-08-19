## BaseRegion.gd
## 모든 지역 씬의 공통 기반 클래스
## 각 지역 스크립트는 이 클래스를 상속받아 apply_progress_stage()를 구현
extends Node2D
class_name BaseRegion

# ─────────────────────────────────────────────
# 노드 참조 (각 지역 씬에서 가져옴)
# ─────────────────────────────────────────────
@onready var canvas_modulate: CanvasModulate = $CanvasModulate if has_node("CanvasModulate") else null
@onready var region_ambience: AudioStreamPlayer = $RegionAmbience if has_node("RegionAmbience") else null
@onready var changeable_decorations: Node2D = $ChangeableDecorations if has_node("ChangeableDecorations") else null

# 지역 ID (각 지역 스크립트에서 설정)
var region_id: String = ""

# 스폰 포인트 목록
var spawn_points: Dictionary = {"default": Vector2(320, 200)}

# ─────────────────────────────────────────────
# 초기화
# ─────────────────────────────────────────────
func _ready() -> void:
	WorldStateManager.register_region(self)
	GameState.discover_region(region_id)
	_setup_region()
	apply_progress_stage(GameState.get_progress_stage())
	# 지역 환경음 시작
	if region_ambience and MusicManager._audio_enabled:
		region_ambience.play()

func _setup_region() -> void:
	pass  # 각 지역 서브클래스에서 오버라이드

# ─────────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────────

## 진행 단계에 따른 지역 환경 변화 (서브클래스에서 구현)
func apply_progress_stage(stage: int) -> void:
	_apply_lighting(stage)
	_apply_decorations(stage)

## 스폰 포인트 반환
func get_spawn_point(point_name: String = "default") -> Vector2:
	return spawn_points.get(point_name, spawn_points.get("default", Vector2(320, 200)))

# ─────────────────────────────────────────────
# 내부: 공통 변화 처리
# ─────────────────────────────────────────────

## 조명 변화 (CanvasModulate 색상)
## stage 0: 짙은 회색 / stage 9: 따뜻한 색조
func _apply_lighting(stage: int) -> void:
	if not canvas_modulate:
		return
	var target_color := _get_stage_color(stage)
	var tween := create_tween()
	tween.tween_property(canvas_modulate, "color", target_color, 1.5)

func _get_stage_color(stage: int) -> Color:
	# 단계별 색상 (어두운 회색 → 따뜻한 자연광)
	var colors: Array[Color] = [
		Color(0.25, 0.25, 0.28, 1.0),  # 0: 짙은 회색
		Color(0.30, 0.30, 0.33, 1.0),  # 1
		Color(0.38, 0.38, 0.42, 1.0),  # 2: 약간 푸른빛
		Color(0.42, 0.42, 0.46, 1.0),  # 3
		Color(0.50, 0.50, 0.52, 1.0),  # 4
		Color(0.60, 0.58, 0.55, 1.0),  # 5: 중성 톤
		Color(0.70, 0.68, 0.62, 1.0),  # 6
		Color(0.80, 0.76, 0.68, 1.0),  # 7: 따뜻한 색조
		Color(0.88, 0.84, 0.76, 1.0),  # 8: 새벽빛
		Color(1.00, 0.96, 0.88, 1.0),  # 9: 자연광
	]
	return colors[clampi(stage, 0, colors.size() - 1)]

## 장식 오브젝트 표시/숨김
func _apply_decorations(stage: int) -> void:
	if not changeable_decorations:
		return
	for child in changeable_decorations.get_children():
		var min_stage: int = child.get_meta("min_stage", 0)
		child.visible = (stage >= min_stage)
		if child.has_method("on_stage_changed"):
			child.on_stage_changed(stage)
