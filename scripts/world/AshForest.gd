## AshForest.gd
## 잿빛 숲 — 게임 시작 지역
## 죽은 나무, 짙은 안개, 첫 악보, 첫 아이템·음표
extends BaseRegion

@onready var fog_layer: Node2D = $FogLayer if has_node("FogLayer") else null
@onready var old_score_object: Node2D = $Interactables/OldScore if has_node("Interactables/OldScore") else null
@onready var npc_forest: Node2D = $NPCs/ForestWanderer if has_node("NPCs/ForestWanderer") else null

func _setup_region() -> void:
	region_id = "ash_forest"
	spawn_points = {
		"default": Vector2(160, 200),
		"from_village": Vector2(600, 200),
	}

func apply_progress_stage(stage: int) -> void:
	super.apply_progress_stage(stage)
	_update_fog(stage)
	_update_trees(stage)
	if npc_forest:
		npc_forest.set_meta("dialogue_stage", WorldStateManager.get_npc_dialogue_stage("forest_wanderer"))

func _update_fog(stage: int) -> void:
	if not fog_layer:
		return
	# 안개 투명도: stage 0=0.85, stage 9=0.1
	var target_alpha = lerpf(0.85, 0.1, float(stage) / 9.0)
	var tween = create_tween()
	tween.tween_property(fog_layer, "modulate:a", target_alpha, 2.0)

func _update_trees(stage: int) -> void:
	# stage 2+: 일부 나무에 작은 잎 출현 (ChangeableDecorations 하위 노드 meta 기반)
	if changeable_decorations:
		for child in changeable_decorations.get_children():
			var min_s: int = child.get_meta("min_stage", 99)
			var tween = create_tween()
			tween.tween_property(child, "modulate:a",
				1.0 if stage >= min_s else 0.0, 0.8)
