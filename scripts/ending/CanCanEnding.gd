## CanCanEnding.gd
## 캉캉 엔딩 씬: NPC 순차 등장, 군무, 줌아웃, 마지막 문장
extends Node2D

@onready var dancers_container: Node2D = $Dancers
@onready var ending_camera: Camera2D = $EndingCamera
@onready var ending_text_ui: CanvasLayer = $EndingTextUI
@onready var ending_menu_ui: CanvasLayer = $EndingMenuUI
@onready var player_dancer: Node2D = $Dancers/PlayerDancer

var _text_label: Label
var _menu_visible = false

# 댄스 타입별 설정
const DANCE_CONFIGS: Dictionary = {
	"high_kick":       {"kick_height": -40.0, "speed": 1.2},
	"side_step":       {"kick_height": -15.0, "speed": 1.0},
	"spin":            {"kick_height": -20.0, "speed": 1.5},
	"late_join":       {"kick_height": -12.0, "speed": 0.8},
	"wrong_direction": {"kick_height": -18.0, "speed": 0.9},
	"stay_center":     {"kick_height": -10.0, "speed": 0.6},
}

func _ready() -> void:
	EndingDirector.register_ending_scene(self)
	if ending_menu_ui:
		ending_menu_ui.hide()
	if ending_text_ui:
		ending_text_ui.hide()
	_setup_text_label()
	_setup_menu_buttons()

func _setup_text_label() -> void:
	if not ending_text_ui:
		return
	_text_label = Label.new()
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text_label.set_anchors_preset(Control.PRESET_CENTER)
	_text_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.80))
	_text_label.modulate.a = 0.0
	ending_text_ui.add_child(_text_label)

func _setup_menu_buttons() -> void:
	if not ending_menu_ui:
		return
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	ending_menu_ui.add_child(vbox)
	var btn_new = Button.new()
	btn_new.text = "처음부터 다시"
	btn_new.pressed.connect(_on_restart)
	vbox.add_child(btn_new)
	var btn_replay = Button.new()
	btn_replay.text = "마지막 장면 다시 보기"
	btn_replay.pressed.connect(_on_replay)
	vbox.add_child(btn_replay)
	var btn_title = Button.new()
	btn_title.text = "제목 화면으로"
	btn_title.pressed.connect(_on_title)
	vbox.add_child(btn_title)

# ─────────────────────────────────────────────
# EndingDirector 인터페이스
# ─────────────────────────────────────────────

func spawn_dancer(npc_id: String, dance_type: String) -> void:
	var dancer = _create_dancer_node(npc_id, dance_type)
	if dancer:
		dancers_container.add_child(dancer)
		_animate_entry(dancer)

func player_join_dance() -> void:
	if player_dancer:
		player_dancer.visible = true
		_animate_player_join()

func start_zoomout() -> void:
	if not ending_camera:
		return
	var tween = create_tween()
	tween.tween_property(ending_camera, "zoom", Vector2(0.25, 0.25), 5.0).set_trans(Tween.TRANS_SINE)

func show_player_reaction(text: String) -> void:
	show_ending_text(text)

func show_ending_text(text: String) -> void:
	if not ending_text_ui:
		return
	ending_text_ui.show()
	if _text_label:
		_text_label.text = text
		var tween = create_tween()
		tween.tween_property(_text_label, "modulate:a", 1.0, 0.8)

func show_the_end() -> void:
	show_ending_text("THE END")

func show_ending_menu() -> void:
	if ending_menu_ui:
		ending_menu_ui.show()
	_menu_visible = true

# ─────────────────────────────────────────────
# 댄서 생성 및 애니메이션
# ─────────────────────────────────────────────

