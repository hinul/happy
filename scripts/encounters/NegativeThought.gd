## NegativeThought.gd
## 부정적인 생각 그림자 생명체 씬
## ShadowNPC를 상속하지 않고 독립적으로 구현 (씬 인스턴스용)
extends Node2D

@export var thought_id: String = "thought_late"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var interaction_area: Area2D = $InteractionArea if has_node("InteractionArea") else null

var _is_interacted := false
var _float_timer := 0.0

func _ready() -> void:
	if GameState.is_event_done("thought_done_" + thought_id):
		# 이미 상호작용 완료 — 작은 그림자로 표시
		scale = Vector2(0.5, 0.5)
		modulate.a = 0.5
		_is_interacted = true
	if sprite:
		sprite.sprite_frames = _create_frames()
		sprite.play("float")

func _process(delta: float) -> void:
	_float_timer += delta
	position.y += sin(_float_timer * 1.5) * 0.3

func on_interact() -> void:
	if _is_interacted:
		DialogueManager.start_lines(["..."], "")
		return
	# 대화 시작
	var data := _get_data()
	var lines: Array[String] = []
	for line in data.get("lines", []):
		lines.append(str(line))
	DialogueManager.start_lines(lines, data.get("display_name", ""))
	DialogueManager.dialogue_end.connect(_on_dialogue_done, CONNECT_ONE_SHOT)

func _on_dialogue_done() -> void:
	_is_interacted = true
	GameState.complete_event("thought_done_" + thought_id)
	# 크기 축소 + 옆으로 이동
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.45, 0.45), 1.2)
	tween.parallel().tween_property(self, "position:x", position.x + 40.0, 1.2)
	tween.parallel().tween_property(self, "modulate:a", 0.5, 1.2)
	SaveManager.auto_save()

func _get_data() -> Dictionary:
	var f := FileAccess.open("res://data/dialogues.json", FileAccess.READ)
	if not f:
		return {}
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		f.close()
		return {}
	f.close()
	var thoughts: Array = json.data.get("negative_thoughts", [])
	for t in thoughts:
		if t.get("id", "") == thought_id:
			return t
	return {}

func _create_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("float")
	frames.set_animation_loop("float", true)
	frames.set_animation_speed("float", 3.0)
	for i in range(4):
		var img := Image.create(14, 14, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		var alpha := 0.55 + float(i % 2) * 0.1
		for y in range(14):
			for x in range(14):
				var dx := float(x - 6.5)
				var dy := float(y - 6.5)
				if dx * dx + dy * dy <= 36.0:
					img.set_pixel(x, y, Color(0.1, 0.1, 0.15, alpha))
		frames.add_frame("float", ImageTexture.create_from_image(img))
	return frames
