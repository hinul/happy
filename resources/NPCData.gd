class_name NPCData
extends Resource

## NPC 고유 ID
@export var id: String = ""

## 화면에 표시되는 이름
@export var display_name: String = ""

## NPC 초상화 텍스처 (대화창 옆에 표시)
@export var portrait: Texture2D

## 지역 ID
@export var region_id: String = ""

## 진행 단계 0~1 (초반) 대사 목록
@export var dialogue_early: Array[String] = []

## 진행 단계 2~3 (중반) 대사 목록
@export var dialogue_middle: Array[String] = []

## 진행 단계 4~6 (후반) 대사 목록
@export var dialogue_late: Array[String] = []

## 진행 단계 7~9 (마지막) 대사 목록
@export var dialogue_final: Array[String] = []

## 전체 지도에 이벤트 아이콘을 표시할지 여부
@export var map_icon_enabled: bool = true

## 특정 이벤트 완료 조건 (이 이벤트들이 모두 완료되어야 final 대사 사용)
@export var required_events: Array[String] = []

## 엔딩 군무에서 사용할 댄스 타입
## "high_kick", "side_step", "spin", "late_join", "wrong_direction", "stay_center"
@export var dance_type: String = "side_step"

## 엔딩에서 등장하는 순서 (낮을수록 먼저 등장)
@export var ending_order: int = 99
