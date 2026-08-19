## DialogueUI.gd
## 고전 RPG 스타일의 대화창 UI
## 얇은 픽셀 테두리, 어두운 반투명 배경, 타이핑 효과
extends Control

@onready var dialogue_panel: Control = $DialoguePanel if has_node("DialoguePanel") else null
@onready var speaker_label: Label = $DialoguePanel/SpeakerName
@onready var text_label: RichTextLabel = $DialoguePanel/DialogueText
@onready var continue_icon: Label = $DialoguePanel/ContinueIcon
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _full_text: String = ""
var _char_timer: float = 0.0
var _char_index: int = 0
var _is_typing: bool = false

func _ready() -> void:
	add_to_group("dialogue_ui")
	DialogueManager.register_ui(self)
	GameState.dialogue_started.connect(_on_dialogue_started)
	GameState.dialogue_finished.connect(_on_dialogue_finished)
	hide()
	if continue_icon:
		continue_icon.text = "▼"

func _process(delta: float) -> void:
	if not _is_typing:
		return
	_char_timer += delta
	var speed := GameState.text_speed
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
	if animation_player and animation_player.has_animation("hide"):
		animation_player.play("hide")
		await animation_player.animation_finished
	hide()

func display_line(text: String, speaker: String) -> void:
	_full_text = text
	_char_index = 0
	_char_timer = 0.0
	_is_typing = true
	if speaker_label:
		speaker_label.text = speaker
		speaker_label.visible = not speaker.is_empty()
	if text_label:
		text_label.text = ""
	if continue_icon:
		continue_icon.visible = false

func skip_typing() -> void:
	if _is_typing:
		_char_index = _full_text.length()
		if text_label:
			text_label.text = _full_text
		_finish_typing()

func show_choices(choices: Array[String]) -> void:
	# 선택지는 대화창 위쪽에 버튼으로 표시
	var choice_container := $DialoguePanel/ChoiceContainer if has_node("DialoguePanel/ChoiceContainer") else null
	if not choice_container:
		return
	choice_container.show()
	for child in choice_container.get_children():
		child.queue_free()
	for i in range(choices.size()):
		var btn := Button.new()
		btn.text = choices[i]
		btn.pressed.connect(func(): DialogueManager.select_choice(i))
		choice_container.add_child(btn)

# ─────────────────────────────────────────────
# 내부
# ─────────────────────────────────────────────

func _finish_typing() -> void:
	_is_typing = false
	if continue_icon:
		continue_icon.visible = true

func _on_dialogue_started() -> void:
	show_dialogue()

func _on_dialogue_finished() -> void:
	_is_typing = false
