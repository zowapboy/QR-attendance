import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_service.dart';
import 'device_service.dart';

class AuthSession {
  const AuthSession({
    required this.username,
    required this.deviceId,
    this.session,
  });

  final String username;
  final String deviceId;
  final String? session;
}

class AuthService {
  AuthService({
    ApiService? apiService,
    DeviceService? deviceService,
    FlutterSecureStorage? storage,
  })  : _apiService = apiService ?? ApiService(),
        _deviceService = deviceService ?? DeviceService(),
        _storage = storage ?? const FlutterSecureStorage();

  static const _usernameKey = 'attendance_username';
  static const _sessionKey = 'attendance_session';

  final ApiService _apiService;
  final DeviceService _deviceService;
  final FlutterSecureStorage _storage;

  Future<AuthSession> signIn({
    required String username,
    required String pin,
  }) async {
    final deviceId = await _deviceService.getDeviceId();
    final response = await _apiService.login(
      username: username,
      pin: pin,
      deviceId: deviceId,
    );

    if (response['success'] != true) {
      throw ApiException(
        response['message']?.toString() ?? 'Invalid account or device',
      );
    }

    final session = response['session_token']?.toString();
    await _storage.write(key: _usernameKey, value: username);
    if (session != null && session.isNotEmpty) {
      await _storage.write(key: _sessionKey, value: session);
    }

    return AuthSession(
        username: username, deviceId: deviceId, session: session);
  }

  Future<AuthSession?> restoreSession() async {
    try {
      final username = await _storage.read(key: _usernameKey);
      final session = await _storage.read(key: _sessionKey);
      final deviceId = await _deviceService.getSavedDeviceId();
      if (username == null ||
          username.isEmpty ||
          session == null ||
          session.isEmpty ||
          deviceId == null ||
          deviceId.isEmpty) {
        return null;
      }
      return AuthSession(
        username: username,
        deviceId: deviceId,
        session: session,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _sessionKey);
  }
}
