## DialogueManager.gd
## NPC 대화·조사 문장·선택지 처리 시스템
## 대사는 JSON에서 관리, 스크립트에 하드코딩 금지
extends Node

signal dialogue_line_shown(text: String, speaker: String)
signal dialogue_choice_required(choices: Array[String])
signal dialogue_choice_made(index: int)
signal dialogue_end

# 대화창 UI 참조 (MainGame 씬에서 등록)
var _dialogue_ui: Node = null

# 대화 상태
var _is_active: bool = false
var _lines: Array[String] = []
var _current_line_index: int = 0
var _speaker_name: String = ""
var _is_typing: bool = false
var _pending_choices: Array[String] = []
var _choice_callback: Callable

# 전체 대사 데이터 캐시
var _dialogue_data: Dictionary = {}

var _auto_advance_timer: float = 0.0
const AUTO_ADVANCE_TIME = 3.5

func _ready() -> void:
	_load_dialogue_data()
	GameState.dialogue_started.connect(func(): _is_active = true)
	GameState.dialogue_finished.connect(func(): _is_active = false)

func _process(delta: float) -> void:
	# 독백(speaker 없음)에만 자동 진행 적용
	if _is_active and not _is_typing and _speaker_name.is_empty() and _pending_choices.is_empty():
		_auto_advance_timer += delta
		if _auto_advance_timer >= AUTO_ADVANCE_TIME:
			_auto_advance_timer = 0.0
			advance()
	else:
		_auto_advance_timer = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if not _is_active:
		return
	if (event is InputEventMouseButton and event.pressed) or event.is_action_just_pressed("interact"):
		advance()

func _load_dialogue_data() -> void:
	var f = FileAccess.open("res://data/dialogues.json", FileAccess.READ)
	if not f:
		push_error("[DialogueManager] dialogues.json을 찾을 수 없습니다.")
		return
	var json = JSON.new()
	if json.parse(f.get_as_text()) == OK:
		_dialogue_data = json.data
	f.close()

# ─────────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────────

## UI 등록
func register_ui(ui: Node) -> void:
	_dialogue_ui = ui

## NPC 대화 시작
func start_npc_dialogue(npc_id: String) -> void:
	var stage = WorldStateManager.get_npc_dialogue_stage(npc_id)
	var lines = _get_npc_lines(npc_id, stage)
	var name_ = _get_npc_name(npc_id)
	_start_dialogue(lines, name_)

## 오브젝트 조사 대화 시작
func start_interactable_dialogue(object_id: String) -> void:
	var lines = _get_interactable_lines(object_id)
	_start_dialogue(lines, "")

## 단순 텍스트 대화 시작 (주인공 독백 등)
func start_lines(lines: Array[String], speaker: String = "") -> void:
	if lines.is_empty():
		return
	_start_dialogue(lines, speaker)

## 선택지 대화 시작
func start_choice_dialogue(
	lines: Array[String],
	speaker: String,
	choices: Array[String],
	callback: Callable
) -> void:
	_pending_choices = choices
	_choice_callback = callback
	_start_dialogue(lines, speaker)

## 다음 대사 진행 (interact 입력 시 호출)
func advance() -> void:
	if not _is_active:
		return
	if _is_typing and _dialogue_ui and _dialogue_ui.has_method("skip_typing"):
		_dialogue_ui.skip_typing()
		return
	_show_next_line()

## 선택지 선택
func select_choice(index: int) -> void:
	dialogue_choice_made.emit(index)
	if _choice_callback.is_valid():
		_choice_callback.call(index)
	_pending_choices = []
	_end_dialogue()

## 대화 활성 여부
func is_active() -> bool:
	return _is_active

# ─────────────────────────────────────────────
# 내부
# ─────────────────────────────────────────────

func _start_dialogue(lines: Array[String], speaker: String) -> void:
	if _is_active:
		return
	if lines.is_empty():
		return
	_lines = lines
	_speaker_name = speaker
	_current_line_index = 0
	_is_active = true
	GameState.lock_input()
	GameState.is_dialogue_active = true
	GameState.dialogue_started.emit()

	if _dialogue_ui and _dialogue_ui.has_method("show_dialogue"):
		_dialogue_ui.show_dialogue()
	_show_next_line()

func _show_next_line() -> void:
	if _current_line_index >= _lines.size():
		# 선택지가 있으면 표시
		if not _pending_choices.is_empty():
			if _dialogue_ui and _dialogue_ui.has_method("show_choices"):
				_dialogue_ui.show_choices(_pending_choices)
			dialogue_choice_required.emit(_pending_choices)
			return
		_end_dialogue()
		return

	var line = _lines[_current_line_index]
	_current_line_index += 1
	dialogue_line_shown.emit(line, _speaker_name)
	if _dialogue_ui and _dialogue_ui.has_method("display_line"):
		_dialogue_ui.display_line(line, _speaker_name)
	_is_typing = true

## 타이핑 완료 콜백 (DialogueUI에서 호출)
func _on_typing_finished() -> void:
	_is_typing = false

func _end_dialogue() -> void:
	_is_active = false
	_lines = []
	_current_line_index = 0
	_speaker_name = ""
	_is_typing = false
	GameState.unlock_input()
	GameState.is_dialogue_active = false
	GameState.dialogue_finished.emit()
	dialogue_end.emit()

	if _dialogue_ui and _dialogue_ui.has_method("hide_dialogue"):
		_dialogue_ui.hide_dialogue()

func _get_npc_lines(npc_id: String, stage: int) -> Array[String]:
	var npcs: Array = _dialogue_data.get("npcs", [])
	for npc in npcs:
		if npc.get("id", "") == npc_id:
			match stage:
				0: return _to_typed_array(npc.get("dialogue_early", []))
				1: return _to_typed_array(npc.get("dialogue_middle", []))
				2: return _to_typed_array(npc.get("dialogue_late", []))
				3: return _to_typed_array(npc.get("dialogue_final", []))
	return ["..."]

func _get_npc_name(npc_id: String) -> String:
	var npcs: Array = _dialogue_data.get("npcs", [])
	for npc in npcs:
		if npc.get("id", "") == npc_id:
			return npc.get("display_name", "")
	return ""

func _get_interactable_lines(object_id: String) -> Array[String]:
	var interactables: Dictionary = _dialogue_data.get("interactables", {})
	if object_id in interactables:
		return _to_typed_array(interactables[object_id].get("lines", []))
	return ["아무것도 보이지 않는다."]

func _to_typed_array(arr: Array) -> Array[String]:
	var result: Array[String] = []
	for item in arr:
		result.append(str(item))
	return result
