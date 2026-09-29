import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/referral_models.dart';

abstract class ReferralRemoteDataSource {
  Future<ReferralDashboardModel> getMyReferralDashboard();
  Future<ReferralCodePreviewModel> previewReferralCode(String code);
  Future<BindReferralResultModel> bindReferralCode({
    required String code,
    required String source,
  });

  /// Subscribes to changes in referral_settings.
  Stream<void> subscribeToReferralSettingsUpdates();

  /// Subscribes to changes in referral_settings, referrals, referral_rewards, referral_qualified_trips.
  Stream<void> subscribeToReferralDashboardUpdates();
}

@LazySingleton(as: ReferralRemoteDataSource)
class ReferralRemoteDataSourceImpl implements ReferralRemoteDataSource {
  final SupabaseClient? _customClient;

  ReferralRemoteDataSourceImpl([SupabaseClient? supabase])
      : _customClient = supabase;

  SupabaseClient? get _supabaseClient {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ReferralDashboardModel> getMyReferralDashboard() async {
    final client = _supabaseClient;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not available');
    }
    final response = await client.rpc('get_my_referral_dashboard');
    return ReferralDashboardModel.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  @override
  Future<ReferralCodePreviewModel> previewReferralCode(String code) async {
    final client = _supabaseClient;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not available');
    }
    final response = await client.rpc(
      'referral_preview_code',
      params: {'p_code': code.trim()},
    );
    return ReferralCodePreviewModel.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  @override
  Future<BindReferralResultModel> bindReferralCode({
    required String code,
    required String source,
  }) async {
    final client = _supabaseClient;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not available');
    }
    final response = await client.rpc(
      'bind_referral_code',
      params: {
        'p_code': code.trim(),
        'p_source': source,
      },
    );
    return BindReferralResultModel.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  @override
  Stream<void> subscribeToReferralSettingsUpdates() {
    final client = _supabaseClient;
    if (client == null) {
      return const Stream.empty();
    }

    late final StreamController<void> controller;
    RealtimeChannel? channel;

    controller = StreamController<void>.broadcast(
      onListen: () {
        try {
          channel = client.channel(
            'referral_settings_live_${identityHashCode(controller)}',
          );
          channel!
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'referral_settings',
                callback: (_) {
                  if (!controller.isClosed) controller.add(null);
                },
              )
              .subscribe();
        } catch (_) {}
      },
      onCancel: () {
        if (channel != null) {
          try {
            client.removeChannel(channel!);
          } catch (_) {}
        }
      },
    );

    return controller.stream;
  }

  @override
  Stream<void> subscribeToReferralDashboardUpdates() {
    final client = _supabaseClient;
    if (client == null) {
      return const Stream.empty();
    }

    late final StreamController<void> controller;
    RealtimeChannel? channel;

    controller = StreamController<void>.broadcast(
      onListen: () {
        try {
          channel = client.channel(
            'referral_dashboard_live_${identityHashCode(controller)}',
          );
          channel!
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'referral_settings',
                callback: (_) {
                  if (!controller.isClosed) controller.add(null);
                },
              )
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'referrals',
                callback: (_) {
                  if (!controller.isClosed) controller.add(null);
                },
              )
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'referral_rewards',
                callback: (_) {
                  if (!controller.isClosed) controller.add(null);
                },
              )
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'referral_qualified_trips',
                callback: (_) {
                  if (!controller.isClosed) controller.add(null);
                },
              )
              .subscribe();
        } catch (_) {}
      },
      onCancel: () {
        if (channel != null) {
          try {
            client.removeChannel(channel!);
          } catch (_) {}
        }
      },
    );

    return controller.stream;
  }
}
