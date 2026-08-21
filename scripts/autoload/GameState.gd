## GameState.gd
## 게임의 전체 상태를 관리하는 Autoload 싱글톤
## 내부 진행 단계(progress_stage)는 UI에 절대로 노출하지 않는다.
extends Node

# ─────────────────────────────────────────────
# 신호 (Signals)
# ─────────────────────────────────────────────
signal item_collected(item_id: String)
signal note_collected(note_id: String)
signal progress_stage_changed(stage: int)
signal region_discovered(region_id: String)
signal npc_event_completed(event_id: String)
signal dialogue_started
signal dialogue_finished
signal save_requested
signal save_completed
signal ending_started
signal new_game_started
signal game_loaded

# ─────────────────────────────────────────────
# 현재 게임 위치
# ─────────────────────────────────────────────
var current_region: String = "ash_forest"
var player_position: Vector2 = Vector2(320, 200)

# ─────────────────────────────────────────────
# 수집 데이터
# ─────────────────────────────────────────────
var collected_item_ids: Array[String] = []
var collected_note_ids: Array[String] = []

# ─────────────────────────────────────────────
# 탐험 데이터
# ─────────────────────────────────────────────
var discovered_region_ids: Array[String] = []
var visited_map_cells: Array[Vector2i] = []
var unlocked_region_ids: Array[String] = ["ash_forest"]

# ─────────────────────────────────────────────
# 이벤트 & NPC 상태
# ─────────────────────────────────────────────
var completed_event_ids: Array[String] = []
var npc_states: Dictionary = {}   # {npc_id: {"met": bool, "event_done": bool}}

# ─────────────────────────────────────────────
# 보스 & 엔딩
# ─────────────────────────────────────────────
var boss_state: int = 0   # 0=미등장, 1~4=단계, 5=완료
var ending_completed: bool = false
var score_ui_unlocked: bool = false

# ─────────────────────────────────────────────
# 내부 진행 단계 (UI에 노출 금지)
# ─────────────────────────────────────────────
var _progress_stage: int = 0

# ─────────────────────────────────────────────
# 설정
# ─────────────────────────────────────────────
var music_volume: float = 0.8
var sound_volume: float = 0.8
var text_speed: float = 0.05
var screen_shake: bool = true
var flash_effects: bool = false

# ─────────────────────────────────────────────
# 대화 잠금 상태
# ─────────────────────────────────────────────
var is_dialogue_active: bool = false
var is_transitioning: bool = false
var input_locked: bool = false

# ─────────────────────────────────────────────
# 초기화
# ─────────────────────────────────────────────
func _ready() -> void:
	_load_settings()

func _load_settings() -> void:
	var f = FileAccess.open("res://data/default_settings.json", FileAccess.READ)
	if f:
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			var d: Dictionary = json.data
			music_volume = d.get("music_volume", 0.8)
			sound_volume = d.get("sound_volume", 0.8)
			text_speed = d.get("text_speed", 0.05)
			screen_shake = d.get("screen_shake", true)
			flash_effects = d.get("flash_effects", false)
		f.close()

# ─────────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────────

## 음표 수집 처리
func collect_note(note_id: String) -> void:
	if note_id in collected_note_ids:
		return
	collected_note_ids.append(note_id)
	var new_stage = collected_note_ids.size()
	var stage_changed = (new_stage != _progress_stage)
	_progress_stage = new_stage
	note_collected.emit(note_id)
	if stage_changed:
		progress_stage_changed.emit(_progress_stage)

## 아이템 수집 처리
func collect_item(item_id: String) -> void:
	if item_id in collected_item_ids:
		return
	collected_item_ids.append(item_id)
	item_collected.emit(item_id)

## 이벤트 완료 처리
func complete_event(event_id: String) -> void:
	if event_id in completed_event_ids:
		return
	completed_event_ids.append(event_id)
	npc_event_completed.emit(event_id)

## 지역 발견 처리
func discover_region(region_id: String) -> void:
	if region_id in discovered_region_ids:
		return
	discovered_region_ids.append(region_id)
	if region_id not in unlocked_region_ids:
		unlocked_region_ids.append(region_id)
	region_discovered.emit(region_id)

## 지역 잠금 해제
func unlock_region(region_id: String) -> void:
	if region_id not in unlocked_region_ids:
		unlocked_region_ids.append(region_id)

