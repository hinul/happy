## DawnHill.gd — 새벽의 언덕 (최종 지역)
extends BaseRegion

@onready var path_blocker: Node2D = $PathBlocker if has_node("PathBlocker") else null
@onready var last_note: Node2D = $MusicNotes/LastNote if has_node("MusicNotes/LastNote") else null
@onready var doubt_boss: Node2D = $Encounters/DoubtBoss if has_node("Encounters/DoubtBoss") else null

func _setup_region() -> void:
	region_id = "dawn_hill"
	spawn_points = {
		"default": Vector2(100, 300),
		"from_theater": Vector2(80, 300),
	}

func apply_progress_stage(stage: int) -> void:
	super.apply_progress_stage(stage)
	_update_path(stage)
	_update_dawn(stage)
	_update_boss_state()

func _update_path(stage: int) -> void:
	# stage 8+: 안개가 걷히며 언덕 입구 드러남
	if path_blocker:
		var tween = create_tween()
		tween.tween_property(path_blocker, "modulate:a",
			0.0 if stage >= 8 else 1.0, 3.0)

func _update_dawn(stage: int) -> void:
	if not canvas_modulate:
		return
	if stage >= 8:
		# 새벽빛: 지평선 색조
		var tween = create_tween()
		tween.tween_property(canvas_modulate, "color",
			Color(1.0, 0.92, 0.80), 4.0)

func _update_boss_state() -> void:
	if not doubt_boss:
		return
	doubt_boss.visible = (GameState.get_progress_stage() >= 8)

## 마지막 음표 획득 트리거
func trigger_last_note() -> void:
	if GameState.has_note("note_09"):
		return
	GameState.collect_note("note_09")
	GameState.collect_item("laughter_bottle")
	# 엔딩 시작
	EndingDirector.start_ending()
