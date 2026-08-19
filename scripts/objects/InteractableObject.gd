## InteractableObject.gd
## 조사 가능한 일반 오브젝트 (악보, 표지판, 가구 등)
extends Node2D

@export var object_id: String = ""
@export var one_time_only: bool = false
@export var unlocks_score_ui: bool = false

var _interacted := false

func _ready() -> void:
	if one_time_only and GameState.is_event_done("obj_" + object_id):
		_interacted = true

func on_interact() -> void:
	if one_time_only and _interacted:
		return
	DialogueManager.start_interactable_dialogue(object_id)
	DialogueManager.dialogue_end.connect(_on_dialogue_done, CONNECT_ONE_SHOT)

func _on_dialogue_done() -> void:
	if one_time_only:
		_interacted = true
		GameState.complete_event("obj_" + object_id)
	if unlocks_score_ui:
		GameState.score_ui_unlocked = true
		# 악보 메뉴 추가됨을 작은 음표 아이콘 움직임으로 알림
		var ui := get_tree().get_first_node_in_group("score_ui")
		if ui and ui.has_method("animate_icon"):
			ui.animate_icon()
