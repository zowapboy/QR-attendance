import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceService {
  DeviceService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _deviceIdKey = 'attendance_device_id';
  final FlutterSecureStorage _storage;

  Future<String?> getSavedDeviceId() => _storage.read(key: _deviceIdKey);

  Future<String> getDeviceId() async {
    final savedId = await getSavedDeviceId();
    if (savedId != null && savedId.isNotEmpty) {
      return savedId;
    }

    final random = Random.secure();
    final id = List<String>.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final deviceId = 'app-$id';
    await _storage.write(key: _deviceIdKey, value: deviceId);
    return deviceId;
  }
}
