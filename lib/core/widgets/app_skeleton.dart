import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Shimmer skeleton loading container using Skeletonizer for full widget trees.
class AppSkeleton extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final bool ignoreContainers;

  const AppSkeleton({
    super.key,
    required this.isLoading,
    required this.child,
    this.ignoreContainers = false,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: isLoading,
      ignoreContainers: ignoreContainers,
      child: child,
    );
  }
}

/// Standalone rectangular or rounded bone shimmer placeholder for rapid skeleton mockups.
class AppSkeletonBone extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const AppSkeletonBone({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: borderRadius ?? AppRadius.radiusSm,
      ),
    );
  }
}
