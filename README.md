# Desktop Cat App

화면 절전 방지 기능을 귀여운 데스크톱 고양이 행동으로 표현하는 Flutter 데스크톱 앱입니다.

## 실행

```bash
flutter create --platforms=macos,windows .
flutter pub get
flutter run -d macos
# 또는
flutter run -d windows
```

`flutter create`가 데스크톱 runner 파일을 만든 뒤, `native/README.md` 안내에 따라 OS API 채널 파일을 runner에 연결해 주세요. 이 저장본에는 앱의 Flutter 코드와 네이티브 채널 구현 원본이 포함되어 있습니다.

## 이미지 넣는 위치

`assets/characters/cat/` 폴더에 아래 파일을 넣어 주세요.

```text
sleep_01.png
sleep_02.png
stretch_01.png
stretch_02.png
walk_01.png
walk_02.png
walk_03.png
walk_04.png
sit.png
yawn.png
manifest.json
```

이미지가 아직 없어도 개발 중에는 파일명 텍스트가 있는 placeholder가 표시됩니다.

## 빌드

```bash
flutter build macos --release
flutter build windows --release
```
