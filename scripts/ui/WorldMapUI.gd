## WorldMapUI.gd
## 전체 지도 (M 키)
## 발견한 지역과 이동 경로 표시, 아이콘은 발견 후만 표시
extends Control

const REGION_POSITIONS: Dictionary = {
	"ash_forest":    Vector2(100, 200),
	"small_village": Vector2(250, 200),
	"rain_lake":     Vector2(400, 150),
	"memory_garden": Vector2(400, 260),
	"old_theater":   Vector2(550, 200),
	"dawn_hill":     Vector2(680, 150),
}

const REGION_NAMES: Dictionary = {
	"ash_forest":    "잿빛 숲",
	"small_village": "작은 마을",
	"rain_lake":     "비의 호수",
	"memory_garden": "기억의 정원",
	"old_theater":   "오래된 극장",
	"dawn_hill":     "새벽의 언덕",
}

# 지역 연결선
const REGION_CONNECTIONS: Array[Array] = [
	["ash_forest", "small_village"],
	["small_village", "rain_lake"],
	["small_village", "memory_garden"],
	["rain_lake", "old_theater"],
	["memory_garden", "old_theater"],
	["old_theater", "dawn_hill"],
]

func _ready() -> void:
	MapDiscoveryManager.register_worldmap(self)
	MapDiscoveryManager.worldmap_updated.connect(queue_redraw)
	GameState.game_loaded.connect(queue_redraw)
	hide()

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("open_map"):
		if visible:
			hide()
		elif not GameState.is_dialogue_active:
			show()
			refresh()
	if visible and event.is_action_just_pressed("pause_menu"):
		hide()

func refresh() -> void:
	queue_redraw()

func _draw() -> void:
	# 배경
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.08, 0.12, 0.95))

	var discovered := GameState.discovered_region_ids

	# 연결선 (발견한 지역 간)
	for conn in REGION_CONNECTIONS:
		var a: String = conn[0]
		var b: String = conn[1]
		if a in discovered and b in discovered:
			draw_line(REGION_POSITIONS[a], REGION_POSITIONS[b],
					  Color(0.4, 0.4, 0.45, 0.7), 2.0)

	# 지역 노드
	for region_id in REGION_POSITIONS:
		var pos: Vector2 = REGION_POSITIONS[region_id]
		if region_id not in discovered:
			continue
		var is_current := (region_id == GameState.current_region)
		var node_color := Color(0.8, 0.85, 0.9) if is_current else Color(0.5, 0.55, 0.6)
		draw_circle(pos, 8.0, node_color)
		if is_current:
			draw_circle(pos, 10.0, Color(1.0, 1.0, 0.8, 0.5), false, 1.5)

		# 지역명 (텍스트는 Label로 처리 — draw에서는 간단한 점만)
	# 현재 위치 표시
	if GameState.current_region in REGION_POSITIONS:
		var pos: Vector2 = REGION_POSITIONS[GameState.current_region]
		draw_circle(pos, 5.0, Color(1.0, 1.0, 0.8, 1.0))

	# 지도 테두리
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.5, 0.5, 0.55, 0.8), false, 1.5)
