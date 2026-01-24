import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/features/auth/presentation/providers/auth_providers.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/providers/admin_map_providers.dart';
import '../providers/user_location_provider.dart';
import '../providers/navigation_provider.dart';

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

class _TripPlannerWidgetState extends ConsumerState<TripPlannerWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Selections
  Building? _startBuilding;
  Building? _endBuilding;
  
  Room? _startRoom;
  Room? _endRoom;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _startBuilding = null;
        _endBuilding = null;
        _startRoom = null;
        _endRoom = null;
      });
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper to get rooms for a building, excluding accessories
  List<Room> _getRoomsForBuilding(String buildingId) {
    final graphService = ref.read(graphServiceProvider);
    
    // Handle Campus
    if (buildingId.startsWith('campus_')) {
        return graphService.allRooms.where((room) {
           return room.floorId == 'ground' || room.floorId == 'campus';
        }).toList();
    }

    return graphService.allRooms.where((room) {
      final bId = graphService.getBuildingIdForFloor(room.floorId);
      if (bId != buildingId) return false;

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
        organizationId: orgId
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

  void _onNavigate() {
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
      notifier.setStart(start, organizationId: user?.organizationId);
      notifier.setEnd(end);
    } else {
      _showError('Please select both start and destination.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.redAccent.withOpacity(0.8),
      behavior: SnackBarBehavior.floating,
    ));
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: electricGrid)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
    }
    
    final dropdownTheme = Theme.of(context).copyWith(
       canvasColor: darkCardColor, // For dropdown menu background
       textTheme: Theme.of(context).textTheme.apply(bodyColor: paperWhite, displayColor: paperWhite),
    );

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: darkCardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: electricGrid.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
            BoxShadow(color: electricGrid.withOpacity(0.05), blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Styled Tab Bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
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
                Tab(text: "Building Guide", icon: Icon(Icons.apartment, size: 20)),
                Tab(text: "Room Finder", icon: Icon(Icons.meeting_room, size: 20)),
              ],
            ),
          ),
          
          buildingsAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: electricGrid))),
            error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
            data: (buildings) {
              if (buildings.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No buildings found.', style: TextStyle(color: Colors.grey)));
              
              return Container(
                padding: const EdgeInsets.all(20),
                child: Theme(
                  data: dropdownTheme,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Important for shrink wrapping
                    children: [
                          if (_tabController.index == 0) ...[
                             // --- Building Mode ---
                             Text("Navigates between Main Entrances.", style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 0.5)),
                             const SizedBox(height: 12),
                             // From Building
                             DropdownButtonFormField<Building>(
                                decoration: inputDecoration('From Building', Icons.my_location),
                                dropdownColor: darkCardColor,
                                style: const TextStyle(color: paperWhite),
                                value: _startBuilding,
                                items: [
                                  DropdownMenuItem(value: _getCampusBuilding(user?.organizationId), child: const Text('Campus / Outdoor', style: TextStyle(color: paperWhite))),
                                  ...buildings.map((b) => DropdownMenuItem(value: b, child: Text(b.name, style: const TextStyle(color: paperWhite)))).toList()
                                ],
                                onChanged: (val) => setState(() => _startBuilding = val),
                             ),
                             const SizedBox(height: 12),
                             // To Building
                             DropdownButtonFormField<Building>(
                                decoration: inputDecoration('To Building', Icons.place),
                                dropdownColor: darkCardColor,
                                style: const TextStyle(color: paperWhite),
                                value: _endBuilding,
                                items: [
                                  DropdownMenuItem(value: _getCampusBuilding(user?.organizationId), child: const Text('Campus / Outdoor', style: TextStyle(color: paperWhite))),
                                  ...buildings.map((b) => DropdownMenuItem(value: b, child: Text(b.name, style: const TextStyle(color: paperWhite)))).toList()
                                ],
                                onChanged: (val) => setState(() => _endBuilding = val),
                             ),
                          ] else ...[
                              // --- Room Mode ---
                              // FROM ROW
                              Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: DropdownButtonFormField<Building>(
                                      isExpanded: true,
                                      dropdownColor: darkCardColor,
                                      decoration: inputDecoration('From Bldg', Icons.apartment),
                                      style: const TextStyle(color: paperWhite, fontSize: 13),
                                      value: _startBuilding,
                                      items: [
                                        DropdownMenuItem(value: _getCampusBuilding(user?.organizationId), child: const Text('Campus / Outdoor', style: TextStyle(color: paperWhite))),
                                        ...buildings.map((b) => DropdownMenuItem(value: b, child: Text(b.name, overflow: TextOverflow.ellipsis))).toList()
                                      ],
                                      onChanged: (val) => setState(() { _startBuilding = val; _startRoom = null; }),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 6,
                                    child: DropdownButtonFormField<Room>(
                                      isExpanded: true,
                                      dropdownColor: darkCardColor,
                                      decoration: inputDecoration('Room No', Icons.door_front_door),
                                      style: const TextStyle(color: paperWhite, fontSize: 13),
                                      value: _startRoom,
                                      items: _startBuilding == null ? [] : _getRoomsForBuilding(_startBuilding!.id)
                                          .map((r) => DropdownMenuItem(value: r, child: Text(r.name, overflow: TextOverflow.ellipsis))).toList(),
                                      onChanged: (val) => setState(() => _startRoom = val),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // TO ROW
                               Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: DropdownButtonFormField<Building>(
                                      isExpanded: true,
                                      dropdownColor: darkCardColor,
                                      decoration: inputDecoration('To Bldg', Icons.apartment),
                                      style: const TextStyle(color: paperWhite, fontSize: 13),
                                      value: _endBuilding,
                                      items: [
                                        DropdownMenuItem(value: _getCampusBuilding(user?.organizationId), child: const Text('Campus / Outdoor', style: TextStyle(color: paperWhite))),
                                        ...buildings.map((b) => DropdownMenuItem(value: b, child: Text(b.name, overflow: TextOverflow.ellipsis))).toList()
                                      ],
                                      onChanged: (val) => setState(() { _endBuilding = val; _endRoom = null; }),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 6,
                                    child: DropdownButtonFormField<Room>(
                                      isExpanded: true,
                                      dropdownColor: darkCardColor,
                                      decoration: inputDecoration('Room No', Icons.door_front_door),
                                      style: const TextStyle(color: paperWhite, fontSize: 13),
                                      value: _endRoom,
                                      items: _endBuilding == null ? [] : _getRoomsForBuilding(_endBuilding!.id)
                                          .map((r) => DropdownMenuItem(value: r, child: Text(r.name, overflow: TextOverflow.ellipsis))).toList(),
                                      onChanged: (val) => setState(() => _endRoom = val),
                                    ),
                                  ),
                                ],
                              ),
                          ]
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
               title: const Text('Accessible Route', style: TextStyle(color: paperWhite, fontSize: 14)),
               subtitle: Text('Prioritize elevators & ramps', style: TextStyle(color: paperWhite.withOpacity(0.5), fontSize: 11)),
               secondary: Icon(Icons.accessible_forward, color: ref.watch(navigationProvider).isAccessible ? electricGrid : Colors.grey),
               value: ref.watch(navigationProvider).isAccessible,
               activeColor: electricGrid,
               onChanged: (val) {
                  ref.read(navigationProvider.notifier).toggleAccessibility(val);
               },
               dense: true,
               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                shadowColor: const Color(0xFF4F46E5).withOpacity(0.5),
              ),
              onPressed: _onNavigate,
              child: const Text('Start Navigation', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          )
        ],
      ),
    ),
    );
  }
}
