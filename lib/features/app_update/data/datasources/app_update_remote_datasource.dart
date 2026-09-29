import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_update_info_model.dart';

abstract class AppUpdateRemoteDataSource {
  Future<AppUpdateInfoModel> getAppUpdateStatus({
    String? appKey,
    String? platform,
    int? currentBuild,
    String? currentVersion,
  });
}

@LazySingleton(as: AppUpdateRemoteDataSource)
class AppUpdateRemoteDataSourceImpl implements AppUpdateRemoteDataSource {
  final SupabaseClient _supabase;

  AppUpdateRemoteDataSourceImpl(this._supabase);

  @override
  Future<AppUpdateInfoModel> getAppUpdateStatus({
    String? appKey,
    String? platform,
    int? currentBuild,
    String? currentVersion,
  }) async {
    final effectiveAppKey = appKey ?? 'passenger';
    final effectivePlatform = platform ?? _detectPlatform();

    final PackageInfo? packageInfo;
    if (currentBuild == null || currentVersion == null) {
      packageInfo = await _getPackageInfoSafe();
    } else {
      packageInfo = null;
    }

    final effectiveBuild = currentBuild ??
        (packageInfo != null ? int.tryParse(packageInfo.buildNumber) ?? 0 : 0);
    final effectiveVersion = currentVersion ??
        (packageInfo != null && packageInfo.version.isNotEmpty
            ? packageInfo.version
            : '1.0.0');

    final response = await _supabase.rpc(
      'get_app_update_status',
      params: {
        'p_app_key': effectiveAppKey,
        'p_platform': effectivePlatform,
        'p_current_build': effectiveBuild,
        'p_current_version': effectiveVersion,
      },
    );

    if (response == null) {
      return const AppUpdateInfoModel(
        updateAvailable: false,
        forceUpdate: false,
      );
    }

    final Map<String, dynamic> data;
    if (response is Map) {
      data = Map<String, dynamic>.from(response);
    } else if (response is List && response.isNotEmpty) {
      final first = response.first;
      data = first is Map ? Map<String, dynamic>.from(first) : {};
    } else if (response is String) {
      final decoded = jsonDecode(response);
      data = decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } else {
      return const AppUpdateInfoModel(
        updateAvailable: false,
        forceUpdate: false,
      );
    }

    return AppUpdateInfoModel.fromJson(data);
  }

  String _detectPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    return 'android';
  }

  Future<PackageInfo?> _getPackageInfoSafe() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      return null;
    }
  }
}
