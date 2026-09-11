import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StorageService {
  Future<bool> setString(String key, String value);
  String? getString(String key);
  Future<bool> setBool(String key, bool value);
  bool? getBool(String key);
  Future<bool> setInt(String key, int value);
  int? getInt(String key);
  Future<bool> remove(String key);
  Future<bool> clear();
}

@LazySingleton(as: StorageService)
class SharedPreferencesStorageService implements StorageService {
  final SharedPreferences _preferences;

  SharedPreferencesStorageService(this._preferences);

  @override
  Future<bool> setString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  String? getString(String key) => _preferences.getString(key);

  @override
  Future<bool> setBool(String key, bool value) =>
      _preferences.setBool(key, value);

  @override
  bool? getBool(String key) => _preferences.getBool(key);

  @override
  Future<bool> setInt(String key, int value) => _preferences.setInt(key, value);

  @override
  int? getInt(String key) => _preferences.getInt(key);

  @override
  Future<bool> remove(String key) => _preferences.remove(key);

  @override
  Future<bool> clear() => _preferences.clear();
}
