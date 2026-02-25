import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../admin_map/domain/entities/map_entities.dart';

// Model for Route History
class RouteHistory {
  final String startLocationId;
  final String startLocationName;
  final String startFloorId;
  final String endLocationId;
  final String endLocationName;
  final String endFloorId;
  final DateTime timestamp;

  RouteHistory({
    required this.startLocationId,
    required this.startLocationName,
    required this.startFloorId,
    required this.endLocationId,
    required this.endLocationName,
    required this.endFloorId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'startLocationId': startLocationId,
    'startLocationName': startLocationName,
    'startFloorId': startFloorId,
    'endLocationId': endLocationId,
    'endLocationName': endLocationName,
    'endFloorId': endFloorId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RouteHistory.fromJson(Map<String, dynamic> json) {
    return RouteHistory(
      startLocationId: json['startLocationId'],
      startLocationName: json['startLocationName'],
      startFloorId: json['startFloorId'] ?? '',
      endLocationId: json['endLocationId'],
      endLocationName: json['endLocationName'],
      endFloorId: json['endFloorId'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

// Provider
final routeHistoryServiceProvider = Provider<RouteHistoryService>((ref) {
  return RouteHistoryService(ref);
});

final routeHistoryProvider = FutureProvider<List<RouteHistory>>((ref) async {
  final service = ref.watch(routeHistoryServiceProvider);
  return service.getRouteHistory();
});

class RouteHistoryService {
  final Ref _ref;
  static const String _key = 'route_history';
  static const int _limit = 10;

  RouteHistoryService(this._ref);

  Future<List<RouteHistory>> getRouteHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => RouteHistory.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addRoute(Room start, Room end) async {
    final prefs = await SharedPreferences.getInstance();
    List<RouteHistory> current = await getRouteHistory();

    // Remove identical routes
    current.removeWhere(
      (route) =>
          route.startLocationId == start.id && route.endLocationId == end.id,
    );

    // Add new to top
    current.insert(
      0,
      RouteHistory(
        startLocationId: start.id,
        startLocationName: start.name,
        startFloorId: start.floorId,
        endLocationId: end.id,
        endLocationName: end.name,
        endFloorId: end.floorId,
        timestamp: DateTime.now(),
      ),
    );

    // Limit to 10
    if (current.length > _limit) {
      current = current.sublist(0, _limit);
    }

    // Save
    await prefs.setString(
      _key,
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );

    // Invalidate provider to refresh UI
    _ref.invalidate(routeHistoryProvider);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _ref.invalidate(routeHistoryProvider);
  }
}
