import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:equatable/equatable.dart';

import '../../domain/usecases/add_corridor_usecase.dart';
import '../../domain/usecases/update_room_usecase.dart';
import '../../domain/usecases/get_corridors_usecase.dart';
import '../../domain/usecases/delete_room_usecase.dart';
import '../../domain/usecases/admin_map_usecases.dart';
import '../../domain/entities/map_entities.dart';
import '../providers/admin_map_providers.dart';

import 'package:indoor_navigation_system/core/services/compass_service.dart';
import 'package:indoor_navigation_system/core/services/pathfinding_service.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../../core/services/navigation_instruction_service.dart';

class FloorParams extends Equatable {
  final String buildingId;
  final String floorId;
  const FloorParams(this.buildingId, this.floorId);
  @override
  List<Object> get props => [buildingId, floorId];
}

final roomsProvider = FutureProvider.family<List<Room>, FloorParams>((ref, params) async {
  final getRoomsUseCase = ref.read(getRoomsUseCaseProvider);
  final result = await getRoomsUseCase(GetRoomsParams(params.buildingId, params.floorId));
  return result.fold(
    (failure) => throw failure.message,
    (rooms) => rooms,
  );
});

final corridorsProvider = FutureProvider.family<List<Corridor>, FloorParams>((ref, params) async {
  final getCorridorsUseCase = ref.read(getCorridorsUseCaseProvider);
  final result = await getCorridorsUseCase(GetCorridorsParams(params.buildingId, params.floorId));
  return result.fold(
    (failure) => throw failure.message,
    (corridors) => corridors,
  );
});

class FloorDetailScreen extends ConsumerStatefulWidget {
  final String buildingId;
  final String floorId;
  final String floorName;

  const FloorDetailScreen({
    super.key,
    required this.buildingId,
    required this.floorId,
    required this.floorName,
  });

  @override
  ConsumerState<FloorDetailScreen> createState() => _FloorDetailScreenState();
}

class _FloorDetailScreenState extends ConsumerState<FloorDetailScreen> {
  String? _selectedRoomId;
  bool _isLinkMode = false;
  bool _isNavMode = false; // Add navigation mode
  List<String> _currentPath = []; // IDs in path
  // Live positions for real-time edge updates
  // Live positions for real-time edge updates
  final Map<String, Offset> _livePositions = {};
  
  final TransformationController _transformController = TransformationController(); // For scale awareness

