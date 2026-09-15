# 랜덤픽 (RandomPick)

PLAY YOUR NEXT WORLD의 두 번째 앱. 룰렛 / 사다리타기 / 팀나누기를 제공하는
가벼운 유틸 앱 (v1.0, 로그인/서버/DB 없음).

- Flutter 패키지명: `random_pick`
- 제안 Android applicationId: `com.pyworld.randompick` (필요 시 변경 가능)

## 현재 상태 (이번 세션까지)

- [x] `pubspec.yaml` / 폴더 구조 설계
- [x] 홈 화면(모드 선택 3개 버튼) UI
- [ ] 룰렛 로직
- [ ] 사다리타기 로직
- [ ] 팀나누기 로직
- [ ] 전면광고 SDK 연동

## 폴더 구조

```
lib/
  main.dart              # 앱 진입점, MaterialApp 설정
  screens/
    home_screen.dart      # 홈: 모드 선택 3버튼 (구현 완료)
    input_screen.dart     # 입력: 모드별 항목/인원 입력 (스텁)
    result_screen.dart    # 결과: 모드별 결과 표시 (스텁, 전면광고 자리 예정)
  widgets/
    mode_button.dart       # 홈 화면 모드 선택 카드 버튼
  models/
    game_mode.dart          # GameMode enum (roulette/ladder/team)
  theme/
    app_theme.dart          # 브랜드 톤 ThemeData
```

## 로컬에서 실행하기

이 저장소는 Flutter SDK 없이 소스만 작성된 상태입니다. 플랫폼 폴더
(`android/`, `ios/` 등)는 아직 생성되지 않았습니다.

1. [Flutter SDK](https://docs.flutter.dev/get-started/install)를 설치하고
   `flutter doctor`로 설치를 확인합니다.
2. 프로젝트 루트(`D:\Projects\random-pick-app`)에서 아래 명령을 실행합니다.
   `flutter create .`는 기존 `pubspec.yaml`/`lib/`를 건드리지 않고
   누락된 `android/`, `ios/` 등 플랫폼 폴더만 채워 넣습니다.

   ```
   flutter create --org com.pyworld --project-name random_pick .
   flutter pub get
   flutter run
   ```

## 다음 단계 제안

1. Flutter SDK 설치 후 위 명령으로 플랫폼 폴더 생성 및 실행 확인
2. 입력 화면(`input_screen.dart`) UI: 모드별 항목/인원 입력 폼
3. 룰렛/사다리타기/팀나누기 핵심 로직 구현 및 결과 화면 연결
4. 결과 화면에 전면광고 Placeholder 배치
5. 앱 아이콘/스플래시, Google Play 출시 메타데이터 준비
