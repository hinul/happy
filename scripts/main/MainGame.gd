## MainGame.gd
## 메인 게임 씬: 플레이어 + 현재 지역 + GameUI를 조합하는 컨테이너
## 지역 씬을 동적으로 교체하여 월드를 단일 씬처럼 느끼게 함
extends Node2D

@onready var region_container: Node2D = $RegionContainer
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var game_ui: CanvasLayer = $GameUI

# 현재 로드된 지역 씬 인스턴스
var _current_region_instance: Node = null

# 지역 ID → 씬 경로
const REGION_SCENES = SceneTransitionManager.REGION_SCENES

func _ready() -> void:
	SceneTransitionManager.register_main_game(self)
	GameState.new_game_started.connect(_on_new_game)
	GameState.game_loaded.connect(_on_game_loaded)
	SceneTransitionManager.transition_finished.connect(_on_transition_finished)

	# 방향키 스크롤 방지 (웹 환경)
	_disable_arrow_scroll()

	# 현재 지역 로드
	load_region(GameState.current_region)

	# 새 게임 시작 연출
	if GameState.collected_note_ids.is_empty():
		_play_intro_sequence()

func _disable_arrow_scroll() -> void:
	# 웹에서 방향키로 페이지가 스크롤되지 않도록
	if OS.get_name() == "Web":
		JavaScriptBridge.eval("""
			window.addEventListener('keydown', function(e) {
				if(['ArrowUp','ArrowDown','ArrowLeft','ArrowRight',' '].indexOf(e.key) > -1) {
					e.preventDefault();
				}
			}, {passive: false});
		""")

func _input(event: InputEvent) -> void:
	# 대화 진행 (interact 키)
	if event.is_action_just_pressed("interact") and DialogueManager.is_active():
		DialogueManager.advance()

# ─────────────────────────────────────────────
# 지역 로드 (SceneTransitionManager에서 호출)
# ─────────────────────────────────────────────

func load_region(region_id: String, spawn_point: String = "default") -> void:
	# 기존 지역 제거
	if _current_region_instance:
		_current_region_instance.queue_free()
		_current_region_instance = null

	var scene_path = REGION_SCENES.get(region_id, "")
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("[MainGame] 지역 씬 없음: " + region_id)
		return

	var packed = load(scene_path) as PackedScene
	if not packed:
		return

	_current_region_instance = packed.instantiate()
	region_container.add_child(_current_region_instance)

	# 플레이어 스폰 위치 설정
	if _current_region_instance.has_method("get_spawn_point"):
		var spawn_pos: Vector2 = _current_region_instance.get_spawn_point(spawn_point)
		player.global_position = spawn_pos
		GameState.player_position = spawn_pos

	# WorldStateManager에 현재 지역 등록
	WorldStateManager.register_region(_current_region_instance)

func set_player_position(pos: Vector2) -> void:
	player.global_position = pos
	GameState.player_position = pos

# ─────────────────────────────────────────────
# 새 게임 시작 연출
# ─────────────────────────────────────────────

func _play_intro_sequence() -> void:
	GameState.unlock_input()
	DialogueManager.start_lines(["여기가 어디지?", "왜 이렇게 조용하지?"], "")

	# 악보 힌트 (오브젝트 근처에 있으면)
	# OldScore 오브젝트가 있으면 상호작용 유도

# ─────────────────────────────────────────────
# 신호 핸들러
# ─────────────────────────────────────────────

func _on_new_game() -> void:
	load_region("ash_forest")
	_play_intro_sequence()

func _on_game_loaded() -> void:
	load_region(GameState.current_region)

func _on_transition_finished(_region_id: String) -> void:
	pass  # 필요 시 추가 처리
