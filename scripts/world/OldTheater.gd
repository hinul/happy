## OldTheater.gd — 오래된 극장
extends BaseRegion

@onready var stage_light: Node2D = $StageLight if has_node("StageLight") else null
@onready var npc_musician: Node2D = $NPCs/TheaterMusician if has_node("NPCs/TheaterMusician") else null
@onready var sound_puzzle: Node2D = $Interactables/SoundPuzzle if has_node("Interactables/SoundPuzzle") else null

# 무대 소리 퍼즐 상태
var _sound_sequence: Array[int] = []
const CORRECT_SEQUENCE := [1, 3, 2]  # 세 가지 소리 순서

func _setup_region() -> void:
	region_id = "old_theater"
	spawn_points = {
		"default": Vector2(320, 280),
		"from_garden": Vector2(80, 280),
		"from_hill": Vector2(560, 280),
	}

func apply_progress_stage(stage: int) -> void:
	super.apply_progress_stage(stage)
	_update_stage_lighting(stage)
	if npc_musician:
		npc_musician.set_meta("dialogue_stage", WorldStateManager.get_npc_dialogue_stage("theater_musician"))

func _update_stage_lighting(stage: int) -> void:
	if not stage_light:
		return
	# stage 6+: 극장 조명 켜짐
	if stage >= 6:
		var tween := create_tween()
		tween.tween_property(stage_light, "modulate:a", 1.0, 2.0)
		# stage 8: 무대 조명 완전 점등
		if stage >= 8:
			tween.tween_property(stage_light, "modulate",
				Color(1.0, 0.95, 0.8), 1.5)

## 소리 퍼즐: 무대 악기 소리 순서 입력
func input_sound(sound_id: int) -> bool:
	_sound_sequence.append(sound_id)
	var expected := CORRECT_SEQUENCE[_sound_sequence.size() - 1]
	if sound_id != expected:
		# 실패 — 패널티 없이 다시 시작
		_sound_sequence = []
		return false
	# 소리에 해당하는 음 재생
	var freqs := [261.63, 329.63, 392.00]
	MusicManager.play_sfx_beep(freqs[clampi(sound_id, 0, freqs.size()-1)], 0.3)
	if _sound_sequence.size() >= CORRECT_SEQUENCE.size():
		_on_sound_puzzle_complete()
		return true
	return false

func _on_sound_puzzle_complete() -> void:
	GameState.complete_event("theater_puzzle_done")
	SaveManager.auto_save()
	if has_node("MusicNotes/Note08"):
		$MusicNotes/Note08.visible = true
