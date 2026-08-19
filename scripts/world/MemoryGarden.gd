## MemoryGarden.gd — 기억의 정원
extends BaseRegion

@onready var npc_keeper: Node2D = $NPCs/GardenKeeper if has_node("NPCs/GardenKeeper") else null
@onready var flower_beds: Node2D = $ChangeableDecorations/FlowerBeds if has_node("ChangeableDecorations/FlowerBeds") else null
@onready var photo_puzzle: Node2D = $Interactables/PhotoPuzzle if has_node("Interactables/PhotoPuzzle") else null

# 사진 조각 배치 현황 (장소 기준, 시간순 아님)
var _placed_photos: Dictionary = {}
const REQUIRED_PHOTOS = 4

func _setup_region() -> void:
	region_id = "memory_garden"
	spawn_points = {
		"default": Vector2(240, 220),
		"from_lake": Vector2(80, 220),
		"from_theater": Vector2(560, 220),
	}

func apply_progress_stage(stage: int) -> void:
	super.apply_progress_stage(stage)
	_update_flowers(stage)
	if npc_keeper:
		npc_keeper.set_meta("dialogue_stage", WorldStateManager.get_npc_dialogue_stage("garden_keeper"))

func _update_flowers(stage: int) -> void:
	if not flower_beds:
		return
	# stage 6+: 꽃 출현
	for child in flower_beds.get_children():
		var min_s: int = child.get_meta("min_stage", 6)
		var target_scale = Vector2.ONE if stage >= min_s else Vector2(0.1, 0.1)
		var tween = create_tween()
		tween.tween_property(child, "scale", target_scale, 1.2)

## 사진 조각 배치 (시간순이 아닌 장소별 배치 퍼즐)
func place_photo(slot_id: String, photo_id: String) -> void:
	_placed_photos[slot_id] = photo_id
	if _placed_photos.size() >= REQUIRED_PHOTOS:
		_on_puzzle_complete()

func _on_puzzle_complete() -> void:
	# 퍼즐 완료 — 과거를 완벽히 복원하지 않음, 그냥 완료 처리
	GameState.complete_event("garden_photo_placed")
	SaveManager.auto_save()
	# 음표 단서 표시
	if has_node("MusicNotes/Note06"):
		$MusicNotes/Note06.visible = true
