## MapDiscoveryManager.gd
## 플레이어가 걸어 다닌 지도 셀 기록 및 미니맵/전체지도 갱신
## 발견하지 않은 지역의 구조를 미리 보여주지 않음
extends Node

signal minimap_updated
signal worldmap_updated
signal icon_changed(cell: Vector2i, icon_type: String, visible: bool)

# 지도 셀 크기 (픽셀)
const CELL_SIZE = 32

# 미니맵 UI 참조
var _minimap_ui: Node = null
var _worldmap_ui: Node = null

# 방문한 셀 (GameState.visited_map_cells와 동기화)
# 아이콘 목록: cell → {type, active}
var _icons: Dictionary = {}

func _ready() -> void:
	GameState.region_discovered.connect(_on_region_discovered)
	GameState.item_collected.connect(_on_item_collected)
	GameState.note_collected.connect(_on_note_collected)
	GameState.npc_event_completed.connect(_on_npc_event_done)
	GameState.game_loaded.connect(_rebuild_from_state)

# ─────────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────────

## UI 등록
func register_minimap(ui: Node) -> void:
	_minimap_ui = ui

func register_worldmap(ui: Node) -> void:
	_worldmap_ui = ui

## 플레이어 현재 월드 위치로 셀 방문 처리
func visit_position(world_pos: Vector2) -> void:
	var cell = Vector2i(
		int(world_pos.x / CELL_SIZE),
		int(world_pos.y / CELL_SIZE)
	)
	if cell not in GameState.visited_map_cells:
		GameState.visit_map_cell(cell)
		minimap_updated.emit()
		if _minimap_ui and _minimap_ui.has_method("mark_cell"):
			_minimap_ui.mark_cell(cell)

## 지도 아이콘 추가
## type: "note"(♪), "item"(★), "npc"(!), "hidden"(?), "player"(●)
func add_icon(cell: Vector2i, type: String) -> void:
	_icons[cell] = {"type": type, "active": true}
	icon_changed.emit(cell, type, true)

## 지도 아이콘 제거 (아이템 획득, 이벤트 완료 후)
func remove_icon(cell: Vector2i) -> void:
	if cell in _icons:
		_icons[cell]["active"] = false
		icon_changed.emit(cell, _icons[cell]["type"], false)

## 현재 방문 셀 목록 반환
func get_visited_cells() -> Array[Vector2i]:
	return GameState.visited_map_cells.duplicate()

## 활성 아이콘 목록 반환
func get_active_icons() -> Dictionary:
	var result = {}
	for cell in _icons:
		if _icons[cell]["active"]:
			result[cell] = _icons[cell]
	return result

# ─────────────────────────────────────────────
# 내부
# ─────────────────────────────────────────────

func _on_region_discovered(region_id: String) -> void:
	worldmap_updated.emit()
	if _worldmap_ui and _worldmap_ui.has_method("refresh"):
		_worldmap_ui.refresh()

func _on_item_collected(item_id: String) -> void:
	# 획득한 아이템 아이콘 제거
	for cell in _icons:
		var icon = _icons[cell]
		if icon.get("type") == "item" and icon.get("item_id") == item_id:
			remove_icon(cell)
			break

func _on_note_collected(note_id: String) -> void:
	for cell in _icons:
		var icon = _icons[cell]
		if icon.get("type") == "note" and icon.get("note_id") == note_id:
			remove_icon(cell)
			break

func _on_npc_event_done(event_id: String) -> void:
	for cell in _icons:
		var icon = _icons[cell]
		if icon.get("type") == "npc" and icon.get("event_id") == event_id:
			remove_icon(cell)
			break

func _rebuild_from_state() -> void:
	# 불러오기 후 아이콘 재구성 (저장 데이터 기반)
	minimap_updated.emit()
	worldmap_updated.emit()
