class_name ItemData
extends Resource

## 아이템 고유 ID (저장 데이터 키로 사용)
@export var id: String = ""

## 화면에 표시되는 이름
@export var display_name: String = ""

## 획득 시 표시되는 짧은 설명 (1~2문장)
@export_multiline var description: String = ""

## 인벤토리 아이콘 텍스처
@export var icon: Texture2D

## 이 아이템이 속한 지역 ID
@export var region_id: String = ""

## 이 아이템 획득으로 해제되는 음표 ID
@export var linked_note_id: String = ""

## 최종 보스(의심)에게 사용할 때 출력되는 보스 반응
@export_multiline var boss_response: String = ""

## 부정적인 생각(그림자 몬스터)에 사용할 때 반응
## 키: 생각 ID, 값: 반응 문장
@export var thought_responses: Dictionary = {}

## 사용 가능 여부 (보스/생각 이벤트에서)
@export var usable_in_encounter: bool = true
