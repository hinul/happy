## PauseMenu.gd
## 일시정지 메뉴 (Esc): 저장, 불러오기, 설정, 제목 화면, 닫기
extends Control

@onready var save_btn: Button = $Panel/VBox/SaveBtn if has_node("Panel/VBox/SaveBtn") else null
@onready var load_btn: Button = $Panel/VBox/LoadBtn if has_node("Panel/VBox/LoadBtn") else null
@onready var settings_panel: Control = $Panel/SettingsPanel if has_node("Panel/SettingsPanel") else null
@onready var music_slider: HSlider = $Panel/SettingsPanel/MusicSlider if has_node("Panel/SettingsPanel/MusicSlider") else null
@onready var sound_slider: HSlider = $Panel/SettingsPanel/SoundSlider if has_node("Panel/SettingsPanel/SoundSlider") else null
@onready var text_speed_slider: HSlider = $Panel/SettingsPanel/TextSpeedSlider if has_node("Panel/SettingsPanel/TextSpeedSlider") else null

var _settings_open = false

func _ready() -> void:
	hide()
	if save_btn:
		save_btn.pressed.connect(_on_save)
	if load_btn:
		load_btn.pressed.connect(_on_load)
	var settings_b = get_node_or_null("Panel/VBox/SettingsBtn")
	if settings_b:
		settings_b.pressed.connect(_on_settings)
	var title_b = get_node_or_null("Panel/VBox/TitleBtn")
	if title_b:
		title_b.pressed.connect(_on_title)
	var resume_b = get_node_or_null("Panel/VBox/ResumeBtn")
	if resume_b:
		resume_b.pressed.connect(_close)

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("pause_menu"):
		if GameState.is_dialogue_active or GameState.is_transitioning:
			return
		if visible:
			_close()
		else:
			_open()

func _open() -> void:
	show()
	if save_btn:
		save_btn.disabled = false
	if load_btn:
		load_btn.disabled = not SaveManager.has_save()
	_refresh_settings()

func _close() -> void:
	hide()
	if settings_panel:
		settings_panel.hide()
	_settings_open = false

func _on_save() -> void:
	GameState.player_position = _get_player_pos()
	var ok = SaveManager.save()
	if ok:
		_show_feedback("저장했습니다.")
	else:
		_show_feedback("저장에 실패했습니다.")

func _on_load() -> void:
	if SaveManager.load_save():
		_close()
		SceneTransitionManager.travel_to(GameState.current_region)
	else:
		_show_feedback("불러오기에 실패했습니다.")

func _on_settings() -> void:
	_settings_open = not _settings_open
	if settings_panel:
		settings_panel.visible = _settings_open

func _on_title() -> void:
	_close()
	SceneTransitionManager.fade_out(0.5, func():
		get_tree().change_scene_to_file("res://scenes/main/TitleScreen.tscn")
	)

func _refresh_settings() -> void:
	if music_slider:
		music_slider.value = GameState.music_volume
		if not music_slider.value_changed.is_connected(_on_music_changed):
			music_slider.value_changed.connect(_on_music_changed)
	if sound_slider:
		sound_slider.value = GameState.sound_volume
		if not sound_slider.value_changed.is_connected(_on_sound_changed):
			sound_slider.value_changed.connect(_on_sound_changed)
	if text_speed_slider:
		text_speed_slider.value = GameState.text_speed
		if not text_speed_slider.value_changed.is_connected(_on_text_speed_changed):
			text_speed_slider.value_changed.connect(_on_text_speed_changed)

func _on_music_changed(val: float) -> void:
	MusicManager.set_music_volume(val)

func _on_sound_changed(val: float) -> void:
	MusicManager.set_sound_volume(val)

func _on_text_speed_changed(val: float) -> void:
	GameState.text_speed = val

func _show_feedback(text: String) -> void:
	var label = get_node_or_null("Panel/FeedbackLabel")
	if label:
		label.text = text
		var tween = create_tween()
		tween.tween_property(label, "modulate:a", 0.0, 2.0).set_delay(1.0)

func _get_player_pos() -> Vector2:
	var player = get_tree().get_first_node_in_group("player")
	return player.global_position if player else GameState.player_position
