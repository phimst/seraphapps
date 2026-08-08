import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import 'storage_service.dart';

/// Single source of truth buat settings, dipakai di seluruh app lewat
/// ListenableBuilder (bawaan Flutter, gak perlu package `provider`).
class SettingsController extends ChangeNotifier {
  SettingsController._();
  static final SettingsController instance = SettingsController._();

  AppSettings settings = AppSettings();
  bool loaded = false;

  Future<void> load() async {
    final json = await StorageService.loadSettings();
    settings = AppSettings.fromJson(json);
    loaded = true;
    notifyListeners();
  }

  Future<void> save() async {
    await StorageService.saveSettings(settings.toJson());
    notifyListeners();
  }
}
