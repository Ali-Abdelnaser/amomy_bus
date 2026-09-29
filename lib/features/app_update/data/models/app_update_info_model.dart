import '../../domain/entities/app_update_info.dart';

class AppUpdateInfoModel extends AppUpdateInfo {
  const AppUpdateInfoModel({
    required super.updateAvailable,
    required super.forceUpdate,
    super.latestVersion,
    super.latestBuild,
    super.storeUrl,
    super.message,
  });

  factory AppUpdateInfoModel.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfoModel(
      updateAvailable: json['update_available'] as bool? ??
          json['is_update_available'] as bool? ??
          false,
      forceUpdate: json['force_update'] as bool? ??
          json['is_force_update'] as bool? ??
          false,
      latestVersion: json['latest_version']?.toString() ??
          json['version']?.toString() ??
          json['target_version']?.toString(),
      latestBuild: json['latest_build'] != null
          ? int.tryParse(json['latest_build'].toString())
          : (json['build_number'] != null
              ? int.tryParse(json['build_number'].toString())
              : null),
      storeUrl: json['store_url']?.toString() ??
          json['url']?.toString() ??
          json['app_url']?.toString(),
      message: json['message']?.toString() ??
          json['release_notes']?.toString() ??
          json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'update_available': updateAvailable,
      'force_update': forceUpdate,
      if (latestVersion != null) 'latest_version': latestVersion,
      if (latestBuild != null) 'latest_build': latestBuild,
      if (storeUrl != null) 'store_url': storeUrl,
      if (message != null) 'message': message,
    };
  }
}
