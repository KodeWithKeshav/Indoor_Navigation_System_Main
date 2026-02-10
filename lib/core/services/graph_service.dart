import 'package:fpdart/fpdart.dart';
import '../../features/admin_map/domain/entities/map_entities.dart';
import '../../features/admin_map/domain/entities/campus_entities.dart';
import '../../features/admin_map/domain/repositories/admin_map_repository.dart';
import 'pathfinding_service.dart';

/// Service responsible for building and managing the navigation graph.
///
/// It fetches data (buildings, floors, rooms, corridors) from the repository,
/// constructs the graph nodes and edges, and handles connections between
/// different levels (vertical) and buildings (campus).
class GraphService {
  final AdminMapRepository repository;
  
  // Cache of all rooms (nodes) in the graph
  List<Room> allRooms = [];
  
  // Cache of all corridors (edges) in the graph
  List<Corridor> allCorridors = [];
  
  // Flag to indicate if the graph needs rebuilding
  bool _isDirty = true;
  
  GraphService(this.repository);

  /// Marks the graph as dirty, forcing a rebuild on the next request.
  void markDirty() {
    _isDirty = true;
  }
  
  String? _currentOrgId;
  
  // Load all data and build the graph
  /// Builds the navigation graph by fetching buildings, floors, rooms, and corridors.
  /// 
  /// Also handles vertical connections (stairs/elevators) and campus-wide inter-building links.
  /// [organizationId] optionally filters the data for a specific organization.
  /// Returns [Either] with a error message or null on success.
  Future<Either<String, void>> buildGraph({String? organizationId}) async {
    try {
      // Check context switch
      if (organizationId != _currentOrgId) {
        _currentOrgId = organizationId;
        markDirty();
      } else if (!_isDirty && allRooms.isNotEmpty) {
        return const Right(null);
      }
      
      allRooms.clear();
      allCorridors.clear();
      
      // 1. Fetch Buildings
      final buildingsResult = await repository.getBuildings(organizationId: _currentOrgId);
      if (buildingsResult.isLeft()) return Left("Failed to load buildings");
      
      final buildings = buildingsResult.getRight().getOrElse(() => []);
      
      // 2. Fetch Floors & Content
      for (final building in buildings) {
        final floorsResult = await repository.getFloors(building.id);
        final floors = floorsResult.getRight().getOrElse(() => []);
        
        for (final floor in floors) {
          final roomsResult = await repository.getRooms(building.id, floor.id);
          final corridorsResult = await repository.getCorridors(building.id, floor.id);
          
          final rooms = roomsResult.getRight().getOrElse(() => []);
          final corridors = corridorsResult.getRight().getOrElse(() => []);
          
          allRooms.addAll(rooms);
          allCorridors.addAll(corridors);
          
          // Track metadata
          _floorToBuilding[floor.id] = building.id;
          floorLevels[floor.id] = floor.floorNumber;
        }
      }
      
      // 3. Load Campus Global Map (Outdoor)
      await _loadCampusMap(_currentOrgId);
      
      // 4. Add Vertical Connections (Virtual Corridors, includes Campus <-> Indoor links)
      _addVerticalConnections();
      
      // 5. Add Explicit Campus Connections (Inter-Building)
      final campusResult = await repository.getCampusConnections(); 
      if (campusResult.isRight()) {
         _addCampusConnections(campusResult.getRight().getOrElse(() => []));
      }
      
      print('Graph Built: ${allRooms.length} nodes, ${allCorridors.length} edges.');
      // Debug: Check for vertical connections
      final vertEdges = allCorridors.where((c) => c.floorId == 'vertical').length;
      print('Vertical Edges Created: $vertEdges');
      
      final campusEdges = allCorridors.where((c) => c.floorId == 'campus').length; 
      // Note: 'campus' floorId is used for created connections, 'ground' is used for the map itself.
      
      _isDirty = false;
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
  
  /// Loads the campus-level map data (outdoor nodes and paths).
  ///
  /// [orgId] is used to construct the campus ID.
  Future<void> _loadCampusMap(String? orgId) async {
    final campusId = orgId != null ? 'campus_$orgId' : 'campus_global';
    final roomsResult = await repository.getRooms(campusId, 'ground');
    final corridorsResult = await repository.getCorridors(campusId, 'ground');
    
    final rooms = roomsResult.getRight().getOrElse(() => []);
    final corridors = corridorsResult.getRight().getOrElse(() => []);
    
    allRooms.addAll(rooms);
    allCorridors.addAll(corridors);
    
    // Set floor level for ground to 0 (neutral)
    floorLevels['ground'] = 0; 
    _floorToBuilding['ground'] = campusId;
  }

  /// Creates vertical connections (edges) between rooms with the same connector ID.
  ///
  /// This links floors together via stairs or elevators.
  void _addVerticalConnections() {
    // Group rooms by ConnectorID
    final Map<String, List<Room>> connectorGroups = {};
    
    for (final room in allRooms) {
      if (room.connectorId != null && room.connectorId!.isNotEmpty) {
        final key = room.connectorId!;
        if (!connectorGroups.containsKey(key)) {
          connectorGroups[key] = [];
        }
        connectorGroups[key]!.add(room);
      }
    }
    
    for (final group in connectorGroups.values) {
      if (group.length < 2) continue;
      for (int i = 0; i < group.length; i++) {
        for (int j = i + 1; j < group.length; j++) {
          final r1 = group[i];
          final r2 = group[j];
          
          // Optimization: Weights for vertical travel
          // e.g. Elevator is "easier" (lower cost) than stairs? 
          // Or just standard distance. Let's make Elevator slightly preferred if close.
          double weight = 20.0; // Default for Stairs
          
          if (r1.type == RoomType.elevator && r2.type == RoomType.elevator) {
            weight = 10.0; // Elevators are faster/preferred
          }
          
          allCorridors.add(Corridor(
            id: 'vert_${r1.id}_${r2.id}',
            floorId: 'vertical',
            startRoomId: r1.id,
            endRoomId: r2.id,
            distance: weight,
          ));
        }
      }
    }
  }

  /// Adds connections between different buildings based on campus data.
  ///
  /// [connections] list contains the metadata for linking buildings.
  void _addCampusConnections(List<CampusConnection> connections) {
    // We need to know which rooms are Entrance nodes for a specific Building.
    // Using the _floorToBuilding map populated in buildGraph.
    
    for (final conn in connections) {
      final fromBldg = conn.fromBuildingId;
      final toBldg = conn.toBuildingId;
      
      // 1. Try to find "Outdoor Nodes" (Visual representation on Campus Map)
      // These are on 'ground' floor and their connectorId matches the building ID.
      final fromNodes = allRooms.where((r) => r.floorId == 'ground' && r.connectorId == fromBldg).toList();
      final toNodes = allRooms.where((r) => r.floorId == 'ground' && r.connectorId == toBldg).toList();

      if (fromNodes.isNotEmpty && toNodes.isNotEmpty) {
          // Link Visual Nodes
          for (final start in fromNodes) {
            for (final end in toNodes) {
               if (conn.distance > 0) {
                 allCorridors.add(Corridor(
                  id: 'campus_${start.id}_${end.id}',
                  floorId: 'campus',
                  startRoomId: start.id,
                  endRoomId: end.id,
                  distance: conn.distance,
                ));
               }
            }
          }
      } else {
          // Fallback: Link Entrances Directly (Invisible path, but functional)
          
          // Find all Entrance Rooms in 'From Building'
          final fromEntrances = allRooms.where((r) {
            final bId = _floorToBuilding[r.floorId];
            return bId == fromBldg && r.type == RoomType.entrance;
          }).toList();

          // Find all Entrance Rooms in 'To Building'
          final toEntrances = allRooms.where((r) {
            final bId = _floorToBuilding[r.floorId];
            return bId == toBldg && r.type == RoomType.entrance;
          }).toList();
          
          for (final start in fromEntrances) {
            for (final end in toEntrances) {
               if (conn.distance > 0) { // check if distance valid
                 allCorridors.add(Corridor(
                  id: 'campus_${start.id}_${end.id}',
                  floorId: 'campus',
                  startRoomId: start.id,
                  endRoomId: end.id,
                  distance: conn.distance,
                ));
               }
            }
          }
      }
    }
  }
  
  final Map<String, String> _floorToBuilding = {};

  /// Finds a path between [startId] and [endId].
  ///
  /// [isAccessible] if true, avoids stairs and prefers elevators/ramps.
  List<String> findPath(String startId, String endId, {bool isAccessible = false}) {
    return PathfindingService.findPath(startId, endId, allRooms, allCorridors, isAccessible: isAccessible);
  }
  
  String? getBuildingIdForFloor(String floorId) => _floorToBuilding[floorId];
  
  final Map<String, int> floorLevels = {};
}
