import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_link_service.dart';
import 'wifi_service.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({
    http.Client? client,
    WifiService? wifiService,
    AppLinkService? appLinkService,
  })  : _client = client ?? http.Client(),
        _wifiService = wifiService ?? WifiService(),
        _appLinkService = appLinkService ?? AppLinkService();

  final http.Client _client;
  final WifiService _wifiService;
  final AppLinkService _appLinkService;

  Future<Map<String, dynamic>> health(String appLink) {
    return _post({'action': 'health'}, appLink: appLink);
  }

  /// Confirms the endpoint exposes the public health action before storing it.
  Future<void> validateAppLink(String appLink) async {
    final response = await health(appLink);
    if (response['success'] != true || response['app'] != 'qr-attendance') {
      throw const ApiException('This attendance app link is not ready yet.');
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String pin,
    required String deviceId,
  }) {
    return _post({
      'action': 'login',
      'username': username,
      'pin': pin,
      'device_id': deviceId,
    });
  }

  Future<Map<String, dynamic>> getDashboard({
    required String username,
    required String deviceId,
    String? session,
  }) {
    return _post({
      'action': 'getDashboard',
      'username': username,
      'device_id': deviceId,
      if (session != null && session.isNotEmpty) 'session_token': session,
    });
  }

  Future<Map<String, dynamic>> submitAttendance({
    required String username,
    required String deviceId,
    required String session,
    required String qrData,
    required String? bssid,
  }) {
    return _post({
      'action': 'submitAttendance',
      'username': username,
      'device_id': deviceId,
      'session_token': session,
      'qr_data': qrData,
      'bssid': _wifiService.normalizeBssid(bssid) ?? '',
    });
  }

  Future<Map<String, dynamic>> _post(
    Map<String, dynamic> body, {
    String? appLink,
  }) async {
    try {
      final target = appLink ?? await _appLinkService.readAppLink();
      if (target == null || target.isEmpty) {
        throw const ApiException('Enter the attendance app link first.');
      }
      var response = await _client
          .post(
            Uri.parse(target),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      // Apps Script returns a 302 to a script.googleusercontent.com URL.
      // package:http exposes that empty redirect response instead of following
      // it, so load the final JSON response explicitly.
      for (var redirect = 0;
          redirect < 3 && _isRedirect(response.statusCode);
          redirect++) {
        final location = response.headers['location'];
        if (location == null || location.isEmpty) break;
        final redirectUri = Uri.parse(target).resolve(location);
        if (!redirectUri.isScheme('https')) {
          throw const ApiException(
              'Unexpected response from the attendance server.');
        }
        response = await _client.get(
          redirectUri,
          headers: const {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 20));
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const ApiException(
            'Unexpected response from the attendance server.');
      }

      final data = Map<String, dynamic>.from(decoded);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          data['message']?.toString() ?? 'Unable to connect. Please try again.',
        );
      }
      return data;
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException(
          'Unexpected response from the attendance server.');
    } catch (_) {
      throw const ApiException('Unable to connect. Please try again.');
    }
  }

  bool _isRedirect(int statusCode) =>
      statusCode == 301 ||
      statusCode == 302 ||
      statusCode == 303 ||
      statusCode == 307 ||
      statusCode == 308;
}
