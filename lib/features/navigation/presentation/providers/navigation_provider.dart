import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/providers/admin_map_providers.dart';
import 'package:indoor_navigation_system/core/services/navigation_instruction_service.dart';
import 'package:indoor_navigation_system/core/services/compass_service.dart';

class NavigationState {
  final Room? startRoom;
  final Room? endRoom;
  final List<String> pathIds;
  final List<Room> pathRooms; // Store full rooms for easier filtering
  final List<NavigationInstruction> instructions;
  final bool isNavigating;
  final String? organizationId;
  final bool isAccessible;

  NavigationState({
    this.startRoom,
    this.endRoom,
    this.pathIds = const [],
    this.pathRooms = const [],
    this.instructions = const [],
    this.isNavigating = false,
    this.organizationId,
    this.isAccessible = false,
  });

  NavigationState copyWith({
    Room? startRoom,
    Room? endRoom,
    List<String>? pathIds,
    List<Room>? pathRooms,
    List<NavigationInstruction>? instructions,
    bool? isNavigating,
    String? organizationId,
    bool? isAccessible,
  }) {
    return NavigationState(
      startRoom: startRoom ?? this.startRoom,
      endRoom: endRoom ?? this.endRoom,
      pathIds: pathIds ?? this.pathIds,
      pathRooms: pathRooms ?? this.pathRooms,
      instructions: instructions ?? this.instructions,
      isNavigating: isNavigating ?? this.isNavigating,
      organizationId: organizationId ?? this.organizationId,
      isAccessible: isAccessible ?? this.isAccessible,
    );
  }
}

class NavigationNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() {
    print('NavigationNotifier: build() called - State Reset?');
    
    // Listen to compass changes to update orientation-dependent instructions
    ref.listen(compassProvider, (prev, next) {
      if (state.isNavigating) {
         _computePath();
      }
    });
    
    return NavigationState();
  }

  Future<void> setStart(Room room, {String? organizationId}) async {
    print('NavigationNotifier: setStart(${room.name}) - Current End: ${state.endRoom?.name}, Org: $organizationId');
    state = state.copyWith(
       startRoom: room, 
       isNavigating: false, 
       pathIds: [], 
       instructions: [], 
       organizationId: organizationId
    );
    await _computePath();
  }

  Future<void> setEnd(Room room) async {
    print('NavigationNotifier: setEnd(${room.name}) - Current Start: ${state.startRoom?.name}');
    state = state.copyWith(endRoom: room);
    await _computePath();
  }

  Future<void> toggleAccessibility(bool value) async {
    state = state.copyWith(isAccessible: value);
    if (state.startRoom != null && state.endRoom != null) {
      await _computePath();
    }
  }

  
  void clear() {
    state = NavigationState();
  }

  Future<void> _computePath() async {
    print('NavigationNotifier: Computing Path...');
    if (state.startRoom == null || state.endRoom == null) {
        print('NavigationNotifier: MISSING START OR END');
        return;
    }
    
    // Ensure Graph IS Built (Optimized internally by GraphService)
    final graphService = ref.read(graphServiceProvider);
    await graphService.buildGraph(organizationId: state.organizationId);
    
    final pathIds = graphService.findPath(
      state.startRoom!.id, 
      state.endRoom!.id,
      isAccessible: state.isAccessible,
    );
    
    if (pathIds.isNotEmpty) {
      print('NavigationNotifier: Path Found (${pathIds.length} nodes)');
      final pathRooms = <Room>[];
      for (final id in pathIds) {
        try {
           final room = graphService.allRooms.firstWhere((r) => r.id == id);
           pathRooms.add(room);
        } catch (_) {}
      }
      
      final currentHeading = ref.read(compassProvider);
      
      final instructions = ref.read(navigationInstructionServiceProvider).generateInstructions(
        pathRooms,
        corridors: graphService.allCorridors,
        floorLevels: graphService.floorLevels,
        currentHeading: currentHeading,
        mapNorthOffset: 0.0, // Default to 0 until we fetch building metadata
      );
      
      state = state.copyWith(
        pathIds: pathIds,
        pathRooms: pathRooms,
        instructions: instructions,
        isNavigating: true,
      );
    } else {
       // No path
       print('NavigationNotifier: No Path Found');
       state = state.copyWith(
         isNavigating: false, 
         pathIds: [],
         instructions: [NavigationInstruction(message: "No Path Found", distance: 0, icon: 'error')],
       );
    }
  }
}

final navigationProvider = NotifierProvider<NavigationNotifier, NavigationState>(NavigationNotifier.new);
