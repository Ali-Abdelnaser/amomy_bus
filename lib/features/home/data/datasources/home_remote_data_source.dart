import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/announcement_model.dart';
import '../models/home_summary_model.dart';

abstract class HomeRemoteDataSource {
  Future<HomeSummaryModel> getHomeSummary();
  Future<List<AnnouncementModel>> getActiveAnnouncements();
}

@LazySingleton(as: HomeRemoteDataSource)
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final SupabaseClient _supabase;

  HomeRemoteDataSourceImpl(this._supabase);

  @override
  Future<HomeSummaryModel> getHomeSummary() async {
    final response = await _supabase.rpc('get_passenger_home_summary');
    if (response == null) {
      throw const ServerException(message: 'Empty response from home summary');
    }

    final Map<String, dynamic> data;
    if (response is String) {
      data = jsonDecode(response) as Map<String, dynamic>;
    } else if (response is Map) {
      data = Map<String, dynamic>.from(response);
    } else {
      throw const ServerException(message: 'Invalid home summary format');
    }

    return HomeSummaryModel.fromJson(data);
  }

  @override
  Future<List<AnnouncementModel>> getActiveAnnouncements() async {
    final response = await _supabase.rpc('get_active_announcements');
    if (response == null) return [];

    final List list = response as List;
    return list
        .map(
          (item) => AnnouncementModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}
