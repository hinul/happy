## DialogueUI.gd
## 고전 RPG 스타일의 대화창 UI
## 얇은 픽셀 테두리, 어두운 반투명 배경, 타이핑 효과
## 대화 진행 힌트 표시, 키/클릭 모두 반응
extends Control

@onready var dialogue_panel: Control = $DialoguePanel if has_node("DialoguePanel") else null
@onready var speaker_label: Label = $DialoguePanel/VBox/SpeakerName if has_node("DialoguePanel/VBox/SpeakerName") else null
@onready var text_label: RichTextLabel = $DialoguePanel/VBox/DialogueText if has_node("DialoguePanel/VBox/DialogueText") else null
@onready var continue_icon: Label = $DialoguePanel/VBox/ContinueIcon if has_node("DialoguePanel/VBox/ContinueIcon") else null
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

var _full_text: String = ""
var _char_timer: float = 0.0
var _char_index: int = 0
var _is_typing: bool = false
var _blink_timer: float = 0.0
var _hint_label: Label = null

func _ready() -> void:
	add_to_group("dialogue_ui")
	DialogueManager.register_ui(self)
	GameState.dialogue_started.connect(_on_dialogue_started)
	GameState.dialogue_finished.connect(_on_dialogue_finished)
	_setup_hint_label()
	hide()
	if continue_icon:
		continue_icon.text = "▼"

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if DialogueManager.is_active():
			DialogueManager.advance()

func _setup_hint_label() -> void:
	# 대화창 하단에 조작 힌트 레이블 추가
	if not dialogue_panel:
		return
	_hint_label = Label.new()
	_hint_label.text = "[Space · Enter · E · 클릭]  계속"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.theme_override_colors["font_color"] = Color(0.6, 0.65, 0.70, 0.75)
	_hint_label.theme_override_font_sizes["font_size"] = 9
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.70, 0.75))
	_hint_label.visible = false
	dialogue_panel.add_child(_hint_label)
	# 패널 우하단에 배치
	_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint_label.position = Vector2(-140.0, -16.0)

func _process(delta: float) -> void:
	if not _is_typing:
		# 계속 힌트 깜빡임
		_blink_timer += delta
		if _hint_label and _hint_label.visible:
			_hint_label.modulate.a = 0.6 + sin(_blink_timer * 3.5) * 0.4
		if continue_icon and continue_icon.visible:
			continue_icon.modulate.a = 0.5 + sin(_blink_timer * 3.5) * 0.5
		return
	_char_timer += delta
	var speed = GameState.text_speed
	if _char_timer >= speed:
		_char_timer = 0.0
		_char_index += 1
		if _char_index <= _full_text.length():
			if text_label:
				text_label.text = _full_text.substr(0, _char_index)
		else:
			_finish_typing()

# ─────────────────────────────────────────────
# DialogueManager 인터페이스
# ─────────────────────────────────────────────

func show_dialogue() -> void:
	show()
	if animation_player and animation_player.has_animation("show"):
		animation_player.play("show")

func hide_dialogue() -> void:
	if _hint_label:
		_hint_label.visible = false
	if animation_player and animation_player.has_animation("hide"):
		animation_player.play("hide")
		await animation_player.animation_finished
	hide()

func display_line(text: String, speaker: String) -> void:
	_full_text = text
	_char_index = 0
	_char_timer = 0.0
	_is_typing = true
	_blink_timer = 0.0
	if speaker_label:
		speaker_label.text = speaker
		speaker_label.visible = not speaker.is_empty()
	if text_label:
		text_label.text = ""
	if continue_icon:
		continue_icon.visible = false
	if _hint_label:
		_hint_label.visible = false

func skip_typing() -> void:
	if _is_typing:
		_char_index = _full_text.length()
		if text_label:
			text_label.text = _full_text
		_finish_typing()

func show_choices(choices: Array[String]) -> void:
	# 선택지는 대화창 위쪽에 버튼으로 표시
	var choice_container = $DialoguePanel/ChoiceContainer if has_node("DialoguePanel/ChoiceContainer") else null
	if not choice_container:
		return
	choice_container.show()
	for child in choice_container.get_children():
		child.queue_free()
	for i in range(choices.size()):
		var btn = Button.new()
		btn.text = choices[i]
		btn.pressed.connect(func(): DialogueManager.select_choice(i))
		choice_container.add_child(btn)

# ─────────────────────────────────────────────
# 내부
# ─────────────────────────────────────────────

func _finish_typing() -> void:
	_is_typing = false
	_blink_timer = 0.0
	if continue_icon:
		continue_icon.visible = true
	if _hint_label:
		_hint_label.visible = true
	# 타이핑 완료를 DialogueManager에 알림
	if DialogueManager.has_method("_on_typing_finished"):
		DialogueManager._on_typing_finished()

func _on_dialogue_started() -> void:
	show_dialogue()

func _on_dialogue_finished() -> void:
	_is_typing = false
	if _hint_label:
		_hint_label.visible = false
