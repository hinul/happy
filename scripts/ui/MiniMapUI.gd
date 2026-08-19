## MiniMapUI.gd
## 미니맵: 플레이어가 지나간 셀만 표시, 발견하지 않은 지역은 완전히 검음
## Control._draw() 기반으로 매 프레임 갱신하지 않고 상태 변화 시만 갱신
extends Control

const CELL_PIXEL = 3   # 미니맵에서 셀 하나의 픽셀 크기
const MAP_SIZE = Vector2i(50, 40)  # 최대 셀 수

# 미니맵 오프셋 (플레이어 기준 중앙)
var _player_cell: Vector2i = Vector2i.ZERO
var _dirty = true

func _ready() -> void:
	MapDiscoveryManager.register_minimap(self)
	MapDiscoveryManager.minimap_updated.connect(queue_redraw)
	GameState.game_loaded.connect(queue_redraw)
	custom_minimum_size = Vector2(MAP_SIZE.x * CELL_PIXEL, MAP_SIZE.y * CELL_PIXEL)

func _draw() -> void:
	# 배경
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.08, 0.8))
	var visited = MapDiscoveryManager.get_visited_cells()
	var icons = MapDiscoveryManager.get_active_icons()

	# 방문한 셀 그리기
	for cell in visited:
		var draw_pos = _cell_to_draw_pos(cell)
		draw_rect(Rect2(draw_pos, Vector2(CELL_PIXEL, CELL_PIXEL)),
				  Color(0.55, 0.55, 0.60, 0.9))

	# 아이콘 그리기
	for cell in icons:
		if cell not in visited:
			continue  # 방문하지 않은 셀의 아이콘은 표시하지 않음
		var draw_pos = _cell_to_draw_pos(cell)
		var icon_type: String = icons[cell]["type"]
		var icon_color = _get_icon_color(icon_type)
		draw_rect(Rect2(draw_pos, Vector2(CELL_PIXEL, CELL_PIXEL)), icon_color)

	# 현재 위치 (항상 표시)
	var player_draw_pos = _cell_to_draw_pos(_player_cell)
	draw_rect(Rect2(player_draw_pos, Vector2(CELL_PIXEL + 1, CELL_PIXEL + 1)),
			  Color(1.0, 1.0, 0.8, 1.0))

	# 미니맵 테두리
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.4, 0.4, 0.45, 0.8), false, 1.0)

func mark_cell(cell: Vector2i) -> void:
	_player_cell = cell
	queue_redraw()

func update_player_cell(cell: Vector2i) -> void:
	_player_cell = cell
	queue_redraw()

func _cell_to_draw_pos(cell: Vector2i) -> Vector2:
	# 플레이어 기준 상대 위치로 변환
	var rel = cell - _player_cell
	var center = Vector2(size) / 2.0
	return center + Vector2(rel) * CELL_PIXEL

func _get_icon_color(icon_type: String) -> Color:
	match icon_type:
		"note":   return Color(0.95, 0.90, 0.4, 1.0)   # 금색 (♪)
		"item":   return Color(0.9, 0.7, 0.3, 1.0)     # 황금 (★)
		"npc":    return Color(0.4, 0.8, 0.6, 1.0)     # 초록 (!)
		"hidden": return Color(0.7, 0.5, 0.8, 1.0)     # 보라 (?)
		_:        return Color(0.8, 0.8, 0.8, 1.0)