  // --- THEME COLORS ---
  static const deepVoidBlue = Color(0xFF020617);
  static const topLightBlue = Color(0xFF1E3A8A);
  static const electricGrid = Color(0xFF38BDF8);
  static const darkCardColor = Color(0xFF1A1F2C);
  static const paperWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    if (widget.buildingId.startsWith('campus_')) {
      // Auto-import buildings after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _importBuildings();
      });
    }
    
    // Check if we are mid-navigation
    final navState = ref.read(navigationProvider);
    if (navState.startRoom != null) {
      _isNavMode = true; 
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset live positions when dependencies change if needed?
    // Actually safe to keep empty, will populate on build or drag.
  }

  void _onRoomTap(Room room) async {
    if (_isLinkMode) {
      if (_selectedRoomId == null) {
        setState(() => _selectedRoomId = room.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected ${room.name}. Tap another room to link.')));
      } else if (_selectedRoomId != room.id) {
        _showLinkDialog(_selectedRoomId!, room.id);
        setState(() => _selectedRoomId = null);
      }
    } else if (_isNavMode) {
      final navNotifier = ref.read(navigationProvider.notifier);
      final navState = ref.read(navigationProvider);
      
      final orgId = GoRouterState.of(context).pathParameters['orgId'];
      
      if (navState.startRoom != null && navState.endRoom != null) {
        // Path is already showing. Reset and treat this as a NEW Start.
        navNotifier.clear();
        navNotifier.setStart(room, organizationId: orgId);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('New Start: ${room.name}. Tap destination.')));
      } else if (navState.startRoom == null) {
        navNotifier.setStart(room, organizationId: orgId);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Start: ${room.name}. Tap destination (switch floors if needed).')));
      } else {
        navNotifier.setEnd(room);
        _selectedRoomId = null;
      }
    } else {
        setState(() {
          _selectedRoomId = room.id;
        });
    }
  }


  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _showLinkDialog(String startId, String endId) {
    final distanceController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: darkCardColor,
        title: const Text('Add Corridor', style: TextStyle(color: paperWhite)),
        content: TextField(
          controller: distanceController,
          style: const TextStyle(color: paperWhite),
          decoration: const InputDecoration(labelText: 'Distance (meters)', labelStyle: TextStyle(color: Colors.white70), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30))),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final dist = double.tryParse(distanceController.text) ?? 1.0;
              final useCase = ref.read(addCorridorUseCaseProvider);
              await useCase(AddCorridorParams(
                widget.buildingId,
                widget.floorId,
                startId,
                endId,
                dist,
              ));
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Corridor Created!')));
                  ref.read(graphServiceProvider).markDirty();
                  ref.invalidate(corridorsProvider(FloorParams(widget.buildingId, widget.floorId)));
                }
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  void _addRoom() {
    final nameController = TextEditingController();
    final connectorIdController = TextEditingController();
    
    final isCampusMap = widget.buildingId.startsWith('campus_');
    
    // Filter available types
    final availableTypes = isCampusMap 
        ? [
            RoomType.entrance, // Most important for campus
            RoomType.hallway,  // Path nodes
            RoomType.parking,
            RoomType.ground,
            RoomType.cafeteria,
            RoomType.library,
            RoomType.restroom, 
            RoomType.room // Maybe keep generic 'room' for custom buildings? User said "no indoor things" 
            // Let's exclude Room, Stairs, Elevator, Office, Lab
          ].where((t) => t != RoomType.room).toList() // Explicitly remove room
        : RoomType.values.toList();
        
    RoomType selectedType = availableTypes.first;
    
    // Capture OrgId from parent context properly
    final orgId = GoRouterState.of(context).pathParameters['orgId'];
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isConnector = selectedType == RoomType.stairs || selectedType == RoomType.elevator || selectedType == RoomType.entrance;
          final isEntrance = selectedType == RoomType.entrance;
          
          return AlertDialog(
            backgroundColor: darkCardColor,
            title: Text(isCampusMap ? 'Add Campus Location' : 'Add Room/Node', style: const TextStyle(color: paperWhite)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: paperWhite),
                  decoration: InputDecoration(labelText: isCampusMap ? 'Name (e.g. Main Gate, Parking A)' : 'Name (e.g. Room 101, Stair A)', labelStyle: const TextStyle(color: Colors.white70), enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30))),
                ),
                const SizedBox(height: 16),
                DropdownButton<RoomType>(
                  value: selectedType,
                  isExpanded: true,
                  dropdownColor: darkCardColor,
                  style: const TextStyle(color: paperWhite),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedType = val);
                    // Auto-fill connectorId if Entrance and not campus (link to self)
                    if (val == RoomType.entrance && !isCampusMap) {
                      connectorIdController.text = widget.buildingId;
                    }
                  },
                  items: availableTypes.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  )).toList(),
                ),
                if (isConnector) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: connectorIdController,
                    style: const TextStyle(color: paperWhite),
                    decoration: const InputDecoration(
                      labelText: 'Connector ID',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                      helperText: 'Must match ID on other floors (e.g. "STAIR-A")',
                      helperStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                ],
                if (isEntrance) ...[
                  const SizedBox(height: 16),
                   // Fetch Buildings for Dropdown
                   FutureBuilder(
                     future: ref.read(buildingsProvider(orgId).future),
                     builder: (context, snapshot) {
                       if (!snapshot.hasData) return const LinearProgressIndicator();
                       final buildings = snapshot.data!;
                       // Exclude 'campus_' maps from the list
                       final validBuildings = buildings.where((b) => !b.id.startsWith('campus_')).toList();
                       
                       return DropdownButtonFormField<String>(
                         decoration: const InputDecoration(labelText: 'Link to Building ID (Usually this building)', labelStyle: TextStyle(color: Colors.white70)),
                         dropdownColor: darkCardColor,
                         style: const TextStyle(color: paperWhite),
                         value: connectorIdController.text.isNotEmpty && validBuildings.any((b) => b.id == connectorIdController.text) ? connectorIdController.text : null,
                         items: validBuildings.map((b) => DropdownMenuItem(
                           value: b.id,
                           child: Text(b.name),
                         )).toList(),
                         onChanged: (val) {
                            if (val != null) connectorIdController.text = val;
                         },
                       );
                     }
                   ),
                   const Text('Matches the Building ID for campus navigation.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ]
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  final useCase = ref.read(addRoomUseCaseProvider);
                  await useCase(AddRoomParams(
                    buildingId: widget.buildingId,
                    floorId: widget.floorId,
                    name: nameController.text.trim(),
                    x: 150.0,
                    y: 150.0,
                    type: selectedType,
                    connectorId: isConnector ? connectorIdController.text.trim() : null,
                  ));
                  ref.read(graphServiceProvider).markDirty();
                  ref.invalidate(roomsProvider(FloorParams(widget.buildingId, widget.floorId)));
                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('Add'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _deleteSelectedRoom() async {
    if (_selectedRoomId == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: darkCardColor,
        title: const Text('Delete Node?', style: TextStyle(color: paperWhite)),
        content: const Text('Are you sure you want to delete this room/node? This will also break connected corridors.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
       final useCase = ref.read(deleteRoomUseCaseProvider);
       await useCase(DeleteRoomParams(
         widget.buildingId, 
         widget.floorId, 
         _selectedRoomId!
       ));
       
       setState(() {
         _livePositions.remove(_selectedRoomId);
         _selectedRoomId = null;
       });
       
       ref.read(graphServiceProvider).markDirty();
       ref.invalidate(roomsProvider(FloorParams(widget.buildingId, widget.floorId)));
       ref.invalidate(corridorsProvider(FloorParams(widget.buildingId, widget.floorId)));
       
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    }
  }

  void _editSelectedRoom() async {
     if (_selectedRoomId == null) return;
     
     // 1. Find the current room object
     final rooms = await ref.read(roomsProvider(FloorParams(widget.buildingId, widget.floorId)).future);
     final room = rooms.firstWhere((r) => r.id == _selectedRoomId);
     
     final nameController = TextEditingController(text: room.name);
     final connectorController = TextEditingController(text: room.connectorId ?? '');
     RoomType selectedType = room.type;
     
     if (!mounted) return;
     
     showDialog(
       context: context, 
       builder: (ctx) => StatefulBuilder(
         builder: (context, setState) {
           final isConnector = selectedType == RoomType.stairs || selectedType == RoomType.elevator || selectedType == RoomType.entrance;
           
           return AlertDialog(
             backgroundColor: darkCardColor,
             title: const Text('Edit Node Details', style: TextStyle(color: paperWhite)),
             content: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                  TextField(
                    controller: nameController, 
                    decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white70), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30))),
                    style: const TextStyle(color: paperWhite),
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<RoomType>(
                    value: selectedType,
                    isExpanded: true,
                    dropdownColor: darkCardColor,
                    style: const TextStyle(color: paperWhite),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedType = val);
                    },
                    items: RoomType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()))).toList(),
                  ),
                  if (isConnector) ...[
                     const SizedBox(height: 16),
                     TextField(
                       controller: connectorController,
                       decoration: const InputDecoration(labelText: 'Connector ID', labelStyle: TextStyle(color: Colors.white70), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30))),
                       style: const TextStyle(color: paperWhite),
                     ),
                  ]
               ],
             ),
             actions: [
               TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
               TextButton(
                 onPressed: () async {
                    // Update
                    final updateUseCase = ref.read(updateRoomUseCaseProvider);
                    await updateUseCase(UpdateRoomUseParams(
                      buildingId: widget.buildingId,
                      floorId: widget.floorId,
                      roomId: room.id,
                      name: nameController.text,
                      type: selectedType,
                      connectorId: connectorController.text.isNotEmpty ? connectorController.text : null,
                    ));
                    
                    if (mounted) {
                      Navigator.pop(ctx);
                      ref.read(graphServiceProvider).markDirty();
                      ref.invalidate(roomsProvider(FloorParams(widget.buildingId, widget.floorId)));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Node Updated')));
                    }
                 },
                 child: const Text('Save'),
               )
             ],
           );
         },
       )
     );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: darkCardColor,
        title: const Text('Editor Guide', style: TextStyle(color: paperWhite)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('How to Model Corridors:', style: TextStyle(fontWeight: FontWeight.bold, color: electricGrid)),
              SizedBox(height: 8),
              Text('1. Place Nodes (Small Circles) at corners and intersections.', style: TextStyle(color: Colors.white70)),
              Text('2. Place Rooms (Blue Boxes) where they belong.', style: TextStyle(color: Colors.white70)),
              Text('3. Link Room → Node to connect a room to the hallway.', style: TextStyle(color: Colors.white70)),
              Text('4. Link Node → Node to draw the hallway path.', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 16),
              Text('Example Structure:', style: TextStyle(fontWeight: FontWeight.bold, color: electricGrid)),
              Text('[C101] — [Node] ——— [Node] — [A101]', style: TextStyle(fontFamily: 'Courier', color: Colors.white70)),
              Text('             |          |', style: TextStyle(fontFamily: 'Courier', color: Colors.white70)),
              Text('[C102] — [Node] ——— [Node] — [A102]', style: TextStyle(fontFamily: 'Courier', color: Colors.white70)),
              
              SizedBox(height: 16),
              Text('Types:', style: TextStyle(fontWeight: FontWeight.bold, color: electricGrid)),
              Text('• Room: Destination (Office, Class)', style: TextStyle(color: Colors.white70)),
              Text('• Hallway/Node: Turning point (Invisible)', style: TextStyle(color: Colors.white70)),
              Text('• Stairs/Elevator: Vertical travel', style: TextStyle(color: Colors.white70)),
              Text('• Entrance: Building exit/entry', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
        ],
      ),
    );
  }
  
  // Helper to get current display position
  Offset _getRoomPosition(Room room) {
    return _livePositions[room.id] ?? Offset(room.x, room.y);
  }

  void _showInstructionsModal(BuildContext context, List<NavigationInstruction> instructions) {
   showModalBottomSheet(
          context: context, 
          backgroundColor: Colors.transparent, // For custom decoration
          isScrollControlled: true,
          builder: (ctx) => Container(
            padding: const EdgeInsets.all(24),
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: darkCardColor.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: const Border(top: BorderSide(color: electricGrid, width: 2)),
              boxShadow: [
                BoxShadow(color: electricGrid.withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     const Text('NAVIGATION STEPS', style: TextStyle(
                       fontSize: 16, 
                       fontWeight: FontWeight.bold, 
                       fontFamily: 'Courier', 
                       letterSpacing: 1.5,
                       color: paperWhite
                     )),
                     IconButton(
                       icon: const Icon(Icons.close, color: Colors.white54), 
                       onPressed: () => Navigator.pop(context)
                     ),
                   ],
                 ),
                 Divider(color: electricGrid.withOpacity(0.3)),
                 Expanded(
                   child: ListView.separated(
                     padding: const EdgeInsets.only(top: 16),
                     itemCount: instructions.length,
                     separatorBuilder: (_, __) => Padding(
                       padding: const EdgeInsets.only(left: 56), // Align with text start
                       child: Divider(color: Colors.white10, height: 24),
                     ),
                     itemBuilder: (context, index) {
                       final step = instructions[index];
                       IconData icon;
                       switch(step.icon) {
                         case 'left': icon = Icons.turn_left; break;
                         case 'right': icon = Icons.turn_right; break;
                         case 'straight': icon = Icons.arrow_upward; break;
                         case 'stairs_up': icon = Icons.stairs; break;
                         case 'stairs_down': icon = Icons.stairs_outlined; break;
                         case 'finish': icon = Icons.flag; break;
                         case 'error': icon = Icons.error; break;
                         default: icon = Icons.circle;
                       }
                       
                       return Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           // Step Indicator
                           Container(
                             padding: const EdgeInsets.all(10),
                             decoration: BoxDecoration(
                               color: electricGrid.withOpacity(0.1),
                               shape: BoxShape.circle,
                               border: Border.all(color: electricGrid.withOpacity(0.5))
                             ),
                             child: Icon(icon, size: 20, color: electricGrid),
                           ),
                           const SizedBox(width: 16),
                           // Step Text
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   step.message, 
                                   style: const TextStyle(
                                     color: paperWhite, 
                                     fontWeight: FontWeight.w600,
                                     fontSize: 14,
                                   )
                                 ),
                                 if (step.distance > 0)
                                   Padding(
                                     padding: const EdgeInsets.only(top: 4),
                                     child: Text(
                                       '${step.distance.toStringAsFixed(1)} m',
                                       style: TextStyle(
                                         color: electricGrid.withOpacity(0.8),
                                         fontSize: 12,
                                         fontWeight: FontWeight.bold,
                                         fontFamily: 'Courier'
                                       ),
                                     ),
                                   ),
                               ],
                             ),
                           ),
                         ],
                       );
                     },
                   ),
                 ),
              ],
            ),
          )
        );
  }

  Future<void> _importBuildings() async {
    final params = GoRouterState.of(context).pathParameters;
    final orgId = params['orgId'];
    
    final buildings = await ref.read(buildingsProvider(orgId).future);
    final currentRooms = await ref.read(roomsProvider(FloorParams(widget.buildingId, widget.floorId)).future);
    
    int importedCount = 0;
    final addRoom = ref.read(addRoomUseCaseProvider);
    
    for (int i = 0; i < buildings.length; i++) {
      final b = buildings[i];
      // Check if a node with this connector ID (Building ID) already exists
      final exists = currentRooms.any((r) => r.connectorId == b.id);
      
      // Exclude self and any other special maps starting with campus_
      if (!exists && !b.id.startsWith('campus_')) {
        // Create Entrance Node for this Building
        await addRoom(AddRoomParams(
          buildingId: widget.buildingId, 
          floorId: widget.floorId, 
          name: b.name, 
          x: 100.0 + (importedCount * 60), 
          y: 200.0, 
          type: RoomType.entrance,
          connectorId: b.id,
        ));
        importedCount++;
      }
    }
    
    if (importedCount > 0) {
      ref.invalidate(roomsProvider(FloorParams(widget.buildingId, widget.floorId)));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $importedCount buildings')));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All buildings already mapped')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = FloorParams(widget.buildingId, widget.floorId);
    final roomsAsync = ref.watch(roomsProvider(params));
    final corridorsAsync = ref.watch(corridorsProvider(params));
    
    // Watch Navigation State
    final navState = ref.watch(navigationProvider);
    
    final currentPath = navState.pathIds;
    
    ref.listen(navigationProvider, (previous, next) {
      if (_isNavMode && next.pathIds.isNotEmpty && next.pathIds != previous?.pathIds) {
         _showInstructionsModal(context, next.instructions);
      }
    });

    return Scaffold(
      backgroundColor: deepVoidBlue,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'MAP EDITOR',
              style: TextStyle(
                fontFamily: 'Courier', 
                fontWeight: FontWeight.bold, 
                letterSpacing: 2,
                fontSize: 10,
                color: electricGrid
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.floorName.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                fontSize: 16,
                color: paperWhite
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: deepVoidBlue.withOpacity(0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: electricGrid),
        actions: [
          if (_selectedRoomId != null) ...[
             IconButton(
               icon: const Icon(Icons.edit, color: electricGrid),
               tooltip: 'Edit Node',
               onPressed: () => _editSelectedRoom(),
             ),
             IconButton(
               icon: const Icon(Icons.delete, color: Colors.redAccent),
               tooltip: 'Delete Selected',
               onPressed: _deleteSelectedRoom,
             ),
          ],

          IconButton(
            icon: Icon(_isLinkMode ? Icons.link_off : Icons.link, color: _isLinkMode ? electricGrid : Colors.white54),
            tooltip: 'Toggle Link Mode',
            onPressed: () {
              setState(() {
                _isLinkMode = !_isLinkMode;
                _isNavMode = false; // exclusive
                _selectedRoomId = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_isLinkMode ? 'Link Mode: ON. Tap two rooms to connect.' : 'Link Mode: OFF'))
              );
            },
          ),
          IconButton(
            icon: Icon(_isNavMode ? Icons.directions_off : Icons.directions, color: _isNavMode ? electricGrid : Colors.white54),
            tooltip: 'Test Navigation',
            onPressed: () {
               setState(() {
                 _isNavMode = !_isNavMode;
                 _isLinkMode = false;
                 _selectedRoomId = null;
                 _currentPath = [];
                 ref.read(navigationProvider.notifier).clear();
               });
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_isNavMode ? 'Nav Mode: ON. Select Start then End.' : 'Nav Mode: OFF'))
              );
            },
          ),
          
          if (_isNavMode)
            IconButton(
              icon: Icon(Icons.accessible, color: navState.isAccessible ? electricGrid : Colors.white54),
              tooltip: navState.isAccessible ? 'Accessible Mode: ON' : 'Accessible Mode: OFF',
              onPressed: () {
                 ref.read(navigationProvider.notifier).toggleAccessibility(!navState.isAccessible);
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(navState.isAccessible ? 'Accessibility OFF' : 'Accessibility ON'))
                 );
              },
            ),

          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white54),
            tooltip: 'Editor Guide',
            onPressed: _showHelpDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: electricGrid.withOpacity(0.2), height: 1.0),
        ),
      ),
      body: Stack(
        children: [
            // 0. GRADIENT BACKGROUND
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [topLightBlue, deepVoidBlue],
                  stops: [0.0, 0.8],
                ),
              ),
            ),
            
            // 1. CONTENT
            SafeArea(
              child: roomsAsync.when(
                data: (rooms) => corridorsAsync.when(
                  data: (corridors) {
                     return InteractiveViewer(
                      transformationController: _transformController,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      minScale: 0.1,
                      maxScale: 4.0,
                      constrained: false, // Allow unbounded child natural size
                      alignment: Alignment.topLeft, // Start at 0,0 so nodes are visible
                      child: SizedBox(
                        width: 15000, 
                        height: 15000,
                        child: Stack(
                          children: [
                            // Grid
                            Positioned.fill(child: CustomPaint(painter: GridPainter())),
                            
                            // Edges (using Live Positions)
                            Positioned.fill(child: CustomPaint(
                              painter: EdgePainter(
                                rooms: rooms, 
                                corridors: corridors,
                                positions: _livePositions,
                                pathIds: currentPath, // Pass global nav path
                              ),
                            )),
                            
                            // Nodes
                            for (final room in rooms)
                              Positioned(
                                left: _getRoomPosition(room).dx,
                                top: _getRoomPosition(room).dy,
                                child: DraggableRoomNode(
                                  key: ValueKey(room.id),
                                  room: room,
                                  position: _getRoomPosition(room),
                                  isSelected: _selectedRoomId == room.id || 
                                             (_isNavMode && navState.startRoom?.id == room.id) || 
                                             (_isNavMode && navState.endRoom?.id == room.id),
                                  onDragUpdate: (delta) {
                                    setState(() {
                                      final scale = _transformController.value.getMaxScaleOnAxis(); // Get current zooom
                                      final adjustedDelta = delta / scale;
                                      
                                      final current = _livePositions[room.id] ?? Offset(room.x, room.y);
                                      _livePositions[room.id] = current + adjustedDelta;
                                    });
                                  },
                                  onDragEnd: (_) async {
                                     // Finalize in Firestore using the LAST LIVE POSITION
                                     final finalOffset = _livePositions[room.id] ?? Offset(room.x, room.y);
                                     
                                     debugPrint("Updating room ${room.id} to ${finalOffset.dx}, ${finalOffset.dy}");
                                     final useCase = ref.read(updateRoomUseCaseProvider);
                                     await useCase(UpdateRoomUseParams(
                                       buildingId: widget.buildingId,
                                       floorId: widget.floorId,
                                       roomId: room.id,
                                       x: finalOffset.dx,
                                       y: finalOffset.dy,
                                     ));
                                     ref.read(graphServiceProvider).markDirty();
                                     ref.invalidate(roomsProvider(FloorParams(widget.buildingId, widget.floorId)));
                                     ref.invalidate(corridorsProvider(FloorParams(widget.buildingId, widget.floorId)));
                                  },
                                  onTap: () => _onRoomTap(room),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: electricGrid)),
                  error: (e, s) => Center(child: Text('Error loading corridors: $e', style: const TextStyle(color: Colors.redAccent))),
                ),
                loading: () => const Center(child: CircularProgressIndicator(color: electricGrid)),
                error: (e, s) => Center(child: Text('Error loading rooms: $e', style: const TextStyle(color: Colors.redAccent))),
              ),
            ),

            if (_isNavMode)
              Positioned(
                bottom: 30, 
                left: 20, 
                right: 90, 
                child: Consumer(builder: (context, ref, _) {
                    final heading = ref.watch(compassProvider) ?? 0.0;
                    
                    String getDirectionText(double h) {
                        if (h >= 337.5 || h < 22.5) return "North";
                        if (h >= 22.5 && h < 67.5) return "NE";
                        if (h >= 67.5 && h < 112.5) return "East";
                        if (h >= 112.5 && h < 157.5) return "SE";
                        if (h >= 157.5 && h < 202.5) return "South";
                        if (h >= 202.5 && h < 247.5) return "SW";
                        if (h >= 247.5 && h < 292.5) return "West";
                        return "NW";
                    }
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: darkCardColor.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: electricGrid.withOpacity(0.3)),
                          boxShadow: [BoxShadow(color: Colors.black26.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,4))]
                      ),
                      child: Row(
                          children: [
                               // Compass Circular Icon
                               Container(
                                  width: 36, height: 36,
                                  decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                                  child: Transform.rotate(
                                      angle: (heading * 3.14159 / 180),
                                      child: const Icon(Icons.navigation, color: electricGrid, size: 18),
                                  ),
                               ),
                               const SizedBox(width: 12),
                               
                               // Heading Text
                               SizedBox(
                                   width: 45,
                                   child: Column(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                           Text(getDirectionText(heading), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                           Text('${heading.toStringAsFixed(0)}°', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                       ]
                                   )
                               ),
                               
                               // Slider
                               Expanded(
                                   child: Column(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                           SizedBox(
                                               height: 20,
                                               child: SliderTheme(
                                                    data: SliderTheme.of(context).copyWith(
                                                        trackHeight: 2,
                                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                                        overlayShape: SliderComponentShape.noOverlay,
                                                        activeTrackColor: electricGrid,
                                                        inactiveTrackColor: Colors.grey[800],
                                                        thumbColor: Colors.white,
                                                    ),
                                                    child: Slider(
                                                       value: heading,
                                                       min: 0, max: 360,
                                                       onChanged: (v) => ref.read(compassProvider.notifier).setHeading(v),
                                                    ),
                                               ),
                                           ),
                                           
                                           // Tiny Labels
                                           Padding(
                                               padding: const EdgeInsets.symmetric(horizontal: 10),
                                               child: Row(
                                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                   children: const [
                                                       Text('N', style: TextStyle(color: Colors.white30, fontSize: 8)),
                                                       Text('E', style: TextStyle(color: Colors.white30, fontSize: 8)),
                                                       Text('S', style: TextStyle(color: Colors.white30, fontSize: 8)),
                                                       Text('W', style: TextStyle(color: Colors.white30, fontSize: 8)),
                                                       Text('N', style: TextStyle(color: Colors.white30, fontSize: 8)),
                                                   ],
                                               ),
                                           )
                                       ]
                                   )
                               ),
                               
                               const SizedBox(width: 8),
                               
                               // Live Button
                               IconButton(
                                   icon: const Icon(Icons.my_location, color: Colors.greenAccent, size: 20),
                                   tooltip: 'Reset to Live',
                                   onPressed: () => ref.read(compassProvider.notifier).enableLive(),
                                   padding: EdgeInsets.zero,
                                   constraints: const BoxConstraints(),
                                   visualDensity: VisualDensity.compact,
                               )
                          ],
                      ),
                    );
                }),
              ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'node',
            onPressed: () {
               final useCase = ref.read(addRoomUseCaseProvider);
               useCase(AddRoomParams(
                  buildingId: widget.buildingId,
                  floorId: widget.floorId,
                  name: "Node ${DateTime.now().millisecond}",
                  x: 150.0,
                  y: 150.0,
                  type: RoomType.hallway,
               )).then((_) => ref.invalidate(roomsProvider(params)));
            },
            backgroundColor: darkCardColor,
            foregroundColor: electricGrid,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: electricGrid),
            ),
            child: const Icon(Icons.circle, size: 10),
            tooltip: 'Add Turn/Node',
          ),

          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _addRoom(),
            backgroundColor: electricGrid,
            foregroundColor: deepVoidBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class DraggableRoomNode extends StatefulWidget {
  final Room room;
  final Offset position;
  final bool isSelected;
  final Function(Offset) onDragUpdate; // Passes delta now
  final Function(Offset) onDragEnd; // Passes nothing (ignored), logic uses state
  final VoidCallback onTap;

  const DraggableRoomNode({
    super.key, 
    required this.room, 
    required this.position,
    required this.isSelected, 
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTap,
  });

  @override
  State<DraggableRoomNode> createState() => _DraggableRoomNodeState();
}

