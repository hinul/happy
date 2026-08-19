## WorldStateManager.gd
## 진행 단계에 따른 세계 환경 변화를 모든 지역에 전달
## 직접적인 성장 메시지 없이 시각/청각/행동으로만 변화를 표현
extends Node

# 각 지역의 현재 씬 참조 (SceneTransitionManager가 설정)
var _current_region_node: Node = null

func _ready() -> void:
	GameState.progress_stage_changed.connect(_on_stage_changed)
	GameState.note_collected.connect(_on_note_collected)
	GameState.region_discovered.connect(_on_region_discovered)

# ─────────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────────

## 현재 활성 지역 씬 등록
func register_region(node: Node) -> void:
	_current_region_node = node
	_apply_current_stage()

## 현재 진행 단계를 현재 지역에 즉시 적용
func apply_to_current_region() -> void:
	_apply_current_stage()

## 지역 잠금 해제 판단
func check_region_unlocks(stage: int) -> void:
	match stage:
		2:
			GameState.unlock_region("small_village")
		4:
			GameState.unlock_region("rain_lake")
		5:
			GameState.unlock_region("memory_garden")
		6:
			GameState.unlock_region("old_theater")
		8:
			GameState.unlock_region("dawn_hill")

## 특정 NPC의 현재 대사 단계 반환 (0~3)
func get_npc_dialogue_stage(npc_id: String) -> int:
	var stage := GameState.get_progress_stage()
	# 일부 NPC는 지역 이벤트 완료 여부도 함께 확인
	match npc_id:
		"theater_musician":
			if GameState.is_event_done("theater_puzzle_done") and stage >= 6:
				return 3
		"garden_keeper":
			if GameState.is_event_done("garden_photo_placed") and stage >= 5:
				return 3
	# 기본 단계 계산
	if stage <= 2:
		return 0
	elif stage <= 4:
		return 1
	elif stage <= 7:
		return 2
	else:
		return 3

## 부정적인 생각 이벤트 활성화 여부 확인
func can_spawn_negative_thought(thought_id: String) -> bool:
	if GameState.is_event_done("thought_" + thought_id):
		return false
	var stage := GameState.get_progress_stage()
	return stage >= 1

## 최종 보스 접근 가능 여부
func can_access_doubt_boss() -> bool:
	return GameState.get_progress_stage() >= 8

# ─────────────────────────────────────────────
# 내부
# ─────────────────────────────────────────────

func _on_stage_changed(stage: int) -> void:
	check_region_unlocks(stage)
	_apply_current_stage()
	# NPC 대사 단계는 각 NPC 노드가 신호를 받아 자체 갱신

func _on_note_collected(note_id: String) -> void:
	# 자동 저장
	SaveManager.auto_save()

func _on_region_discovered(region_id: String) -> void:
	SaveManager.auto_save()

func _apply_current_stage() -> void:
	if _current_region_node == null:
		return
	if _current_region_node.has_method("apply_progress_stage"):
		_current_region_node.apply_progress_stage(GameState.get_progress_stage())
