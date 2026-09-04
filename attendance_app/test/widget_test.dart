import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_attendance_app/screens/login_screen.dart';
import 'package:qr_attendance_app/services/wifi_service.dart';

void main() {
  testWidgets('shows the attendance login screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  test('normalizes BSSIDs before attendance submission', () {
    final wifiService = WifiService();

    expect(
        wifiService.normalizeBssid('aa-bb-cc-11-22-33'), 'AA:BB:CC:11:22:33');
    expect(
        wifiService.normalizeBssid(' aa:bb:cc:11:22:33 '), 'AA:BB:CC:11:22:33');
  });
}
