import 'package:dotdotdot_chat/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('앱 기본 렌더링 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(const DotDotDotApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('닉네임을 입력해주세요'), findsOneWidget);
  });
}
