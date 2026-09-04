import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'utils/constants.dart';

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          hintStyle: const TextStyle(color: AppColors.muted),
          prefixIconColor: AppColors.muted,
          suffixIconColor: AppColors.muted,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.surfaceRaised),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        useMaterial3: true,
      ),
      home: const _SessionGate(),
    );
  }
}

class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  final _authService = AuthService();
  late final Future<AuthSession?> _savedSession;

  @override
  void initState() {
    super.initState();
    _savedSession = _authService.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthSession?>(
      future: _savedSession,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final session = snapshot.data;
        if (session == null) return const LoginScreen();
        return DashboardScreen(
          username: session.username,
          deviceId: session.deviceId,
          session: session.session,
        );
      },
    );
  }
}
