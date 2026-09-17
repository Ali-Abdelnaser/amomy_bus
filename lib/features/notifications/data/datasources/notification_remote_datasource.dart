import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/entities/notification_test_event_result.dart';
import '../../domain/entities/self_test_result.dart';
import '../models/notification_model.dart';
import '../models/notification_preferences_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    int offset = 0,
  });

  Future<int> getUnreadCount();

  Stream<AppNotification?> subscribeToNotificationUpdates();

  Future<bool> markAsRead(String notificationId);

  Future<int> markAllAsRead();

  Future<bool> registerDeviceToken({
    required String token,
    required String platform,
    String? installationId,
    String? deviceName,
    String? appVersion,
  });

  Future<bool> deactivateDeviceToken(String token);

  Future<SelfTestResult> sendSelfTestNotification({int? delaySeconds});

  Future<bool> isNotificationTester();

  Future<NotificationTestEventResult> sendTestEvent({
    required String eventType,
    bool forceDelivery = false,
    Map<String, dynamic>? customData,
    int? delaySeconds,
  });

  Future<NotificationPreferencesModel> getPreferences();

  Future<NotificationPreferencesModel> updatePreferences(
    NotificationPreferences preferences,
  );
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final SupabaseClient _client;

  NotificationRemoteDataSourceImpl({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  String _maskToken(String? token) {
    if (token == null || token.isEmpty) return 'none';
    final len = token.length;
    final suffix = len > 6 ? token.substring(len - 6) : token;
    return 'length: $len, suffix: ...$suffix';
  }

  @override
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          debugPrint('[AMOMY_NOTIF] getNotifications: no authenticated user');
        }
        return [];
      }

      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final list = response as List<dynamic>;
      final notifications = list
          .map(
            (json) => NotificationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      if (kDebugMode) {
        final latest = notifications.isNotEmpty ? notifications.first : null;
        debugPrint(
          '[AMOMY_NOTIF] Inbox refresh completed: count=${notifications.length}, '
          'latest_type=${latest?.type.name ?? "none"}, '
          'latest_created_at=${latest?.createdAt.toIso8601String() ?? "none"}',
        );
      }

      return notifications;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] getNotifications error: $e');
      }
      return [];
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 0;

      final response = await _client.rpc('get_unread_notifications_count');
      int count = 0;
      if (response is int) count = response;
      if (response is num) count = response.toInt();

      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] Unread count: $count');
      }
      return count;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] getUnreadCount error: $e');
      }
      return 0;
    }
  }

  @override
  Stream<AppNotification?> subscribeToNotificationUpdates() {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    late final StreamController<AppNotification?> controller;
    RealtimeChannel? channel;

    controller = StreamController<AppNotification?>.broadcast(
      onListen: () {
        channel = _client.channel(
          'notifications_${identityHashCode(controller)}',
        );
        channel!
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'notifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: user.id,
              ),
              callback: (payload) {
                if (controller.isClosed) return;
                if (payload.eventType == PostgresChangeEvent.insert &&
                    payload.newRecord.isNotEmpty) {
                  controller.add(NotificationModel.fromJson(payload.newRecord));
                  return;
                }
                controller.add(null);
              },
            )
            .subscribe();
      },
      onCancel: () {
        if (channel != null) {
          _client.removeChannel(channel!);
        }
      },
    );

    return controller.stream;
  }

  @override
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _client.rpc(
        'mark_notification_as_read',
        params: {'p_notification_id': notificationId},
      );
      final success = response == true;
      if (kDebugMode) {
        debugPrint(
          '[AMOMY_NOTIF] markAsRead ($notificationId): success=$success',
        );
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] markAsRead error: $e');
      }
      return false;
    }
  }

  @override
  Future<int> markAllAsRead() async {
    try {
      final response = await _client.rpc('mark_all_notifications_as_read');
      int count = 0;
      if (response is int) count = response;
      if (response is num) count = response.toInt();
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] markAllAsRead count: $count');
      }
      return count;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] markAllAsRead error: $e');
      }
      return 0;
    }
  }

  @override
  Future<bool> registerDeviceToken({
    required String token,
    required String platform,
    String? installationId,
    String? deviceName,
    String? appVersion,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[AMOMY_NOTIF] register_device_token RPC called with ${_maskToken(token)}, platform=$platform',
        );
      }

      final response = await _client.rpc(
        'register_device_token',
        params: {
          'p_token': token,
          'p_platform': platform,
          'p_installation_id': installationId,
          'p_device_name': deviceName,
          'p_app_version': appVersion,
        },
      );

      final success = response != null;
      if (kDebugMode) {
        debugPrint(
          '[AMOMY_NOTIF] Token registered in Supabase: ${success ? "success" : "failure"}',
        );
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] Token registered in Supabase error: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> deactivateDeviceToken(String token) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[AMOMY_NOTIF] deactivate_device_token RPC called for ${_maskToken(token)}',
        );
      }
      final response = await _client.rpc(
        'deactivate_device_token',
        params: {'p_token': token},
      );
      return response == true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] deactivateDeviceToken error: $e');
      }
      return false;
    }
  }

  @override
  Future<SelfTestResult> sendSelfTestNotification({int? delaySeconds}) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        if (kDebugMode) {
          debugPrint('[AMOMY_NOTIF] Self-test aborted: no active user session');
        }
        return SelfTestResult.failure('No active authenticated session');
      }

      if (kDebugMode) {
        debugPrint(
          '[AMOMY_NOTIF] Self-test request sent to Edge Function (delay: ${delaySeconds ?? 0}s)...',
        );
      }

      final body = <String, dynamic>{
        'action': 'self_test',
        if (delaySeconds != null && delaySeconds > 0)
          'delay_seconds': delaySeconds,
      };

      final response = await _client.functions.invoke(
        'send-fcm-notification',
        body: body,
      );

      final statusCode = response.status;
      final rawData = response.data;

      Map<String, dynamic> jsonMap = {};
      if (rawData is Map<String, dynamic>) {
        jsonMap = rawData;
      } else if (rawData is Map) {
        jsonMap = Map<String, dynamic>.from(rawData);
      }

      final result = SelfTestResult.fromJson(jsonMap, statusCode);

      if (kDebugMode) {
        debugPrint(
          '[AMOMY_NOTIF] Self-test backend response: '
          'status=$statusCode, '
          'success=${result.success}, '
          'request_accepted=${result.requestAccepted}, '
          'target_devices=${result.totalDevices}, '
          'fcm_send_attempted=${result.fcmSendAttempted}, '
          'fcm_successes=${result.fcmSuccesses}, '
          'fcm_failures=${result.fcmFailures}, '
          'inbox_inserted=${result.notificationInboxInserted}, '
          'error=${result.error ?? "none"}',
        );
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] Self-test backend response error: $e');
      }
      return SelfTestResult.failure(e.toString());
    }
  }

  @override
  Future<bool> isNotificationTester() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final res = await _client.rpc('is_notification_tester');
      if (res == true) return true;

      // Fallback direct check on app_testers table for current user
      final testerRow = await _client
          .from('app_testers')
          .select('notification_lab_enabled')
          .eq('user_id', user.id)
          .maybeSingle();

      if (testerRow != null && testerRow['notification_lab_enabled'] == true) {
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] isNotificationTester error: $e');
      }
      return false;
    }
  }

  @override
  Future<NotificationTestEventResult> sendTestEvent({
    required String eventType,
    bool forceDelivery = false,
    Map<String, dynamic>? customData,
    int? delaySeconds,
  }) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        return NotificationTestEventResult.failure(
          'No active user session',
          eventType: eventType,
        );
      }

      final body = <String, dynamic>{
        'action': 'test_event',
        'event_type': eventType,
        'force_delivery': forceDelivery,
        if (customData != null && customData.isNotEmpty) 'data': customData,
        if (delaySeconds != null && delaySeconds > 0)
          'delay_seconds': delaySeconds,
      };

      if (kDebugMode) {
        debugPrint(
          '[AMOMY_NOTIF] Dispatching Test Lab event: $eventType, force=$forceDelivery',
        );
      }

      final response = await _client.functions.invoke(
        'send-fcm-notification',
        body: body,
      );

      final statusCode = response.status;
      final rawData = response.data;

      Map<String, dynamic> jsonMap = {};
      if (rawData is Map<String, dynamic>) {
        jsonMap = rawData;
      } else if (rawData is Map) {
        jsonMap = Map<String, dynamic>.from(rawData);
      }

      final result = NotificationTestEventResult.fromJson(jsonMap, statusCode);

      if (kDebugMode) {
        debugPrint(
          '[AMOMY_NOTIF_TEST] action=test_event event_type=${result.eventType} tester_authorized=true force_delivery=${result.forced} target_devices=${result.totalDevices} inbox_inserted=${result.inboxInserted} fcm_successes=${result.delivered} fcm_failures=${result.fcmFailures}',
        );
      }

      return result;
    } catch (e) {
      String cleanMessage = 'Failed to dispatch test notification';
      if (e is FunctionException) {
        final details = e.details;
        if (details is Map && details['error'] != null) {
          cleanMessage = details['error'].toString();
        } else if (e.reasonPhrase != null && e.reasonPhrase!.isNotEmpty) {
          cleanMessage = e.reasonPhrase!;
        } else {
          cleanMessage = 'Server error (${e.status})';
        }
      } else {
        cleanMessage = e.toString();
        if (cleanMessage.contains('error:')) {
          final parts = cleanMessage.split('error:');
          if (parts.length > 1) {
            cleanMessage = parts[1].replaceAll(RegExp(r'[}"\n]'), '').trim();
          }
        }
      }

      if (kDebugMode) {
        debugPrint(
          '[AMOMY_NOTIF_TEST] action=test_event event_type=$eventType tester_authorized=false error=$cleanMessage',
        );
      }
      return NotificationTestEventResult.failure(
        cleanMessage,
        eventType: eventType,
      );
    }
  }

  @override
  Future<NotificationPreferencesModel> getPreferences() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return const NotificationPreferencesModel();
      }

      final response = await _client.rpc(
        'get_or_create_notification_preferences',
      );
      if (response is Map<String, dynamic>) {
        return NotificationPreferencesModel.fromJson(response);
      } else if (response is Map) {
        return NotificationPreferencesModel.fromJson(
          Map<String, dynamic>.from(response),
        );
      }

      final row = await _client
          .from('notification_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (row != null) {
        return NotificationPreferencesModel.fromJson(row);
      }
      return const NotificationPreferencesModel();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] getPreferences error: $e');
      }
      return const NotificationPreferencesModel();
    }
  }

  @override
  Future<NotificationPreferencesModel> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return NotificationPreferencesModel.fromEntity(preferences);
      }

      final response = await _client.rpc(
        'update_notification_preferences',
        params: {
          'p_all_enabled': preferences.allEnabled,
          'p_service_updates': preferences.serviceUpdates,
          'p_booking_updates': preferences.bookingUpdates,
          'p_wallet_updates': preferences.walletUpdates,
          'p_trip_updates': preferences.tripUpdates,
        },
      );

      if (response is Map<String, dynamic>) {
        return NotificationPreferencesModel.fromJson(response);
      } else if (response is Map) {
        return NotificationPreferencesModel.fromJson(
          Map<String, dynamic>.from(response),
        );
      }

      return NotificationPreferencesModel.fromEntity(preferences);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] updatePreferences error: $e');
      }
      return NotificationPreferencesModel.fromEntity(preferences);
    }
  }
}
