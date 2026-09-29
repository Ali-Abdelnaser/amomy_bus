import 'package:equatable/equatable.dart';

class AppUpdateInfo extends Equatable {
  final bool updateAvailable;
  final bool forceUpdate;
  final String? latestVersion;
  final int? latestBuild;
  final String? storeUrl;
  final String? message;

  const AppUpdateInfo({
    required this.updateAvailable,
    required this.forceUpdate,
    this.latestVersion,
    this.latestBuild,
    this.storeUrl,
    this.message,
  });

  @override
  List<Object?> get props => [
        updateAvailable,
        forceUpdate,
        latestVersion,
        latestBuild,
        storeUrl,
        message,
      ];
}
