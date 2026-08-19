## SmallVillage.gd — 작은 마을
extends BaseRegion

@onready var lanterns: Node2D = $Interactables/Lanterns if has_node("Interactables/Lanterns") else null
@onready var npc_elder: Node2D = $NPCs/VillageElder if has_node("NPCs/VillageElder") else null
@onready var npc_kid: Node2D = $NPCs/VillageKid if has_node("NPCs/VillageKid") else null

func _setup_region() -> void:
	region_id = "small_village"
	spawn_points = {
		"default": Vector2(200, 250),
		"from_forest": Vector2(80, 250),
		"from_lake": Vector2(560, 250),
	}

func apply_progress_stage(stage: int) -> void:
	super.apply_progress_stage(stage)
	_update_windows(stage)
	_update_lanterns(stage)
	if npc_elder:
		npc_elder.set_meta("dialogue_stage", WorldStateManager.get_npc_dialogue_stage("village_elder"))
	if npc_kid:
		npc_kid.set_meta("dialogue_stage", WorldStateManager.get_npc_dialogue_stage("village_kid"))

func _update_windows(stage: int) -> void:
	if not changeable_decorations:
		return
	# stage 4+: 창문에 불이 켜짐
	for child in changeable_decorations.get_children():
		if child.name.contains("Window"):
			var min_s: int = child.get_meta("min_stage", 4)
			var tween = create_tween()
			tween.tween_property(child, "modulate",
				Color(1.0, 0.9, 0.6) if stage >= min_s else Color(0.3, 0.3, 0.35), 1.5)

func _update_lanterns(stage: int) -> void:
	if not lanterns:
		return
	lanterns.visible = stage >= 3
