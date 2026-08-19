## RainLake.gd — 비의 호수
extends BaseRegion

@onready var rain_particles: GPUParticles2D = $RainParticles if has_node("RainParticles") else null
@onready var reflection_layer: Node2D = $ReflectionLayer if has_node("ReflectionLayer") else null
@onready var bridge: Node2D = $Interactables/WoodBridge if has_node("Interactables/WoodBridge") else null
@onready var npc_fisherman: Node2D = $NPCs/LakeFisherman if has_node("NPCs/LakeFisherman") else null

func _setup_region() -> void:
	region_id = "rain_lake"
	spawn_points = {
		"default": Vector2(200, 240),
		"from_village": Vector2(80, 240),
		"from_garden": Vector2(560, 240),
	}

func apply_progress_stage(stage: int) -> void:
	super.apply_progress_stage(stage)
	_update_rain(stage)
	_update_reflections(stage)
	if npc_fisherman:
		npc_fisherman.set_meta("dialogue_stage", WorldStateManager.get_npc_dialogue_stage("lake_fisherman"))

func _update_rain(stage: int) -> void:
	if not rain_particles:
		return
	# stage가 높을수록 비가 줄어듦
	var amount = int(lerpf(200.0, 30.0, float(stage) / 9.0))
	rain_particles.amount = amount

func _update_reflections(stage: int) -> void:
	if not reflection_layer:
		return
	# stage 4+: 수면 반사 효과 등장
	var tween = create_tween()
	tween.tween_property(reflection_layer, "modulate:a",
		lerpf(0.0, 0.8, float(maxi(0, stage - 4)) / 5.0), 2.0)

## 호수 발판 퍼즐 (종이배 방향 단서)
func check_stepping_stone_puzzle(sequence: Array[int]) -> bool:
	# 올바른 순서: [2, 0, 3, 1] (종이배가 가리키는 방향)
	var correct = [2, 0, 3, 1]
	return sequence == correct
