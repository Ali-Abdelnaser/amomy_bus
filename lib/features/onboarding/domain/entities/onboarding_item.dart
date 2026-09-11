import 'package:equatable/equatable.dart';

class OnboardingItem extends Equatable {
  final String imageAsset;
  final String title;
  final String subtitle;

  const OnboardingItem({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
  });

  @override
  List<Object?> get props => [imageAsset, title, subtitle];
}
