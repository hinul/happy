## generate_icon.gd
## 도구 스크립트: Godot 에디터에서 실행하여 기본 아이콘 생성
## 사용법: Godot 에디터 > Script > 이 파일 열기 > 실행
@tool
extends EditorScript

func _run() -> void:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.05, 0.05, 0.08, 1.0))
	# 음표 그리기 (큰 버전)
	var note_color := Color(0.95, 0.90, 0.60, 1.0)
	# 음표 머리 (타원)
	for y in range(80, 110):
		for x in range(30, 85):
			var dx := float(x - 57.5) / 27.5
			var dy := float(y - 95.0) / 15.0
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, note_color)
	# 음표 기둥
	for y in range(20, 82):
		for x in range(80, 88):
			img.set_pixel(x, y, note_color)
	# 음표 깃발
	for i in range(20):
		var x := 87 + int(float(i) * 0.8)
		var y := 22 + int(float(i) * 1.2)
		if x < 128 and y < 128:
			img.set_pixel(x, y, note_color)
	img.save_png("res://assets/ui/icon.png")
	print("[GenerateIcon] icon.png 생성 완료")
