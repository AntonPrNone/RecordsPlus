// ignore_for_file: file_names

import 'package:records_plus/Services/UserService.dart';

class SettingsCustom {
  static SortType? currentSortType;
  static bool? currentAscending;

  static Future<void> getSortSettings() async {
    Map<String, dynamic> sortSettings = await UserService().getSortSettings();
    currentSortType = SortType.values[sortSettings['currentSortType'] ?? 0];
    currentAscending = sortSettings['currentAscending'] ?? true;
  }
}
