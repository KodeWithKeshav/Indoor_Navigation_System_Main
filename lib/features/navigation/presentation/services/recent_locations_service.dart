
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../admin_map/domain/entities/map_entities.dart';
import '../../../admin_map/presentation/providers/admin_map_providers.dart';

// Model for Recent Location
class RecentLocation {
  final String locationId; // Room ID or Building ID
  final String name;
  final String? type; // 'room' or 'building'
  final DateTime timestamp;

  RecentLocation({
    required this.locationId, 
    required this.name, 
    this.type = 'room',
    required this.timestamp
  });

  Map<String, dynamic> toJson() => {
    'locationId': locationId,
    'name': name,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RecentLocation.fromJson(Map<String, dynamic> json) {
    return RecentLocation(
      locationId: json['locationId'],
      name: json['name'],
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

// Provider
final recentLocationsServiceProvider = Provider<RecentLocationsService>((ref) {
  return RecentLocationsService(ref);
});

final recentLocationsProvider = FutureProvider<List<RecentLocation>>((ref) async {
  final service = ref.watch(recentLocationsServiceProvider);
  return service.getRecentLocations();
});

class RecentLocationsService {
  final Ref _ref;
  static const String _key = 'recent_locations';
  static const int _limit = 5;

  RecentLocationsService(this._ref);

  Future<List<RecentLocation>> getRecentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => RecentLocation.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addRecentLocation(Room room) async {
    final prefs = await SharedPreferences.getInstance();
    List<RecentLocation> current = await getRecentLocations();

    // Remove duplicates
    current.removeWhere((loc) => loc.locationId == room.id);

    // Add new to top
    current.insert(0, RecentLocation(
      locationId: room.id,
      name: room.name,
      type: 'room',
      timestamp: DateTime.now()
    ));

    // Limit
    if (current.length > _limit) {
      current = current.sublist(0, _limit);
    }

    // Save
    await prefs.setString(_key, jsonEncode(current.map((e) => e.toJson()).toList()));
    
    // Invalidate provider to refresh UI
    _ref.invalidate(recentLocationsProvider);
  }
  
  Future<void> clearRecents() async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.remove(_key);
     _ref.invalidate(recentLocationsProvider);
  }
}