class _DraggableRoomNodeState extends State<DraggableRoomNode> {
  // We use parent provided position now, but to avoid jitter, we can track local pan
  // Actually, parent controls position now via onDragUpdate -> setState

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData? icon;
    double size = 60;
    
    switch (widget.room.type) {
      case RoomType.room:
        color = Colors.blueAccent;
        break;
      case RoomType.hallway:
        color = Colors.grey;
        size = 30; // Small node
        break;
      case RoomType.stairs:
        color = Colors.green;
        icon = Icons.stairs;
        break;
      case RoomType.elevator:
        color = Colors.purple;
        icon = Icons.elevator;
        break;
      case RoomType.entrance:
        color = Colors.redAccent;
        icon = Icons.door_back_door;
        break;
      case RoomType.restroom:
        color = Colors.cyan;
        icon = Icons.wc;
        break;
      case RoomType.cafeteria:
        color = Colors.orange;
        icon = Icons.local_cafe;
        break;
      case RoomType.lab:
        color = Colors.teal;
        icon = Icons.science;
        break;
      case RoomType.library:
        color = Colors.brown;
        icon = Icons.local_library;
        break;
      case RoomType.parking:
        color = Colors.blueGrey;
        icon = Icons.local_parking;
        break;
      case RoomType.ground:
        color = Colors.lightGreen;
        icon = Icons.grass;
        break;
      case RoomType.office:
        color = Colors.indigo;
        icon = Icons.business;
        break;
    }
    
