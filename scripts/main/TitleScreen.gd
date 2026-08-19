## TitleScreen.gd
## 시작 화면: 검은 배경, 작은 픽셀 음표 하나, 새 게임/이어하기/설정
## 오디오는 새 게임 또는 이어하기 클릭 후에만 시작 (브라우저 정책 대응)
extends Control

@onready var new_game_btn: Button = $VBox/NewGameBtn if has_node("VBox/NewGameBtn") else null
@onready var continue_btn: Button = $VBox/ContinueBtn if has_node("VBox/ContinueBtn") else null
@onready var settings_btn: Button = $VBox/SettingsBtn if has_node("VBox/SettingsBtn") else null
@onready var note_icon: Node2D = $FloatingNote if has_node("FloatingNote") else null
@onready var settings_panel: Control = $SettingsPanel if has_node("SettingsPanel") else null
@onready var storage_warning: Label = $StorageWarning if has_node("StorageWarning") else null

var _note_float_timer = 0.0

func _ready() -> void:
	# 저장 데이터 없으면 이어하기 비활성화
	if continue_btn:
		continue_btn.disabled = not SaveManager.has_save()

	# 버튼 연결
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game)
	if continue_btn:
		continue_btn.pressed.connect(_on_continue)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings)

	# 브라우저 저장 경고 (필요 시)
	_check_storage_warning()
	modulate.a = 1.0

func _process(delta: float) -> void:
	# 음표 아이콘 부유 효과
	if note_icon:
		_note_float_timer += delta
		note_icon.position.y = 40.0 + sin(_note_float_timer * 0.8) * 5.0
		note_icon.rotation = sin(_note_float_timer * 0.5) * 0.05

func _on_new_game() -> void:
	MusicManager.enable_audio()   # 첫 사용자 입력 후 오디오 활성화
	GameState.reset_for_new_game()
	SaveManager.save()
	_start_game()

func _on_continue() -> void:
	MusicManager.enable_audio()   # 첫 사용자 입력 후 오디오 활성화
	if SaveManager.load_save():
		_start_game()
	else:
		if continue_btn:
			continue_btn.text = "저장 데이터 없음"
			continue_btn.disabled = true

func _on_settings() -> void:
	if settings_panel:
		settings_panel.visible = not settings_panel.visible

func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main/MainGame.tscn")

func _check_storage_warning() -> void:
	if not storage_warning:
		return
	# 웹 환경에서 IndexedDB 저장 지속성 불확실 시 중립적 안내
	if OS.get_name() == "Web":
		storage_warning.text = "현재 브라우저 환경에서는 저장 데이터가 다음 실행까지 유지되지 않을 수 있습니다."
		storage_warning.visible = true
	else:
		storage_warning.visible = false
