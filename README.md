# dotdotdot_chat

요청하신 스펙 기준으로 생성한 Flutter 실시간 채팅 앱입니다.

## 구현 범위
- Splash + Login (다크 테마, 닉네임 10자 제한)
- 엔터 입력 시 입장 확인 팝업(Yes/No)
- Room 1 ~ Room 5 로비
- Socket.io 실시간 채팅
- 좌/우 말풍선 + 닉네임 표시
- 채팅방 풀스크린(상태바 숨김)
- 타이핑 인디케이터(...) 애니메이션
- 입력창 포커스 시 키보드 뷰 시프팅
- 나가기 시 클라이언트 로그 즉시 초기화

## 경로
`/Volumes/MacBook-Dev/Project/app/dotdotdot_chat`

## 실행 방법
### 1) 소켓 서버 실행
```bash
cd /Volumes/MacBook-Dev/Project/app/dotdotdot_chat/server
npm install --cache ./.npm-cache
npm start
```
기본 포트: `3001`

### 2) Flutter 앱 실행
```bash
cd /Volumes/MacBook-Dev/Project/app/dotdotdot_chat
flutter pub get
flutter run
```

## 연결 주소
- iOS/macOS: `https://dotdotdot.onrender.com`
- Android Emulator: `https://dotdotdot.onrender.com`

(코드 위치: `lib/main.dart` 의 `_socketUrl` getter)

## 로고 파일
현재 로고는 아래 파일로 연결되어 있음:
- `assets/images/logo.jpg`

배경제거(투명 PNG) 버전이 준비되면 파일명만 `logo.png`로 교체하고
`pubspec.yaml`/`main.dart`에서 경로만 바꾸면 됩니다.
