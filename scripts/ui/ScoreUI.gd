## ScoreUI.gd
## 악보 UI — 9개 음표 빈자리와 수집된 음표 표시 (Tab 키)
## 오래된 종이 형태, 수치·진행률 표시 없음
extends Control

const NOTE_IDS = ["note_01","note_02","note_03","note_04","note_05",
				   "note_06","note_07","note_08","note_09"]

@onready var note_icon: Label = $NoteIcon  # 상단 작은 음표 아이콘

var _note_slots: Array[Label] = []
var _is_animating_icon = false

func _ready() -> void:
	add_to_group("score_ui")
	GameState.note_collected.connect(_on_note_collected)
	GameState.game_loaded.connect(_rebuild)
	hide()
	_build_note_slots()

func _input(event: InputEvent) -> void:
	var pressed_score_key = event.is_action_just_pressed("open_score")
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T or event.physical_keycode == KEY_N:
			pressed_score_key = true

	if pressed_score_key:
		if visible:
			hide()
		elif not GameState.is_dialogue_active:
			show()
			_rebuild()

func _build_note_slots() -> void:
	var container = $Panel/NoteContainer if has_node("Panel/NoteContainer") else null
	if not container:
		return
	for child in container.get_children():
		child.queue_free()
	_note_slots = []
	for i in range(9):
		var slot = Label.new()
		slot.text = "○"
		slot.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(slot)
		_note_slots.append(slot)

func _rebuild() -> void:
	for i in range(NOTE_IDS.size()):
		if i >= _note_slots.size():
			break
		var collected = GameState.has_note(NOTE_IDS[i])
		_note_slots[i].text = "♪" if collected else "○"
		_note_slots[i].add_theme_color_override(
			"font_color",
			Color(0.95, 0.90, 0.60) if collected else Color(0.5, 0.5, 0.5)
		)

func _on_note_collected(_note_id: String) -> void:
	_rebuild()
	animate_icon()

## 악보 메뉴가 추가됨을 알리는 작은 음표 애니메이션
func animate_icon() -> void:
	if not note_icon or _is_animating_icon:
		return
	_is_animating_icon = true
	var tween = create_tween().set_loops(3)
	tween.tween_property(note_icon, "modulate:a", 0.2, 0.2)
	tween.tween_property(note_icon, "modulate:a", 1.0, 0.2)
	tween.finished.connect(func(): _is_animating_icon = false)
