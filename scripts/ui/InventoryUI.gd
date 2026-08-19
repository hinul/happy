## InventoryUI.gd
## 인벤토리 격자 UI (I 키로 열고 닫음)
extends Control

@onready var item_grid: GridContainer = $Panel/ItemGrid if has_node("Panel/ItemGrid") else null
@onready var item_name_label: Label = $Panel/ItemInfo/NameLabel if has_node("Panel/ItemInfo/NameLabel") else null
@onready var item_desc_label: Label = $Panel/ItemInfo/DescLabel if has_node("Panel/ItemInfo/DescLabel") else null

var _selected_item: String = ""

func _ready() -> void:
	add_to_group("inventory_ui")
	InventoryManager.inventory_updated.connect(_refresh)
	hide()

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("open_inventory"):
		if visible:
			_close()
		elif not GameState.is_dialogue_active and not GameState.is_transitioning:
			_open()

func _open() -> void:
	_refresh()
	show()

func _close() -> void:
	hide()
	_selected_item = ""

func _refresh() -> void:
	if not item_grid:
		return
	for child in item_grid.get_children():
		child.queue_free()

	var items = InventoryManager.get_items()
	for item_id in items:
		var btn = Button.new()
		btn.text = InventoryManager.get_display_name(item_id)
		btn.custom_minimum_size = Vector2(80, 30)
		btn.pressed.connect(func(): _select_item(item_id))
		item_grid.add_child(btn)

func _select_item(item_id: String) -> void:
	_selected_item = item_id
	if item_name_label:
		item_name_label.text = InventoryManager.get_display_name(item_id)
	if item_desc_label:
		item_desc_label.text = InventoryManager.get_description(item_id)

## 만남 이벤트에서 아이템 사용 (부정적인 생각 / 보스)
func use_selected_in_encounter(encounter_type: String, encounter_id: String) -> String:
	if _selected_item.is_empty():
		return "이건 지금 필요한 게 아닌 것 같다."
	return InventoryManager.use_item_in_encounter(_selected_item, encounter_type, encounter_id)