## 내부 진행 단계 반환 (내부 시스템 전용)
func get_progress_stage() -> int:
	return _progress_stage

## 지도 셀 방문 처리
func visit_map_cell(cell: Vector2i) -> void:
	if cell not in visited_map_cells:
		visited_map_cells.append(cell)

## 이벤트 완료 여부 확인
func is_event_done(event_id: String) -> bool:
	return event_id in completed_event_ids

## 아이템 보유 여부 확인
func has_item(item_id: String) -> bool:
	return item_id in collected_item_ids

## 음표 보유 여부 확인
func has_note(note_id: String) -> bool:
	return note_id in collected_note_ids

## NPC 상태 갱신
func set_npc_state(npc_id: String, key: String, value: Variant) -> void:
	if npc_id not in npc_states:
		npc_states[npc_id] = {}
	npc_states[npc_id][key] = value

## NPC 상태 조회
func get_npc_state(npc_id: String, key: String, default: Variant = null) -> Variant:
	if npc_id in npc_states and key in npc_states[npc_id]:
		return npc_states[npc_id][key]
	return default

## 입력 잠금 제어
func lock_input() -> void:
	input_locked = true

func unlock_input() -> void:
	input_locked = false

## 새 게임 초기화
func reset_for_new_game() -> void:
	current_region = "ash_forest"
	player_position = Vector2(240, 200)
	collected_item_ids = []
	collected_note_ids = []
	discovered_region_ids = ["ash_forest"]
	visited_map_cells = []
	unlocked_region_ids = ["ash_forest"]
	completed_event_ids = []
	npc_states = {}
	boss_state = 0
	ending_completed = false
	score_ui_unlocked = false
	_progress_stage = 0
	is_dialogue_active = false
	is_transitioning = false
	input_locked = false
	new_game_started.emit()

## 직렬화 (저장용)
func to_dict() -> Dictionary:
	return {
		"current_region": current_region,
		"player_position_x": player_position.x,
		"player_position_y": player_position.y,
		"collected_item_ids": collected_item_ids,
		"collected_note_ids": collected_note_ids,
		"discovered_region_ids": discovered_region_ids,
		"visited_map_cells": _cells_to_array(visited_map_cells),
		"unlocked_region_ids": unlocked_region_ids,
		"completed_event_ids": completed_event_ids,
		"npc_states": npc_states,
		"boss_state": boss_state,
		"ending_completed": ending_completed,
		"score_ui_unlocked": score_ui_unlocked,
		"music_volume": music_volume,
		"sound_volume": sound_volume,
		"text_speed": text_speed,
		"screen_shake": screen_shake,
	}

## 역직렬화 (불러오기용)
func from_dict(d: Dictionary) -> void:
	current_region = d.get("current_region", "ash_forest")
	player_position = Vector2(
		d.get("player_position_x", 320.0),
		d.get("player_position_y", 200.0)
	)
	collected_item_ids = _to_string_array(d.get("collected_item_ids", []))
	collected_note_ids = _to_string_array(d.get("collected_note_ids", []))
	discovered_region_ids = _to_string_array(d.get("discovered_region_ids", []))
	visited_map_cells = _array_to_cells(d.get("visited_map_cells", []))
	unlocked_region_ids = _to_string_array(d.get("unlocked_region_ids", ["ash_forest"]))
	completed_event_ids = _to_string_array(d.get("completed_event_ids", []))
	npc_states = d.get("npc_states", {})
	boss_state = d.get("boss_state", 0)
	ending_completed = d.get("ending_completed", false)
	score_ui_unlocked = d.get("score_ui_unlocked", false)
	music_volume = d.get("music_volume", 0.8)
	sound_volume = d.get("sound_volume", 0.8)
	text_speed = d.get("text_speed", 0.05)
	screen_shake = d.get("screen_shake", true)
	_progress_stage = collected_note_ids.size()
	game_loaded.emit()

# ─────────────────────────────────────────────
# 내부 유틸리티
# ─────────────────────────────────────────────

func _cells_to_array(cells: Array[Vector2i]) -> Array:
	var result = []
	for c in cells:
		result.append([c.x, c.y])
	return result

func _array_to_cells(arr: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for item in arr:
		if item is Array and item.size() >= 2:
			result.append(Vector2i(item[0], item[1]))
	return result

func _to_string_array(arr: Array) -> Array[String]:
	var result: Array[String] = []
	for item in arr:
		result.append(str(item))
	return result
