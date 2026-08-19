# 〈오늘의 한 음〉

> "하나씩 찾다 보니, 어느새 음악이 되었다."

웹 브라우저에서 실행 가능한 Godot 4 GDScript 2D RPG 게임입니다.

---

## 📋 요구사항

| 항목 | 버전 |
|------|------|
| Godot Engine | **4.4 이상** (4.7.2 권장) |
| 언어 | GDScript 전용 |
| 렌더러 | Compatibility (GL Compatibility) |
| 타겟 플랫폼 | 웹 브라우저 (WebGL 2.0) |

---

## 🚀 프로젝트 실행 방법

### 1. Godot 에디터에서 열기

1. [Godot Engine 다운로드](https://godotengine.org/download) 페이지에서 **4.4 이상** 버전 다운로드
2. Godot 실행 → **Import** 클릭
3. 이 디렉터리의 `project.godot` 파일 선택
4. **F5** 또는 **Run** 버튼으로 게임 시작

### 2. 게임 아이콘 생성 (선택 사항)

아이콘이 없는 경우 Godot 에디터에서:
1. `assets/ui/generate_icon.gd` 파일을 Script Editor에서 열기
2. 상단 **Run** (▶) 버튼 클릭
3. `assets/ui/icon.png` 생성 확인

---

## 🌐 웹 내보내기 방법

### 전제 조건

웹 내보내기 템플릿이 필요합니다:
1. Godot 에디터 → **Editor** → **Manage Export Templates**
2. **Download and Install** 클릭 (현재 버전의 Web 템플릿 설치)

### 내보내기 실행

```bash
# 커맨드라인으로 내보내기 (Godot 실행 파일 경로를 실제 경로로 변경)
godot --headless --export-release "Web" ./build/web/index.html
```

또는 에디터에서:
1. **Project** → **Export**
2. **Add...** → **Web** 선택
3. Export Path: `./build/web/index.html`
4. **Export Project** 클릭

### 웹 빌드 테스트

로컬 HTTP 서버가 필요합니다 (더블클릭으로는 실행 불가):

```bash
# Python 3
cd build/web
python -m http.server 8080

# 또는 Node.js
npx serve build/web -p 8080
```

브라우저에서 `http://localhost:8080` 접속

---

## 🎮 조작 방법

| 키 | 기능 |
|----|------|
| 방향키 / WASD | 이동 |
| E / Space / Enter | 조사 및 대화 |
| I | 인벤토리 |
| M | 전체 지도 |
| Tab | 악보 (음표 수집 후 해제) |
| Esc | 메뉴 (저장/불러오기/설정) |

---

## 🗺️ 지역 구성

| 지역 | 해제 조건 | 주요 요소 |
|------|----------|----------|
| 잿빛 숲 | 시작 | 첫 악보, 음표 01~02 |
| 작은 마을 | 음표 2개 | NPC 2명, 음표 03~04 |
| 비의 호수 | 음표 4개 | 발판 퍼즐, 음표 05 |
| 기억의 정원 | 음표 5개 | 사진 퍼즐, 음표 06~07 |
| 오래된 극장 | 음표 6개 | 소리 퍼즐, 음표 08 |
| 새벽의 언덕 | 음표 8개 | 최종 보스, 음표 09 |

---

## 🎵 음악 시스템

이 게임은 외부 오디오 파일 없이 **절차적 사운드 합성**으로 동작합니다.

- `AudioStreamWAV`를 GDScript로 직접 생성
- 캉캉(Cancan) 멜로디 기반 음정 배열 사용
- 진행 단계별로 음정이 하나씩 추가되는 방식

### 선택 사항: 실제 OGG 파일 배치

더 풍부한 음악을 원한다면 `audio/bgm/` 폴더에 다음 파일을 배치:

```
audio/bgm/
├── music_stage_00.ogg   # 거의 무음
├── music_stage_01.ogg   # 단음 추가
├── music_stage_03.ogg   # 짧은 멜로디
├── music_stage_05.ogg   # 반주 추가
├── music_stage_07.ogg   # 방향이 명확한 멜로디
├── music_stage_08.ogg   # 완성 직전
└── cancan_final.ogg     # 캉캉 전체 연주
```

**주의**: 자크 오펜바흐의 캉캉은 저작권이 만료된 곡이지만, 상업용 녹음은 별도 저작권이 있을 수 있습니다. 다음 소스의 무료 음원 사용을 권장합니다:
- [Musopen](https://musopen.org) — 저작권 프리 클래식 음악
- [Free Music Archive](https://freemusicarchive.org)
- 직접 제작한 MIDI → OGG 변환본

---

## 📁 프로젝트 구조

```
happy/
├── project.godot              # Godot 프로젝트 설정
├── scenes/
│   ├── main/                  # 타이틀·메인게임 씬
│   ├── regions/               # 6개 지역 씬
│   ├── actors/                # NPC·그림자 씬
│   ├── objects/               # 아이템·음표·출구 씬
│   ├── encounters/            # 부정적 생각·의심 보스
│   ├── ui/                    # UI 씬
│   └── ending/                # 캉캉 엔딩 씬
├── scripts/
│   ├── autoload/              # Autoload 싱글톤 9개
│   ├── player/
│   ├── world/                 # BaseRegion + 6개 지역
│   ├── actors/
│   ├── objects/
│   ├── encounters/
│   ├── ui/
│   ├── main/
│   └── ending/
├── resources/
│   ├── ItemData.gd            # 아이템 리소스 클래스
│   └── NPCData.gd             # NPC 리소스 클래스
├── data/
│   ├── items.json             # 9개 아이템 데이터
│   ├── dialogues.json         # NPC·오브젝트 대사 데이터
│   └── default_settings.json
├── audio/
│   └── default_bus_layout.tres
└── assets/
    └── ui/
        └── icon.png
```

---

## ⚙️ 웹 내보내기 설정 참고

`project.godot`에 이미 포함된 권장 설정:

- **Renderer**: GL Compatibility
- **Viewport**: 640×360
- **Stretch Mode**: canvas_items
- **Stretch Aspect**: keep
- **Single Thread**: 별도 교차 출처 격리 헤더 불필요

---

## 📜 에셋 및 라이선스

| 에셋 | 출처 | 라이선스 |
|------|------|--------|
| 캐릭터·타일·UI | 절차적 GDScript 생성 | 자체 제작 |
| 캉캉 멜로디 | 자크 오펜바흐 (1819-1880) | 저작권 만료 (Public Domain) |
| Godot Engine | godotengine.org | MIT License |

---

## 🔧 알려진 주의사항

1. **한국어 폰트**: 웹 빌드 시 시스템 기본 폰트가 한글을 지원해야 합니다. 폰트가 깨질 경우 `assets/fonts/` 폴더에 한국어 지원 폰트를 추가하고 ThemeOverride 설정을 업데이트하세요.

2. **저장 데이터 (웹)**: 브라우저 시크릿 모드 또는 스토리지 차단 설정 시 저장이 유지되지 않을 수 있습니다.

3. **오디오 (웹)**: 브라우저 정책에 따라 첫 사용자 입력(클릭) 후에만 소리가 재생됩니다. 이미 시작 화면에서 처리되어 있습니다.

4. **TileMapLayer 타일셋**: 현재 TileMapLayer는 빈 상태입니다. Godot 에디터에서 TileSet을 생성하여 지역별 타일을 배치해야 합니다. 스크립트 동작과 충돌 처리는 코드로 구현되어 있습니다.

---

*〈오늘의 한 음〉— "내가 변하고 있다는 것을 스스로는 알아차리지 못하지만, 어느 순간 돌아보니 나는 이미 달라져 있었다."*
