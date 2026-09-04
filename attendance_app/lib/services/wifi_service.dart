class WifiService {
  /// Converts supported BSSID spellings to the canonical Sheet format.
  ///
  /// For example, both `aa-bb-cc-11-22-33` and `aa:bb:cc:11:22:33` become
  /// `AA:BB:CC:11:22:33` before the app submits the value to Apps Script.
  String? normalizeBssid(String? value) {
    final normalized = value?.trim().toUpperCase().replaceAll('-', ':');
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
