import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import '../../../../core/providers/settings_provider.dart';
import 'package:indoor_navigation_system/features/auth/presentation/providers/auth_providers.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/providers/admin_map_providers.dart';
import '../providers/user_location_provider.dart';
import '../providers/navigation_provider.dart';
import '../services/recent_locations_service.dart';
import 'location_search_dialog.dart';

// Theme Constants
const Color deepVoidBlue = Color(0xFF0F172A);
const Color electricGrid = Color(0xFF38BDF8);
const Color darkCardColor = Color(0xFF1E293B);
const Color paperWhite = Color(0xFFE2E8F0);

enum PlannerMode { building, room }

class TripPlannerWidget extends ConsumerStatefulWidget {
  const TripPlannerWidget({super.key});

  @override
  ConsumerState<TripPlannerWidget> createState() => _TripPlannerWidgetState();
}

class _TripPlannerWidgetState extends ConsumerState<TripPlannerWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Selections
  Building? _startBuilding;
  Floor? _startFloor;
  Room? _startRoom;

  Building? _endBuilding;
  Floor? _endFloor;
  Room? _endRoom;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _resetSelections();
      });
    });
  }

  void _resetSelections() {
    _startBuilding = null;
    _startFloor = null;
    _startRoom = null;
    _endBuilding = null;
    _endFloor = null;
    _endRoom = null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper to get rooms for a building/floor
  List<Room> _getRooms(String buildingId, String? floorId) {
    final graphService = ref.read(graphServiceProvider);

    // Handle Campus (No Floors usually)
    if (buildingId.startsWith('campus_')) {
      return graphService.allRooms.where((room) {
        return room.floorId == 'ground' || room.floorId == 'campus';
      }).toList();
    }

    // Normal Building
    if (floorId == null)
      return []; // Require floor selection for normal buildings

    return graphService.allRooms.where((room) {
      if (room.floorId != floorId) return false;

      // Filter out unwanted types for "Room Finder"
      if (room.type == RoomType.hallway ||
          room.type == RoomType.stairs ||
          room.type == RoomType.elevator) {
        return false;
      }
      return true;
    }).toList();
  }

  Building _getCampusBuilding(String? orgId) {
    return Building(
      id: orgId != null ? 'campus_$orgId' : 'campus_global',
      name: 'Campus / Outdoor',
      description: 'Outdoor Map',
      organizationId: orgId,
    );
  }

  // Helper to get Entrances for a building
  Room? _getEntranceForBuilding(String buildingId) {
    final graphService = ref.read(graphServiceProvider);
    try {
      final entrance = graphService.allRooms.firstWhere((room) {
        if (room.type != RoomType.entrance) return false;
        final bId = graphService.getBuildingIdForFloor(room.floorId);
        return bId == buildingId || room.connectorId == buildingId;
      });
      return entrance;
    } catch (_) {
      return null;
    }
  }

  void _onNavigate() async {
    final user = ref.read(currentUserProvider);
    final notifier = ref.read(navigationProvider.notifier);

    Room? start;
    Room? end;

    if (_tabController.index == 0) {
      if (_startBuilding != null && _endBuilding != null) {
        start = _getEntranceForBuilding(_startBuilding!.id);
        end = _getEntranceForBuilding(_endBuilding!.id);
        if (start == null || end == null) {
          _showError('One of the buildings does not have a defined Entrance.');
          return;
        }
      }
    } else {
      start = _startRoom;
      end = _endRoom;
    }

    if (start != null && end != null) {
      if (start.id == end.id) {
        _showError('Start and Destination cannot be the same.');
        return;
      }

      // Trip Summary Dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: darkCardColor,
          title: const Text(
            'Trip Summary',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow(Icons.my_location, "From", start!.name),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Icon(Icons.arrow_downward, color: Colors.grey, size: 16),
              ),
              _buildSummaryRow(Icons.place, "To", end!.name),
              const SizedBox(height: 16),
              const Text(
                "Ready to start navigation?",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: electricGrid),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Start',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Save to Route History
        final routeService = ref.read(routeHistoryServiceProvider);
        routeService.addRoute(start, end);

        notifier.setStart(start, organizationId: user?.organizationId);
        notifier.setEnd(end);
      }
    } else {
      _showError('Please select both start and destination.');
    }
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: electricGrid, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _swapLocations() {
    setState(() {
      final tempB = _startBuilding;
      final tempF = _startFloor;
      final tempR = _startRoom;

      _startBuilding = _endBuilding;
      _startFloor = _endFloor;
      _startRoom = _endRoom;

      _endBuilding = tempB;
      _endFloor = tempF;
      _endRoom = tempR;
    });
  }

  void _openSearch(bool isStart) async {
    final selectedRoom = await showDialog<Room>(
      context: context,
      builder: (ctx) => const LocationSearchDialog(),
    );

    if (selectedRoom != null) {
      final graphService = ref.read(graphServiceProvider);

      // We need to reconstruct the Building/Floor objects for the dropdowns to match
      // This is a bit tricky because we only have IDs.
      // We need to find the Building and Floor objects that correspond to this room.

      final user = ref.read(currentUserProvider);
      final buildings =
          ref.read(buildingsProvider(user?.organizationId)).value ?? [];

      String? buildingId;
      // Try to find building ID
      try {
        buildingId = graphService.getBuildingIdForFloor(selectedRoom.floorId);
      } catch (_) {
        // Maybe it's a campus room?
        if (selectedRoom.floorId == 'campus')
          buildingId = 'campus_${user?.organizationId ?? 'global'}';
      }

      final building =
          buildings.where((b) => b.id == buildingId).firstOrNull ??
          _getCampusBuilding(user?.organizationId);

      // Now find floor
      // We need to fetch floors? The provider caches them, but we might usually access them async.
      // For simplicity, if we found the building, we can try to set the room directly
      // But our UI relies on Dropdowns.
      // Let's set what we can.

      // Hack: we need to ensure the providers have data or we just set the room
      // and let the UI try to catch up or use the Room object directly.

      setState(() {
        if (isStart) {
          _startBuilding = building;
          // We can't easily find the Floor object instance without async call to floors provider
          // But we can set the room, and if the dropdowns re-build, they might match?
          // Actually, if we set _startRoom, the UI should show it?
          // The dropdown logic uses `value: _startRoom`. So if `_startRoom` is in the list returned by `_getRooms`, it works.
          // `_getRooms` uses `_startFloor`. So we MUST set `_startFloor`.

          // Let's reset floor/room to null first to avoid assertion error if mismatched
          _startFloor = null;
          _startRoom = null;

          // If we have building, we should ideally fetch floors to find the right one.
          // This is complicated in synchronous setState.
          // Better approach: Just set the Room and let a computed effect handle it? No.

          // Alternative: Just set the Room and make the dropdown smart?
          // For now, let's just support Room Search setting the Room directly if in Room Mode.
          if (_tabController.index == 1) {
            _startRoom = selectedRoom;
            // We try to infer floor/building for UI consistency if possible,
            // but primarily we just want the room set.
            // To update the Floor dropdown, we need the Floor object.
            // We can't get it easily.
            // So we might leave Floor/Building dropdowns inconsistent or empty?
            // That's bad UX.

            // Let's just set the building if we found it.
            if (buildingId != null) _startBuilding = building;

            // We need to set the floor for the room dropdown to populate correctly
            // because `items` depends on `_getRooms` which depends on `_startFloor`.
            // We can try to construct a partial Floor object? No, Equatable needs exact match.

            // Workaround: Function to fetch floor async and update state
            _resolveLocationContext(selectedRoom, isStart);
          }
        } else {
          if (_tabController.index == 1) {
            _resolveLocationContext(selectedRoom, isStart);
          }
        }
      });
    }
  }

  void _resolveLocationContext(Room room, bool isStart) async {
    final user = ref.read(currentUserProvider);
    final graphService = ref.read(graphServiceProvider);

    String? buildingId;
    try {
      buildingId = graphService.getBuildingIdForFloor(room.floorId);
    } catch (_) {
      if (room.floorId == 'campus')
        buildingId = 'campus_${user?.organizationId ?? 'global'}';
    }

    final buildings =
        ref.read(buildingsProvider(user?.organizationId)).value ?? [];
    final building =
        buildings.where((b) => b.id == buildingId).firstOrNull ??
        _getCampusBuilding(user?.organizationId);

    if (building != null) {
      // Fetch floors
      final floors = await ref.read(
        floorsOfBuildingProvider(building.id).future,
      );
      final floor = floors.where((f) => f.id == room.floorId).firstOrNull;

      if (mounted) {
        setState(() {
          if (isStart) {
            _startBuilding = building;
            _startFloor = floor;
            _startRoom = room;
          } else {
            _endBuilding = building;
            _endFloor = floor;
            _endRoom = room;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final buildingsAsync = ref.watch(buildingsProvider(user?.organizationId));

    // Input Decoration Style
    InputDecoration inputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: paperWhite.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: electricGrid),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: electricGrid),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        isDense: true,
      );
    }

    final dropdownTheme = Theme.of(context).copyWith(
      canvasColor: darkCardColor,
      textTheme: Theme.of(
        context,
      ).textTheme.apply(bodyColor: paperWhite, displayColor: paperWhite),
    );

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: darkCardColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: electricGrid.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: electricGrid.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Styled Tab Bar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: electricGrid,
                unselectedLabelColor: Colors.grey,
                indicatorColor: electricGrid,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    text: "Building Guide",
                    icon: Icon(Icons.apartment, size: 20),
                  ),
                  Tab(
                    text: "Room Finder",
                    icon: Icon(Icons.meeting_room, size: 20),
                  ),
                ],
              ),
            ),

            buildingsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: electricGrid),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (buildings) {
                if (buildings.isEmpty)
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No buildings found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );

                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Theme(
                    data: dropdownTheme,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_tabController.index == 0) ...[
                          // --- Building Mode ---
                          const Text(
                            "Navigates between Main Entrances.",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // From Building
                          DropdownButtonFormField<Building>(
                            decoration: inputDecoration(
                              'From Building',
                              Icons.my_location,
                            ),
                            dropdownColor: darkCardColor,
                            style: const TextStyle(color: paperWhite),
                            value: _startBuilding,
                            items: [
                              DropdownMenuItem(
                                value: _getCampusBuilding(user?.organizationId),
                                child: const Text(
                                  'Campus / Outdoor',
                                  style: TextStyle(color: paperWhite),
                                ),
                              ),
                              ...buildings
                                  .map(
                                    (b) => DropdownMenuItem(
                                      value: b,
                                      child: Text(
                                        b.name,
                                        style: const TextStyle(
                                          color: paperWhite,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ],
                            onChanged: (val) =>
                                setState(() => _startBuilding = val),
                          ),

                          // Swap Button
                          Center(
                            child: IconButton(
                              icon: const Icon(
                                Icons.swap_vert_circle,
                                color: electricGrid,
                                size: 32,
                              ),
                              onPressed: _swapLocations,
                              tooltip: 'Swap Locations',
                            ),
                          ),

                          // To Building
                          DropdownButtonFormField<Building>(
                            decoration: inputDecoration(
                              'To Building',
                              Icons.place,
                            ),
                            dropdownColor: darkCardColor,
                            style: const TextStyle(color: paperWhite),
                            value: _endBuilding,
                            items: [
                              DropdownMenuItem(
                                value: _getCampusBuilding(user?.organizationId),
                                child: const Text(
                                  'Campus / Outdoor',
                                  style: TextStyle(color: paperWhite),
                                ),
                              ),
                              ...buildings
                                  .map(
                                    (b) => DropdownMenuItem(
                                      value: b,
                                      child: Text(
                                        b.name,
                                        style: const TextStyle(
                                          color: paperWhite,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ],
                            onChanged: (val) =>
                                setState(() => _endBuilding = val),
                          ),
                        ] else ...[
                          // --- Room Mode ---
                          // FROM SECTION
                          _buildLocationSelector(
                            label: "From",
                            icon: Icons.my_location,
                            buildings: buildings,
                            selectedBuilding: _startBuilding,
                            selectedFloor: _startFloor,
                            selectedRoom: _startRoom,
                            onBuildingChanged: (b) => setState(() {
                              _startBuilding = b;
                              _startFloor = null;
                              _startRoom = null;
                            }),
                            onFloorChanged: (f) => setState(() {
                              _startFloor = f;
                              _startRoom = null;
                            }),
                            onRoomChanged: (r) =>
                                setState(() => _startRoom = r),
                            campusBuilding: _getCampusBuilding(
                              user?.organizationId,
                            ),
                            onSearch: () => _openSearch(true),
                          ),

                          // Swap Button
                          Center(
                            child: IconButton(
                              icon: const Icon(
                                Icons.swap_vert_circle,
                                color: electricGrid,
                                size: 32,
                              ),
                              onPressed: _swapLocations,
                              tooltip: 'Swap Locations',
                            ),
                          ),

                          // TO SECTION
                          _buildLocationSelector(
                            label: "To",
                            icon: Icons.place,
                            buildings: buildings,
                            selectedBuilding: _endBuilding,
                            selectedFloor: _endFloor,
                            selectedRoom: _endRoom,
                            onBuildingChanged: (b) => setState(() {
                              _endBuilding = b;
                              _endFloor = null;
                              _endRoom = null;
                            }),
                            onFloorChanged: (f) => setState(() {
                              _endFloor = f;
                              _endRoom = null;
                            }),
                            onRoomChanged: (r) => setState(() => _endRoom = r),
                            campusBuilding: _getCampusBuilding(
                              user?.organizationId,
                            ),
                            onSearch: () => _openSearch(false),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            // Accessibility Toggle
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Accessible Route',
                  style: TextStyle(color: paperWhite, fontSize: 14),
                ),
                subtitle: Text(
                  'Prioritize elevators & ramps',
                  style: TextStyle(
                    color: paperWhite.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
                secondary: Icon(
                  Icons.accessible_forward,
                  color: ref.watch(navigationProvider).isAccessible
                      ? electricGrid
                      : Colors.grey,
                ),
                value: ref.watch(navigationProvider).isAccessible,
                activeColor: electricGrid,
                onChanged: (val) {
                  ref
                      .read(navigationProvider.notifier)
                      .toggleAccessibility(val);
                },
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Action Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5), // IndigoAccent
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: const Color(0xFF4F46E5).withOpacity(0.5),
                ),
                onPressed: _onNavigate,
                child: const Text(
                  'Start Navigation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector({
    required String label,
    required IconData icon,
    required List<Building> buildings,
    required Building? selectedBuilding,
    required Floor? selectedFloor,
    required Room? selectedRoom,
    required Function(Building?) onBuildingChanged,
    required Function(Floor?) onFloorChanged,
    required Function(Room?) onRoomChanged,
    required Building campusBuilding,
    required VoidCallback onSearch,
  }) {
    // Check if we need Floor Dropdown
    final isCampus = selectedBuilding?.id.startsWith('campus_') ?? false;
    final showFloor = selectedBuilding != null && !isCampus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Building + Search
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<Building>(
                isExpanded: true,
                dropdownColor: darkCardColor,
                decoration: InputDecoration(
                  labelText: '$label Building',
                  labelStyle: TextStyle(color: paperWhite.withOpacity(0.6)),
                  prefixIcon: Icon(icon, color: electricGrid),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(color: paperWhite, fontSize: 13),
                value: selectedBuilding,
                items: [
                  DropdownMenuItem(
                    value: campusBuilding,
                    child: const Text(
                      'Campus / Outdoor',
                      style: TextStyle(color: paperWhite),
                    ),
                  ),
                  ...buildings
                      .map(
                        (b) => DropdownMenuItem(
                          value: b,
                          child: Text(b.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                ],
                onChanged: onBuildingChanged,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.search, color: electricGrid),
              onPressed: onSearch,
              tooltip: 'Search for room',
              style: IconButton.styleFrom(backgroundColor: Colors.white10),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Row 2: Floor (if valid) + Room
        Row(
          children: [
            // Floor Dropdown
            if (showFloor) ...[
              Expanded(
                flex: 4,
                child: Consumer(
                  builder: (context, ref, _) {
                    final floorsAsync = ref.watch(
                      floorsOfBuildingProvider(selectedBuilding!.id),
                    );
                    return floorsAsync.when(
                      data: (floors) => DropdownButtonFormField<Floor>(
                        isExpanded: true,
                        dropdownColor: darkCardColor,
                        decoration: InputDecoration(
                          labelText: 'Floor',
                          labelStyle: TextStyle(
                            color: paperWhite.withOpacity(0.6),
                          ),
                          prefixIcon: const Icon(
                            Icons.layers,
                            color: electricGrid,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(color: paperWhite, fontSize: 13),
                        value: selectedFloor,
                        items: floors
                            .map(
                              (f) => DropdownMenuItem(
                                value: f,
                                child: Text(
                                  f.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: onFloorChanged,
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Icon(Icons.error, size: 16),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Room Dropdown
            Expanded(
              flex: showFloor ? 6 : 10,
              child: DropdownButtonFormField<Room>(
                isExpanded: true,
                dropdownColor: darkCardColor,
                decoration: InputDecoration(
                  labelText: 'Room',
                  labelStyle: TextStyle(color: paperWhite.withOpacity(0.6)),
                  prefixIcon: const Icon(
                    Icons.door_front_door,
                    color: electricGrid,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(color: paperWhite, fontSize: 13),
                value: selectedRoom,
                items: selectedBuilding == null
                    ? []
                    : _getRooms(selectedBuilding.id, selectedFloor?.id)
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                r.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                onChanged: onRoomChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
