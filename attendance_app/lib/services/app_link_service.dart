import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppLinkService {
  AppLinkService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _appLinkKey = 'attendance_app_link';
  final FlutterSecureStorage _storage;

  Future<String?> readAppLink() async {
    final value = await _storage.read(key: _appLinkKey);
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> saveAppLink(String appLink) {
    return _storage.write(key: _appLinkKey, value: appLink);
  }

  static String? normaliseAppLink(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return null;
    }

    // Apps Script production deployments use /exec, not the editor-only /dev URL.
    if (!uri.path.endsWith('/exec')) {
      return null;
    }
    return uri.toString();
  }
}
