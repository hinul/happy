## SaveManager.gd
## 저장·불러오기 시스템
## 임시 파일에 먼저 기록 후 검증하여 실제 파일로 교체 (데이터 손상 방지)
extends Node

const SAVE_PATH = "user://savegame.json"
const SAVE_TEMP_PATH = "user://savegame.tmp"
const SAVE_VERSION = 1

var _has_save_data: bool = false

# ─────────────────────────────────────────────
# 초기화
# ─────────────────────────────────────────────
func _ready() -> void:
	_has_save_data = FileAccess.file_exists(SAVE_PATH)
	_check_storage_persistence()

func _check_storage_persistence() -> void:
	# IndexedDB(웹 환경)에서 저장 지속성을 간단히 확인
	# 저장이 불가능한 환경은 중립적인 메시지로 안내 (기술 용어 미노출)
	var test_path = "user://.storage_check"
	var f = FileAccess.open(test_path, FileAccess.WRITE)
	if not f:
		push_warning("[SaveManager] 저장 경로에 쓰기가 불가능합니다. (브라우저 환경 확인 필요)")
	else:
		f.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))

# ─────────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────────

func has_save() -> bool:
	return _has_save_data

func save() -> bool:
	GameState.save_requested.emit()
	var data = GameState.to_dict()
	data["save_version"] = SAVE_VERSION
	data["save_timestamp"] = Time.get_unix_time_from_system()

	# 1. 임시 파일에 기록
	var tmp = FileAccess.open(SAVE_TEMP_PATH, FileAccess.WRITE)
	if not tmp:
		push_error("[SaveManager] 임시 저장 파일을 열 수 없습니다.")
		return false
	tmp.store_string(JSON.stringify(data, "\t"))
	tmp.close()

	# 2. 임시 파일 검증
	var verify = FileAccess.open(SAVE_TEMP_PATH, FileAccess.READ)
	if not verify:
		push_error("[SaveManager] 임시 저장 파일 검증 실패.")
		return false
	var json = JSON.new()
	var err = json.parse(verify.get_as_text())
	verify.close()
	if err != OK:
		push_error("[SaveManager] 임시 파일 JSON 파싱 실패.")
		return false

	# 3. 실제 저장 파일로 교체
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var rename_err = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(SAVE_TEMP_PATH),
		ProjectSettings.globalize_path(SAVE_PATH)
	)
	if rename_err != OK:
		# rename이 안 될 경우 copy 방식으로 대체
		var src = FileAccess.open(SAVE_TEMP_PATH, FileAccess.READ)
		var dst = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if src and dst:
			dst.store_string(src.get_as_text())
			src.close()
			dst.close()

	_has_save_data = true
	GameState.save_completed.emit()
	return true

func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		push_error("[SaveManager] 저장 파일을 열 수 없습니다.")
		return false

	var json = JSON.new()
	var err = json.parse(f.get_as_text())
	f.close()

	if err != OK:
		push_error("[SaveManager] 저장 파일 파싱 실패. 파일이 손상되었을 수 있습니다.")
		return false

	var data: Dictionary = json.data
	_migrate_save_data(data)
	GameState.from_dict(data)
	return true

func auto_save() -> void:
	# 자동 저장: 즉시 실행 (백그라운드 스레드 없이)
	save()

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	_has_save_data = false

# ─────────────────────────────────────────────
# 저장 데이터 버전 마이그레이션
# ─────────────────────────────────────────────
func _migrate_save_data(data: Dictionary) -> void:
	var version = data.get("save_version", 0)
	if version < 1:
		# v0 → v1: 기본값 보완
		if not data.has("score_ui_unlocked"):
			data["score_ui_unlocked"] = false
		if not data.has("boss_state"):
			data["boss_state"] = 0
		if not data.has("screen_shake"):
			data["screen_shake"] = true
		data["save_version"] = 1
