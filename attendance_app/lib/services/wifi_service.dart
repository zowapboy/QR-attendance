import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiService {
  WifiService({NetworkInfo? networkInfo})
      : _networkInfo = networkInfo ?? NetworkInfo();

  final NetworkInfo _networkInfo;

  /// Requests the Android permission required to read a Wi-Fi BSSID, then
  /// returns it in the uppercase colon-separated format expected by the API.
  Future<String?> getCurrentBssid() async {
    final permission = await Permission.locationWhenInUse.request();
    if (!permission.isGranted) return null;

    try {
      return normalizeBssid(await _networkInfo.getWifiBSSID());
    } catch (_) {
      return null;
    }
  }

  /// Converts supported BSSID spellings to the canonical Sheet format.
  ///
  /// For example, both `aa-bb-cc-11-22-33` and `aa:bb:cc:11:22:33` become
  /// `AA:BB:CC:11:22:33` before the app submits the value to Apps Script.
  String? normalizeBssid(String? value) {
    final normalized = value?.trim().toUpperCase().replaceAll('-', ':');
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
