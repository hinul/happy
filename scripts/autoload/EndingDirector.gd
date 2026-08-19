## EndingDirector.gd
## 마지막 음표 연출, 캉캉 음악 시작, NPC 순차 등장, 군무 타임라인
## AnimationPlayer 신호와 스크립트 타이머를 함께 사용
## 하나의 거대한 함수에 모든 타이밍을 작성하지 않음
extends Node

signal ending_phase_changed(phase: String)
signal dancer_appeared(npc_id: String)
signal final_text_shown(text: String)
signal ending_menu_shown

# 등장 순서와 댄스 타입 (data/dialogues.json의 npcs와 연동)
const DANCER_SEQUENCE: Array[Dictionary] = [
	{"npc_id": "village_elder",    "entry_time": 2.0,  "dance_type": "stay_center"},
	{"npc_id": "forest_wanderer",  "entry_time": 4.0,  "dance_type": "high_kick"},
	{"npc_id": "village_kid",      "entry_time": 5.5,  "dance_type": "wrong_direction"},
	{"npc_id": "lake_fisherman",   "entry_time": 7.0,  "dance_type": "side_step"},
	{"npc_id": "garden_keeper",    "entry_time": 9.0,  "dance_type": "spin"},
	{"npc_id": "theater_musician", "entry_time": 11.0, "dance_type": "late_join"},
	{"npc_id": "thought_shadow_1", "entry_time": 13.0, "dance_type": "side_step"},
	{"npc_id": "thought_shadow_2", "entry_time": 14.0, "dance_type": "side_step"},
	{"npc_id": "doubt_shadow",     "entry_time": 15.5, "dance_type": "late_join"},
]

const FINAL_TEXTS: Array[String] = [
	"나는 변하고 있는 줄 몰랐다.",
	"그냥 하나씩 찾았을 뿐이다.",
	"그랬더니 어느새, 내가 춤추고 있었다.",
]

const TEXT_INTERVALS: Array[float] = [3.0, 3.0, 4.0]

var _ending_scene: Node = null
var _is_running: bool = false

func _ready() -> void:
	GameState.ending_started.connect(_on_ending_started)

# ─────────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────────

func register_ending_scene(scene: Node) -> void:
	_ending_scene = scene

## 엔딩 시퀀스 시작
func start_ending() -> void:
	if _is_running:
		return
	_is_running = true
	GameState.lock_input()
	GameState.ending_started.emit()
	_phase_last_note()

## 엔딩 재생 (이미 본 엔딩 다시 보기)
func replay_ending() -> void:
	start_ending()

# ─────────────────────────────────────────────
# 단계별 함수 (각 단계가 다음 단계를 호출)
# ─────────────────────────────────────────────

## 1단계: 마지막 음표 획득 연출
func _phase_last_note() -> void:
	ending_phase_changed.emit("last_note")
	# 9개 음표가 하나씩 울리는 연출
	_play_note_sequence(0, func(): _phase_cancan_start())

func _play_note_sequence(index: int, callback: Callable) -> void:
	if index >= 9:
		callback.call()
		return
	MusicManager.play_note_pickup(index)
	var t := get_tree().create_timer(0.35)
	t.timeout.connect(func(): _play_note_sequence(index + 1, callback))

## 2단계: 캉캉 시작 전 정적
func _phase_cancan_start() -> void:
	ending_phase_changed.emit("silence_before_cancan")
	# 짧은 정적
	var t := get_tree().create_timer(1.2)
	t.timeout.connect(func():
		MusicManager.play_cancan()
		_phase_npc_parade()
	)

## 3단계: NPC 순차 등장
func _phase_npc_parade() -> void:
	ending_phase_changed.emit("npc_parade")
	for dancer_data in DANCER_SEQUENCE:
		var entry_time: float = dancer_data["entry_time"]
		var npc_id: String = dancer_data["npc_id"]
		var t := get_tree().create_timer(entry_time)
		t.timeout.connect(func():
			dancer_appeared.emit(npc_id)
			if _ending_scene and _ending_scene.has_method("spawn_dancer"):
				_ending_scene.spawn_dancer(npc_id, dancer_data.get("dance_type", "side_step"))
		)

	# 주인공 합류 (16초 후)
	var player_join_timer := get_tree().create_timer(16.0)
	player_join_timer.timeout.connect(_phase_player_joins)

## 4단계: 주인공 춤 합류
func _phase_player_joins() -> void:
	ending_phase_changed.emit("player_joins")
	if _ending_scene and _ending_scene.has_method("player_join_dance"):
		_ending_scene.player_join_dance()

	# 카메라 줌아웃 (22초 후)
	var zoom_timer := get_tree().create_timer(6.0)
	zoom_timer.timeout.connect(_phase_camera_zoomout)

## 5단계: 카메라 줌아웃
func _phase_camera_zoomout() -> void:
	ending_phase_changed.emit("camera_zoomout")
	if _ending_scene and _ending_scene.has_method("start_zoomout"):
		_ending_scene.start_zoomout()

	# 주인공 대사: "어라?" (줌아웃 중간)
	var text_timer := get_tree().create_timer(3.0)
	text_timer.timeout.connect(func():
		if _ending_scene and _ending_scene.has_method("show_player_reaction"):
			_ending_scene.show_player_reaction("어라?")
	)

	# 최종 문장 (줌아웃 완료 후)
	var final_timer := get_tree().create_timer(5.0)
	final_timer.timeout.connect(_phase_final_texts)

## 6단계: 마지막 문장 순차 표시
func _phase_final_texts() -> void:
	ending_phase_changed.emit("final_texts")
	_show_text_sequence(0)

func _show_text_sequence(index: int) -> void:
	if index >= FINAL_TEXTS.size():
		_phase_the_end()
		return
	var text := FINAL_TEXTS[index]
	final_text_shown.emit(text)
	if _ending_scene and _ending_scene.has_method("show_ending_text"):
		_ending_scene.show_ending_text(text)
	var interval := TEXT_INTERVALS[index] if index < TEXT_INTERVALS.size() else 3.0
	var t := get_tree().create_timer(interval)
	t.timeout.connect(func(): _show_text_sequence(index + 1))

## 7단계: THE END + 엔딩 메뉴
func _phase_the_end() -> void:
	ending_phase_changed.emit("the_end")
	GameState.ending_completed = true
	SaveManager.auto_save()

	if _ending_scene and _ending_scene.has_method("show_the_end"):
		_ending_scene.show_the_end()

	var menu_timer := get_tree().create_timer(2.5)
	menu_timer.timeout.connect(func():
		ending_menu_shown.emit()
		if _ending_scene and _ending_scene.has_method("show_ending_menu"):
			_ending_scene.show_ending_menu()
		GameState.unlock_input()
	)

# ─────────────────────────────────────────────
# 신호 핸들러
# ─────────────────────────────────────────────

func _on_ending_started() -> void:
	pass  # ending_started 신호는 start_ending()에서 직접 emit
