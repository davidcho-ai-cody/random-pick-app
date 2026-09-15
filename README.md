# 랜덤픽 (RandomPick)

PLAY YOUR NEXT WORLD의 두 번째 앱. 룰렛 / 사다리타기 / 팀나누기를 제공하는
가벼운 유틸 앱 (v1.0, 로그인/서버/DB 없음).

- Flutter 패키지명: `random_pick`
- 제안 Android applicationId: `com.pyworld.randompick` (필요 시 변경 가능)

## 현재 상태

- [x] `pubspec.yaml` / 폴더 구조 설계
- [x] 홈 화면(모드 선택 3개 버튼) UI
- [x] 룰렛 로직 (회전 애니메이션 + 시인성 좋은 포인터)
- [x] 사다리타기 로직 (밀도 있는 사다리 + 경로 애니메이션)
- [x] 팀나누기 로직 (라운드로빈 순차 공개 연출)
- [x] 전면광고 SDK 연동 (`google_mobile_ads`, 결과 화면에서 "홈으로" 이동 시 노출)
  - 현재는 구글 공식 테스트 광고 단위 ID 사용 중. 실제 출시 전
    [lib/services/ad_service.dart](lib/services/ad_service.dart)의 ID와
    Android/iOS 매니페스트의 App ID를 AdMob 콘솔에서 발급받은 값으로 교체할 것.

## 폴더 구조

```
lib/
  main.dart                  # 앱 진입점, MobileAds 초기화, MaterialApp 설정
  screens/
    home_screen.dart          # 홈: 모드 선택 3버튼
    roulette_input/result_screen.dart
    ladder_input/result_screen.dart
    team_input/result_screen.dart
  widgets/
    mode_button.dart, roulette_wheel.dart, ladder_painter.dart
  models/
    game_mode.dart, ladder_board.dart, team_split.dart
  services/
    ad_service.dart          # 전면광고 로드/노출
  theme/
    app_theme.dart            # 브랜드 톤 ThemeData
```

## 로컬에서 실행하기

```
flutter pub get
flutter run
```

`.claude/launch.json`에 웹 프리뷰용 설정(`flutter run -d web-server`)도 등록되어 있다.

## 다음 단계 제안

1. AdMob 콘솔에서 실제 앱 등록 + 전면광고 단위 ID 발급 후
   [lib/services/ad_service.dart](lib/services/ad_service.dart)와
   `android/app/src/main/AndroidManifest.xml` / `ios/Runner/Info.plist`의
   테스트 ID를 실제 ID로 교체
2. 앱 아이콘/스플래시, Google Play 출시 메타데이터 준비
3. 실기기/에뮬레이터에서 전면광고가 정상적으로 뜨는지 확인
