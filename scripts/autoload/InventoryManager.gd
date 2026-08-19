## InventoryManager.gd
## 아이템 보유·사용·UI 갱신 관리
extends Node

signal inventory_updated
signal item_used_in_encounter(item_id: String, response: String)

var _item_data_cache: Dictionary = {}  # item_id → item dict

func _ready() -> void:
	_load_item_data()
	GameState.item_collected.connect(_on_item_collected)

func _load_item_data() -> void:
	var f := FileAccess.open("res://data/items.json", FileAccess.READ)
	if not f:
		push_error("[InventoryManager] items.json을 찾을 수 없습니다.")
		return
	var json := JSON.new()
	if json.parse(f.get_as_text()) == OK:
		var items: Array = json.data.get("items", [])
		for item in items:
			_item_data_cache[item.get("id", "")] = item
	f.close()

# ─────────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────────

## 보유 아이템 목록 반환
func get_items() -> Array[String]:
	return GameState.collected_item_ids.duplicate()

## 아이템 정보 반환
func get_item_data(item_id: String) -> Dictionary:
	return _item_data_cache.get(item_id, {})

## 아이템 보유 여부
func has_item(item_id: String) -> bool:
	return GameState.has_item(item_id)

## 만남 이벤트(생각/보스)에서 아이템 사용
## 아이템이 잘못 선택돼도 소모되지 않음
func use_item_in_encounter(item_id: String, encounter_type: String, encounter_id: String) -> String:
	var data := get_item_data(item_id)
	if data.is_empty():
		return "이건 지금 필요한 게 아닌 것 같다."

	var response := ""
	match encounter_type:
		"boss":
			response = data.get("boss_response", "...")
		"thought":
			var responses: Dictionary = data.get("thought_responses", {})
			response = responses.get(encounter_id, "...")

	if response.is_empty():
		response = "이건 지금 필요한 게 아닌 것 같다."

	item_used_in_encounter.emit(item_id, response)
	return response

## 아이템 표시 이름 반환
func get_display_name(item_id: String) -> String:
	return _item_data_cache.get(item_id, {}).get("display_name", item_id)

## 아이템 설명 반환
func get_description(item_id: String) -> String:
	return _item_data_cache.get(item_id, {}).get("description", "")

# ─────────────────────────────────────────────
# 내부
# ─────────────────────────────────────────────

func _on_item_collected(item_id: String) -> void:
	inventory_updated.emit()
	SaveManager.auto_save()
