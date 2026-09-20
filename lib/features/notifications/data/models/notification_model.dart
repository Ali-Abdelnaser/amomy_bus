import '../../domain/entities/app_notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.titleAr,
    required super.bodyAr,
    required super.titleEn,
    required super.bodyEn,
    super.data,
    super.entityType,
    super.entityId,
    super.dedupeKey,
    super.readAt,
    required super.createdAt,
    super.expiresAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String?),
      titleAr: json['title_ar'] as String? ?? '',
      bodyAr: json['body_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      bodyEn: json['body_en'] as String? ?? '',
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : (json['data'] is Map
                ? Map<String, dynamic>.from(json['data'] as Map)
                : {}),
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      dedupeKey: json['dedupe_key'] as String?,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.toDbString(),
      'title_ar': titleAr,
      'body_ar': bodyAr,
      'title_en': titleEn,
      'body_en': bodyEn,
      'data': data,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (dedupeKey != null) 'dedupe_key': dedupeKey,
      if (readAt != null) 'read_at': readAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    };
  }
}
