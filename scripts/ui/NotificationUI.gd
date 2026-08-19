## NotificationUI.gd
## 아이템 획득 알림 (화면 중앙을 가리지 않는 작은 메시지)
## "화면을 가득 채우는 획득 연출" 사용 금지
extends Control

@onready var container: VBoxContainer = $Container if has_node("Container") else null

const NOTIFICATION_DURATION := 3.0
const MAX_NOTIFICATIONS := 3

func _ready() -> void:
	add_to_group("notification_ui")
	mouse_filter = MOUSE_FILTER_IGNORE

func show_item_pickup(item_name: String, description: String) -> void:
	if not container:
		return
	# 최대 3개 유지
	if container.get_child_count() >= MAX_NOTIFICATIONS:
		container.get_child(0).queue_free()

	var panel := _create_notification_panel(item_name, description)
	container.add_child(panel)

	# 자동 사라짐
	var tween := create_tween()
	tween.tween_interval(NOTIFICATION_DURATION - 0.5)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)

func show_note_collected(note_number: int) -> void:
	if not container:
		return
	var panel := _create_notification_panel("♪ " + str(note_number) + "번째 음", "")
	container.add_child(panel)
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)

func _create_notification_panel(title: String, desc: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.modulate.a = 0.0
	var vbox := VBoxContainer.new()
	var title_label := Label.new()
	title_label.text = "[" + title + "]"
	title_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.70))
	vbox.add_child(title_label)
	if not desc.is_empty():
		var desc_label := Label.new()
		desc_label.text = desc
		desc_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.70))
		vbox.add_child(desc_label)
	panel.add_child(vbox)
	# 페이드인
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	return panel
