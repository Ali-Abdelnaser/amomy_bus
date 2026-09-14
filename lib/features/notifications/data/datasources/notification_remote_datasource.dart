import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    int offset = 0,
  });

  Future<int> getUnreadCount();

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

  Future<bool> sendSelfTestNotification();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final SupabaseClient _client;

  NotificationRemoteDataSourceImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final list = response as List<dynamic>;
      return list
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[NotificationRemoteDataSource] getNotifications error: $e');
      return [];
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 0;

      final response = await _client.rpc('get_unread_notifications_count');
      if (response is int) return response;
      if (response is num) return response.toInt();
      return 0;
    } catch (e) {
      debugPrint('[NotificationRemoteDataSource] getUnreadCount error: $e');
      return 0;
    }
  }

  @override
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _client.rpc('mark_notification_as_read', params: {
        'p_notification_id': notificationId,
      });
      return response == true;
    } catch (e) {
      debugPrint('[NotificationRemoteDataSource] markAsRead error: $e');
      return false;
    }
  }

  @override
  Future<int> markAllAsRead() async {
    try {
      final response = await _client.rpc('mark_all_notifications_as_read');
      if (response is int) return response;
      if (response is num) return response.toInt();
      return 0;
    } catch (e) {
      debugPrint('[NotificationRemoteDataSource] markAllAsRead error: $e');
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
      final response = await _client.rpc('register_device_token', params: {
        'p_token': token,
        'p_platform': platform,
        'p_installation_id': installationId,
        'p_device_name': deviceName,
        'p_app_version': appVersion,
      });
      return response != null;
    } catch (e) {
      debugPrint('[NotificationRemoteDataSource] registerDeviceToken error: $e');
      return false;
    }
  }

  @override
  Future<bool> deactivateDeviceToken(String token) async {
    try {
      final response = await _client.rpc('deactivate_device_token', params: {
        'p_token': token,
      });
      return response == true;
    } catch (e) {
      debugPrint('[NotificationRemoteDataSource] deactivateDeviceToken error: $e');
      return false;
    }
  }

  @override
  Future<bool> sendSelfTestNotification() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return false;

      final response = await _client.functions.invoke(
        'send-fcm-notification',
        body: {'action': 'self_test'},
      );

      return response.status == 200;
    } catch (e) {
      debugPrint('[NotificationRemoteDataSource] sendSelfTestNotification error: $e');
      return false;
    }
  }
}
