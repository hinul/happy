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

# 절차적 배경 레이어
var _procedural_background: Node2D = null

# ─────────────────────────────────────────────
# 초기화
# ─────────────────────────────────────────────
func _ready() -> void:
	_setup_region()
	WorldStateManager.register_region(self)
	if not region_id.is_empty():
		GameState.discover_region(region_id)
	_create_procedural_environment()
	apply_progress_stage(GameState.get_progress_stage())
	if region_ambience and MusicManager._audio_enabled:
		region_ambience.play()

func _setup_region() -> void:
	pass  # 각 지역 서브클래스에서 오버라이드

# ─────────────────────────────────────────────
# 절차적 2D 맵 배경 생성 (TileMap 미배치 시에도 시각적 맵 제공)
# ─────────────────────────────────────────────
func _create_procedural_environment() -> void:
	# Ground 노드 확인 및 절차적 그리기 추가
	var ground = get_node_or_null("Ground")
	if ground and ground.get_child_count() == 0:
		_procedural_background = ProceduralMapDraw.new()
		_procedural_background.region_id = region_id
		ground.add_child(_procedural_background)

# ─────────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────────

## 진행 단계에 따른 지역 환경 변화 (서브클래스에서 구현)
func apply_progress_stage(stage: int) -> void:
	_apply_lighting(stage)
	_apply_decorations(stage)
	if _procedural_background and _procedural_background.has_method("set_stage"):
		_procedural_background.set_stage(stage)

## 스폰 포인트 반환
func get_spawn_point(point_name: String = "default") -> Vector2:
	return spawn_points.get(point_name, spawn_points.get("default", Vector2(320, 200)))

# ─────────────────────────────────────────────
# 내부: 공통 변화 처리
# ─────────────────────────────────────────────

## 조명 변화 (CanvasModulate 색상)
## 초반(stage 0)도 맵이 선명하게 보이도록 기본 명도 보장
func _apply_lighting(stage: int) -> void:
	if not canvas_modulate:
		return
	var target_color = _get_stage_color(stage)
	var tween = create_tween()
	tween.tween_property(canvas_modulate, "color", target_color, 1.5)