    if (widget.isSelected) color = Colors.amber; // Selection overrides

    return GestureDetector(
      onPanUpdate: (details) {
        widget.onDragUpdate(details.delta);
      },
      onPanEnd: (details) {
        widget.onDragEnd(Offset.zero); // Argument ignored by parent
      },
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(widget.room.type == RoomType.hallway ? 15 : 8),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Icon(icon ?? Icons.circle, color: Colors.white, size: widget.room.type == RoomType.hallway ? 0 : 20),
          ),
          if (widget.room.type != RoomType.hallway)
            Container(
               margin: const EdgeInsets.only(top: 4),
               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
               decoration: BoxDecoration(
                 color: Colors.black54,
                 borderRadius: BorderRadius.circular(4),
               ),
               child: Text(
                  widget.room.name, 
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
            ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    
    final paint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.1) // electricGrid with low opacity
      ..strokeWidth = 1;
      
    const step = 40.0;
    
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EdgePainter extends CustomPainter {
  final List<Room> rooms;
  final List<Corridor> corridors;
  final Map<String, Offset> positions; // Live positions
  final List<String> pathIds; // Highlighted path

  EdgePainter({
    required this.rooms, 
    required this.corridors,
    required this.positions,
    this.pathIds = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.5) // electricGrid with mid opacity for edges
      ..strokeWidth = 3 // Thicker for visibility
      ..style = PaintingStyle.stroke;

    for (final corridor in corridors) {
      try {
        final startRoom = rooms.firstWhere((r) => r.id == corridor.startRoomId);
        final endRoom = rooms.firstWhere((r) => r.id == corridor.endRoomId);
        
        // Get live position if available, else static
        final startPos = positions[startRoom.id] ?? Offset(startRoom.x, startRoom.y);
        final endPos = positions[endRoom.id] ?? Offset(endRoom.x, endRoom.y);
        
        bool isPathEdge = false;
        if (pathIds.length > 1) {
           // Check if this corridor is part of the path sequence
           for (int i=0; i < pathIds.length - 1; i++) {
              final a = pathIds[i];
              final b = pathIds[i+1];
              if ((corridor.startRoomId == a && corridor.endRoomId == b) || 
                  (corridor.startRoomId == b && corridor.endRoomId == a)) {
                 isPathEdge = true;
                 break;
              }
           }
        }

        final drawPaint = isPathEdge 
            ? (Paint()..color = Colors.redAccent..strokeWidth = 5..style = PaintingStyle.stroke) 
            : paint;

        // Add 30 to center
        canvas.drawLine(startPos + const Offset(30, 30), endPos + const Offset(30, 30), drawPaint);
      } catch (e) {
        // Room missing
      }
    }
  }

  @override
  bool shouldRepaint(covariant EdgePainter oldDelegate) {
    return true; // Always repaint when positions map updates (handled by parent setState)
  }
}
