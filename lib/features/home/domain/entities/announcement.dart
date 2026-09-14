import 'package:equatable/equatable.dart';

/// Represents a passenger-facing announcement or special offer banner.
class Announcement extends Equatable {
  final String id;
  final String titleAr;
  final String? titleEn;
  final String descriptionAr;
  final String? descriptionEn;
  final String type; // 'announcement' or 'offer'
  final int sortOrder;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const Announcement({
    required this.id,
    required this.titleAr,
    this.titleEn,
    required this.descriptionAr,
    this.descriptionEn,
    this.type = 'announcement',
    this.sortOrder = 0,
    this.startsAt,
    this.endsAt,
  });

  bool get isOffer => type == 'offer';

  String localizedTitle(String locale) {
    if (locale == 'en' && titleEn != null && titleEn!.trim().isNotEmpty) {
      return titleEn!;
    }
    return titleAr;
  }

  String localizedDescription(String locale) {
    if (locale == 'en' && descriptionEn != null && descriptionEn!.trim().isNotEmpty) {
      return descriptionEn!;
    }
    return descriptionAr;
  }

  @override
  List<Object?> get props => [
        id,
        titleAr,
        titleEn,
        descriptionAr,
        descriptionEn,
        type,
        sortOrder,
        startsAt,
        endsAt,
      ];
}