func _get_stage_color(stage: int) -> Color:
	# 단계별 색상 (시작부터 충분히 밝게 유지)
	var colors: Array[Color] = [
		Color(0.82, 0.82, 0.86, 1.0),  # 0: 밝은 서늘한 톤
		Color(0.84, 0.84, 0.88, 1.0),  # 1
		Color(0.86, 0.86, 0.88, 1.0),  # 2
		Color(0.88, 0.88, 0.88, 1.0),  # 3
		Color(0.90, 0.89, 0.88, 1.0),  # 4
		Color(0.92, 0.91, 0.89, 1.0),  # 5
		Color(0.94, 0.93, 0.90, 1.0),  # 6
		Color(0.96, 0.94, 0.91, 1.0),  # 7
		Color(0.98, 0.96, 0.92, 1.0),  # 8
		Color(1.00, 0.98, 0.93, 1.0),  # 9: 따뜻한 햇빛
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

# ─────────────────────────────────────────────
# 절차적 맵 드로잉 헬퍼 클래스
# ─────────────────────────────────────────────
class ProceduralMapDraw extends Node2D:
	var region_id: String = "ash_forest"
	var current_stage: int = 0

	func set_stage(st: int) -> void:
		current_stage = st
		queue_redraw()

	func _draw() -> void:
		var width = 640
		var height = 360

		match region_id:
			"ash_forest":
				_draw_ash_forest(width, height)
			"small_village":
				_draw_small_village(width, height)
			"rain_lake":
				_draw_rain_lake(width, height)
			"memory_garden":
				_draw_memory_garden(width, height)
			"old_theater":
				_draw_old_theater(width, height)
			"dawn_hill":
				_draw_dawn_hill(width, height)
			_:
				_draw_ash_forest(width, height)

	## draw_ellipse 대체: 폴리공 없이 정수 점 샘플링으로 타원 그리기
	func _draw_ellipse_approx(center: Vector2, rx: float, ry: float, color: Color, filled: bool = true) -> void:
		var pts = PackedVector2Array()
		var steps = 36
		for i in range(steps + 1):
			var angle = (float(i) / float(steps)) * TAU
			pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
		if filled:
			draw_colored_polygon(pts, color)
		else:
			draw_polyline(pts, color, 1.5)

	func _draw_ash_forest(w: int, h: int) -> void:
		# 바닥 풀밭 (잿빛 → 짙은 녹색)
		var base_color = Color(0.28, 0.32, 0.28).lerp(Color(0.32, 0.45, 0.30), float(current_stage) / 9.0)
		draw_rect(Rect2(0, 0, w, h), base_color)

		# 흙바닥 구역 (Ground highlight)
		var mid_color = base_color.lightened(0.08)
		draw_rect(Rect2(60, 155, w - 120, 55), mid_color)

		# 흙바닥 길 (중앙 도로)
		var path_color = Color(0.42, 0.38, 0.30)
		draw_rect(Rect2(40, 178, w - 80, 46), path_color)
		draw_rect(Rect2(138, 158, 64, 86), path_color)
		draw_rect(Rect2(438, 158, 64, 86), path_color)

		# 주변 나무
		var tree_color = Color(0.16, 0.22, 0.16).lerp(Color(0.20, 0.36, 0.22), float(current_stage) / 9.0)
		var trunk_color = Color(0.32, 0.26, 0.20)

		for x in range(30, w, 50):
			# 상단 나무
			draw_rect(Rect2(x, 42, 12, 42), trunk_color)
			draw_circle(Vector2(x + 6, 42), 24.0, tree_color)
			# 하단 나무
			draw_rect(Rect2(x + 20, 268, 12, 42), trunk_color)
			draw_circle(Vector2(x + 26, 268), 24.0, tree_color)

	func _draw_small_village(w: int, h: int) -> void:
		# 마을 자갈길 바닥
		var base_color = Color(0.30, 0.28, 0.26)
		draw_rect(Rect2(0, 0, w, h), base_color)

		# 마을 중앙 광장
		var plaza_color = Color(0.40, 0.38, 0.35)
		_draw_ellipse_approx(Vector2(w / 2, h / 2), 90.0, 90.0, plaza_color)
		_draw_ellipse_approx(Vector2(w / 2, h / 2), 86.0, 86.0, base_color)

		# 집 실루엣 3채
		var house_color = Color(0.20, 0.18, 0.18)
		draw_rect(Rect2(70, 80, 80, 60), house_color)
		draw_rect(Rect2(250, 60, 100, 70), house_color)
		draw_rect(Rect2(470, 80, 90, 60), house_color)

	func _draw_rain_lake(w: int, h: int) -> void:
		# 호숫가 잔디 바닥
		var shore_color = Color(0.22, 0.26, 0.24)
		draw_rect(Rect2(0, 0, w, h), shore_color)

		# 중앙 거대 호수
		var lake_color = Color(0.20, 0.28, 0.38).lerp(Color(0.25, 0.42, 0.55), float(current_stage) / 9.0)
		_draw_ellipse_approx(Vector2(w / 2, h / 2 + 10), 200.0, 90.0, lake_color)

		# 젖은 나무다리
		var bridge_color = Color(0.38, 0.28, 0.20)
		draw_rect(Rect2(120, h / 2 - 10, 200, 24), bridge_color)

	func _draw_memory_garden(w: int, h: int) -> void:
		# 정원 잔디 바닥
		var grass_color = Color(0.24, 0.30, 0.24)
		draw_rect(Rect2(0, 0, w, h), grass_color)

		# 정원 산책로 (십자형)
		var path_color = Color(0.42, 0.38, 0.32)
		draw_rect(Rect2(0, 160, w, 40), path_color)
		draw_rect(Rect2(300, 0, 40, h), path_color)

		# 화단 영역 4개
		var bed_color = Color(0.32, 0.22, 0.18)
		draw_rect(Rect2(80, 50, 140, 80), bed_color)
		draw_rect(Rect2(420, 50, 140, 80), bed_color)
		draw_rect(Rect2(80, 230, 140, 80), bed_color)
		draw_rect(Rect2(420, 230, 140, 80), bed_color)

	func _draw_old_theater(w: int, h: int) -> void:
		# 극장 마루 바닥
		var floor_color = Color(0.18, 0.14, 0.12)
		draw_rect(Rect2(0, 0, w, h), floor_color)

		# 무대 영역
		var stage_color = Color(0.28, 0.20, 0.15)
		draw_rect(Rect2(100, 40, 440, 140), stage_color)

		# 객석 의자 열
		var seat_color = Color(0.25, 0.12, 0.12)
		for y in range(220, 330, 30):
			for x in range(120, 520, 40):
				draw_rect(Rect2(x, y, 24, 16), seat_color)

	func _draw_dawn_hill(w: int, h: int) -> void:
		# 언덕 잔디 (새벽빛)
		var hill_color = Color(0.22, 0.22, 0.28).lerp(Color(0.35, 0.38, 0.32), float(current_stage) / 9.0)
		draw_rect(Rect2(0, 0, w, h), hill_color)

		# 언덕 곡선 길
		var path_color = Color(0.38, 0.35, 0.30)
		var points = PackedVector2Array([
			Vector2(50, 320), Vector2(180, 260),
			Vector2(320, 200), Vector2(450, 140), Vector2(560, 100)
		])
		for i in range(points.size() - 1):
			draw_line(points[i], points[i+1], path_color, 28.0)

		# 정상의 작은 제단/음표 자리
		draw_circle(Vector2(560, 100), 20.0, Color(0.45, 0.42, 0.38))