func _create_dancer_node(npc_id: String, dance_type: String) -> Node2D:
	var node = Node2D.new()
	node.name = "Dancer_" + npc_id
	var sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _create_dancer_frames(npc_id, dance_type)
	sprite.play("dance")
	node.add_child(sprite)
	# 무작위 위치
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	node.position = Vector2(
		rng.randf_range(-200.0, 200.0),
		rng.randf_range(-20.0, 40.0)
	)
	return node

func _create_dancer_frames(npc_id: String, dance_type: String) -> SpriteFrames:
	var frames = SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("dance")
	frames.set_animation_loop("dance", true)
	var config = DANCE_CONFIGS.get(dance_type, DANCE_CONFIGS["side_step"])
	var speed: float = config["speed"]
	frames.set_animation_speed("dance", 8.0 * speed)
	var color = _get_npc_color(npc_id)
	var kick_height: float = config["kick_height"]
	for i in range(8):
		frames.add_frame("dance", _create_dance_frame(color, i, kick_height))
	return frames

func _create_dance_frame(color: Color, frame_idx: int, kick_height: float) -> ImageTexture:
	var img = Image.create(16, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	# 몸통
	for y in range(10, 24):
		for x in range(4, 12):
			img.set_pixel(x, y, color.darkened(0.1))
	# 머리
	for y in range(2, 10):
		for x in range(4, 12):
			img.set_pixel(x, y, color)
	# 눈
	img.set_pixel(6, 5, Color(0.1, 0.1, 0.1))
	img.set_pixel(9, 5, Color(0.1, 0.1, 0.1))
	# 다리 발차기
	var leg_y = 24 + int(kick_height * float(frame_idx % 4) / 3.0 * -1.0)
	leg_y = clampi(leg_y, 0, 31)
	for x in range(4, 8):
		if leg_y >= 0 and leg_y < 32:
			img.set_pixel(x, leg_y, color.darkened(0.2))
	# 반대 다리
	var other_leg_y = 24 + int(kick_height * float((frame_idx + 2) % 4) / 3.0 * -1.0)
	other_leg_y = clampi(other_leg_y, 0, 31)
	for x in range(8, 12):
		if other_leg_y >= 0 and other_leg_y < 32:
			img.set_pixel(x, other_leg_y, color.darkened(0.2))
	return ImageTexture.create_from_image(img)

func _animate_entry(dancer: Node2D) -> void:
	dancer.modulate.a = 0.0
	dancer.position.x += 200.0
	var tween = create_tween()
	tween.tween_property(dancer, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(dancer, "position:x", dancer.position.x - 200.0, 0.5)

func _animate_player_join() -> void:
	if not player_dancer:
		return
	var sprite = player_dancer.get_node_or_null("AnimatedSprite2D")
	if sprite and sprite is AnimatedSprite2D:
		sprite.play("dance")

func _get_npc_color(npc_id: String) -> Color:
	match npc_id:
		"forest_wanderer":  return Color(0.4, 0.5, 0.45)
		"village_elder":    return Color(0.55, 0.45, 0.35)
		"village_kid":      return Color(0.5, 0.55, 0.6)
		"lake_fisherman":   return Color(0.35, 0.45, 0.55)
		"garden_keeper":    return Color(0.45, 0.55, 0.40)
		"theater_musician": return Color(0.50, 0.40, 0.55)
		"thought_shadow_1", "thought_shadow_2": return Color(0.2, 0.2, 0.25, 0.7)
		"doubt_shadow":     return Color(0.15, 0.15, 0.20, 0.6)
		_: return Color(0.6, 0.55, 0.5)

# ─────────────────────────────────────────────
# 엔딩 메뉴 버튼 핸들러
# ─────────────────────────────────────────────

func _on_restart() -> void:
	GameState.reset_for_new_game()
	SaveManager.save()
	get_tree().change_scene_to_file("res://scenes/main/MainGame.tscn")

func _on_replay() -> void:
	EndingDirector.replay_ending()

func _on_title() -> void:
	get_tree().change_scene_to_file("res://scenes/main/TitleScreen.tscn")
