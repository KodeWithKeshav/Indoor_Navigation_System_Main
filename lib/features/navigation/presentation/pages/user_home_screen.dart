import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../admin_map/presentation/providers/admin_map_providers.dart';
import '../../../admin_map/domain/entities/map_entities.dart';
import '../../../admin_map/presentation/pages/floor_detail_screen.dart';
import '../../../admin_map/presentation/pages/building_detail_screen.dart';
import '../providers/user_location_provider.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/navigation_provider.dart';
import '../widgets/path_arrow_painter.dart';
import '../../../../core/providers/settings_provider.dart';
import '../widgets/trip_planner_widget.dart';
import '../../../../core/services/compass_service.dart';

import 'package:indoor_navigation_system/features/auth/presentation/providers/auth_providers.dart';
import 'user_profile_screen.dart';
import 'support_screen.dart';


// --- Theme Constants (Deep Void) ---
const Color deepVoidBlue = Color(0xFF0F172A);
const Color topLightBlue = Color(0xFF1E3A8A); 
const Color electricGrid = Color(0xFF38BDF8); 
const Color darkCardColor = Color(0xFF1E293B);
const Color paperWhite = Color(0xFFE2E8F0);




/// The main user interface for the navigation feature.
///
/// Handles graph building, displaying the map, navigation controls, and
/// access to settings and profile.
class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() => _UserHomeScreenState();
}



class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {

  @override
  void initState() {
    super.initState();
    // Build the graph once the widget is ready, using the user's organization ID.
    WidgetsBinding.instance.addPostFrameCallback((_) {
       final user = ref.read(currentUserProvider);
       if (user != null && user.organizationId.isNotEmpty) {
          ref.read(graphServiceProvider).buildGraph(organizationId: user.organizationId);
       }
    });
  }

  /// Displays the accessibility settings dialog.
  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
      showDialog(
        context: context, 
        builder: (context) => Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(settingsProvider);
            final notifier = ref.read(settingsProvider.notifier);
            
            return AlertDialog(
              backgroundColor: darkCardColor,
              title: const Text('Accessibility Settings', style: TextStyle(color: paperWhite)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const SizedBox(height: 16),
                  const Text('Text Size', style: TextStyle(color: paperWhite)),
                  Slider(
                    value: settings.textScaleFactor,
                    min: 0.8,
                    max: 1.6,
                    divisions: 4,
                    label: '${(settings.textScaleFactor * 100).round()}%',
                    activeColor: electricGrid,
                    onChanged: (val) => notifier.setTextScale(val),
                  ),
                  SwitchListTile(
                    title: const Text('Voice Guidance', style: TextStyle(color: paperWhite)),
                    value: settings.isVoiceEnabled,
                    activeColor: electricGrid,
                    onChanged: (val) => notifier.toggleVoice(val),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: electricGrid))),
              ],
            );
          }
        )
      );
  }



  /// Shows a dialog to select a building and floor for viewing the map.
  void _showMapDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _MapSelectionDialog(),
    );
  }



  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final navState = ref.watch(navigationProvider); // Removed locationState as map is gone
    final settings = ref.watch(settingsProvider);
    
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(settings.textScaleFactor)),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: deepVoidBlue,
        appBar: AppBar(
          title: Column(
            children: const [
               Text(
                'NAVIGATOR',
                style: TextStyle(
                  fontFamily: 'Courier', 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 2,
                  fontSize: 12,
                  color: electricGrid
                ),
              ),
               SizedBox(height: 2),
               Text(
                'STUDENT PORTAL',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: paperWhite
                ),
              ),
            ],
          ),
          centerTitle: true,
          backgroundColor: deepVoidBlue.withOpacity(0.8),
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [deepVoidBlue, deepVoidBlue.withOpacity(0.5)],
              ),
              border: const Border(bottom: BorderSide(color: electricGrid, width: 1)),
              boxShadow: [BoxShadow(color: electricGrid.withOpacity(0.2), blurRadius: 15, spreadRadius: 1)],
            ),
          ),
          iconTheme: const IconThemeData(color: electricGrid),
          actions: [
            if (navState.isNavigating)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.redAccent),
                tooltip: 'Clear Navigation',
                onPressed: () => ref.read(navigationProvider.notifier).clear(),
              ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () => _showSettingsDialog(context, ref),
            ),
            IconButton(
               icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
               tooltip: 'Logout',
               onPressed: () => ref.read(authControllerProvider.notifier).logout(context),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: electricGrid,
          foregroundColor: deepVoidBlue,
          onPressed: () => _showMapDialog(context),
          child: const Icon(Icons.map),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [topLightBlue, deepVoidBlue],
            ),
          ),
          child: Stack(
            children: [
              // 1. Trip Planner (Centered vs Top)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
                top: navState.isNavigating ? (kToolbarHeight + 50) : (MediaQuery.of(context).size.height / 2 - 180), // Approx center
                left: 16,
                right: 16,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    cardColor: darkCardColor.withOpacity(0.9),
                    textTheme: Theme.of(context).textTheme.apply(bodyColor: paperWhite, displayColor: paperWhite),
                    inputDecorationTheme: InputDecorationTheme(
                      fillColor: Colors.white.withOpacity(0.05),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                  child: TripPlannerWidget(
                    key: ValueKey('planner_${settings.isHighContrast}'),
                  ),
                ),
              ),

              // 2. Navigation Instructions (Bottom Overlay)
              if (navState.isNavigating)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height * 0.45, // Increased height since map is gone
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                             Text(
                               'NEXT STEPS', 
                               style: const TextStyle(
                                 color: paperWhite, 
                                 fontWeight: FontWeight.bold, 
                                 fontFamily: 'Courier',
                                 fontSize: 14,
                                 letterSpacing: 1.5
                               )
                             ),
                             Text(
                               '${navState.instructions.length} STEPS',
                               style: const TextStyle(color: electricGrid, fontSize: 10, fontWeight: FontWeight.bold),
                             )
                           ],
                        ),
                        Divider(color: electricGrid.withOpacity(0.3)),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.only(top: 8),
                            separatorBuilder: (_, __) => Divider(color: Colors.white10, height: 16),
                            itemCount: navState.instructions.length,
                            itemBuilder: (context, index) {
                              final step = navState.instructions[index];
                              IconData icon;
                              switch(step.icon) {
                                case 'left': icon = Icons.turn_left; break;
                                case 'right': icon = Icons.turn_right; break;
                                case 'straight': icon = Icons.arrow_upward; break;
                                case 'stairs_up': icon = Icons.stairs; break;
                                case 'stairs_down': icon = Icons.stairs_outlined; break;
                                case 'elevator_up': icon = Icons.elevator; break;
                                case 'elevator_down': icon = Icons.elevator_outlined; break;
                                case 'finish': icon = Icons.flag; break;
                                default: icon = Icons.circle;
                              }
                              return Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: electricGrid.withOpacity(0.1),
                                    radius: 18, // Slightly bigger
                                    child: Icon(icon, color: electricGrid, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(step.message, style: const TextStyle(color: paperWhite, fontWeight: FontWeight.w600, fontSize: 14)),
                                         if (step.distance > 0)
                                            Text(
                                              'Walk ${step.distance.toStringAsFixed(0)}m', 
                                              style: TextStyle(color: electricGrid.withOpacity(0.8), fontSize: 12, fontFamily: 'Courier', fontWeight: FontWeight.bold)
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
                  ),
                ),

              // 3. Compass Widget (Restored)
              if (navState.isNavigating)
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.45 + 16, 
                  right: 16,
                  child: Consumer(builder: (context, ref, _) {
                      final heading = ref.watch(compassProvider) ?? 0.0;
                    
                      String getDirectionText(double h) {
                          if (h >= 337.5 || h < 22.5) return "N";
                          if (h >= 22.5 && h < 67.5) return "NE";
                          if (h >= 67.5 && h < 112.5) return "E";
                          if (h >= 112.5 && h < 157.5) return "SE";
                          if (h >= 157.5 && h < 202.5) return "S";
                          if (h >= 202.5 && h < 247.5) return "SW";
                          if (h >= 247.5 && h < 292.5) return "W";
                          return "NW";
                      }
                      
                      return Container(
                        width: 260, // Fixed width for slider
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                            color: darkCardColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: electricGrid.withOpacity(0.5), width: 1.5),
                            boxShadow: [
                              BoxShadow(color: electricGrid.withOpacity(0.1), blurRadius: 10, spreadRadius: 1),
                              const BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))
                            ]
                        ),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                 Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: electricGrid.withOpacity(0.1), 
                                      shape: BoxShape.circle,
                                      border: Border.all(color: electricGrid.withOpacity(0.3))
                                    ),
                                    alignment: Alignment.center,
                                    child: Transform.rotate(
                                        angle: -(heading * 3.14159 / 180),
                                        child: const Icon(Icons.navigation, color: electricGrid, size: 16),
                                    ),
                                 ),
                                 const SizedBox(width: 12),
                                 Expanded(
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         children: [
                                           Text(
                                             getDirectionText(heading), 
                                             style: const TextStyle(
                                               color: paperWhite, 
                                               fontWeight: FontWeight.bold, 
                                               fontSize: 12,
                                               letterSpacing: 1
                                             )
                                           ),
                                           Text(
                                             '${heading.toStringAsFixed(0)}°', 
                                             style: TextStyle(color: electricGrid.withOpacity(0.8), fontSize: 10, fontFamily: 'Courier')
                                           ),
                                         ],
                                       ),
                                        SizedBox(
                                         height: 14,
                                         child: SliderTheme(
                                              data: SliderTheme.of(context).copyWith(
                                                  trackHeight: 2,
                                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                                  overlayShape: SliderComponentShape.noOverlay,
                                                  activeTrackColor: electricGrid,
                                                  inactiveTrackColor: Colors.grey[700],
                                                  thumbColor: paperWhite,
                                              ),
                                              child: Slider(
                                                 value: heading,
                                                 min: 0, max: 360,
                                                 onChanged: (v) => ref.read(compassProvider.notifier).setHeading(v),
                                              ),
                                         ),
                                     ),
                                     ],
                                   ),
                                 ),
                                 const SizedBox(width: 8),
                                 // Reset Button
                                 InkWell(
                                   onTap: () => ref.read(compassProvider.notifier).enableLive(),
                                   borderRadius: BorderRadius.circular(20),
                                   child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                                        shape: BoxShape.circle
                                      ),
                                      child: const Icon(Icons.my_location, color: Colors.greenAccent, size: 12)
                                   ),
                                 )
                            ],
                        ),
                      );
                  }),
                ),
              ],
            ),
          ),
        drawer: Drawer(
          backgroundColor: deepVoidBlue,
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [topLightBlue, deepVoidBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(bottom: BorderSide(color: electricGrid)),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: electricGrid.withOpacity(0.2),
                  child: Text(
                    user?.email.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(color: electricGrid, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                accountName: Text(
                   user?.role == 'student' ? 'Student Portal' : 'Guest User',
                   style: const TextStyle(color: paperWhite, fontWeight: FontWeight.bold)
                ),
                accountEmail: Text(
                  user?.email ?? 'guest@example.com',
                  style: TextStyle(color: paperWhite.withOpacity(0.7)),
                ),
              ),
               ListTile(
                 leading: const Icon(Icons.person_outline, color: electricGrid),
                 title: const Text('My Profile', style: TextStyle(color: paperWhite)),
                 onTap: () {
                   Navigator.pop(context);
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()));
                 },
              ),
               ListTile(
                 leading: const Icon(Icons.help_outline, color: electricGrid),
                 title: const Text('Help & Support', style: TextStyle(color: paperWhite)),
                 onTap: () {
                   Navigator.pop(context);
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
                 },
              ),
               ListTile(
                 leading: const Icon(Icons.info_outline, color: electricGrid),
                 title: const Text('About', style: TextStyle(color: paperWhite)),
                 onTap: () {
                   Navigator.pop(context);
                   showDialog(
                     context: context,
                     builder: (ctx) => AlertDialog(
                       backgroundColor: darkCardColor,
                       title: const Text("Indoor Navigator", style: TextStyle(color: electricGrid)),
                       content: const Text(
                         "Version 1.0.0\n\nNavigate your campus with ease.\n\n© 2026 Indoor Navigation System",
                         style: TextStyle(color: paperWhite),
                       ),
                       actions: [
                         TextButton(
                           onPressed: () => Navigator.pop(ctx), 
                           child: const Text("Close", style: TextStyle(color: electricGrid))
                         )
                       ],
                     )
                   );
                 },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: electricGrid.withOpacity(0.3)),
              ),
               ListTile(
                 leading: const Icon(Icons.settings_accessibility, color: paperWhite),
                 title: const Text('Accessibility Settings', style: TextStyle(color: paperWhite)),
                 onTap: () {
                   Navigator.pop(context);
                   _showSettingsDialog(context, ref);
                 },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ListTile(
                   leading: const Icon(Icons.power_settings_new, color: Colors.redAccent),
                   title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                   onTap: () {
                      ref.read(authControllerProvider.notifier).logout(context);
                   },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for selecting a building and floor to view.
class _MapSelectionDialog extends ConsumerStatefulWidget {
  const _MapSelectionDialog();

  @override
  ConsumerState<_MapSelectionDialog> createState() => _MapSelectionDialogState();
}

class _MapSelectionDialogState extends ConsumerState<_MapSelectionDialog> {
  String? _selectedBuildingId;
  String? _selectedFloorId;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final buildingsAsync = ref.watch(buildingsProvider(user?.organizationId));

    // Handle Initialization once buildings are loaded
    ref.listen(buildingsProvider(user?.organizationId), (prev, next) {
      if (!_initialized && next.hasValue && next.value!.isNotEmpty) {
           _initializeSelection(next.value!);
      }
    });
    
    // Also try to init if data is already there on first build
    if (!_initialized && buildingsAsync.hasValue && buildingsAsync.value!.isNotEmpty) {
       // Defer to post frame to avoid build conflicts
       WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_initialized) {
             _initializeSelection(buildingsAsync.value!);
          }
       });
    }

    return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: deepVoidBlue.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: electricGrid, width: 1.5),
            boxShadow: [
              BoxShadow(color: electricGrid.withOpacity(0.2), blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: electricGrid.withOpacity(0.3))),
                  gradient: LinearGradient(colors: [electricGrid.withOpacity(0.1), Colors.transparent])
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Row(
                       children: const [
                         Icon(Icons.map, color: electricGrid),
                         SizedBox(width: 8),
                         Text('CAMPUS MAP', style: TextStyle(color: paperWhite, fontFamily: 'Courier', fontWeight: FontWeight.bold, letterSpacing: 1)),
                       ],
                     ),
                     IconButton(
                       icon: const Icon(Icons.close, color: electricGrid),
                       onPressed: () => Navigator.pop(context),
                     )
                  ],
                ),
              ),
              
              // Selectors
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Building Selector
                    Expanded(
                      flex: 3,
                        child: buildingsAsync.when(
                          data: (buildings) {
                             final validBuildings = buildings.where((b) => !b.id.startsWith('campus_')).toList();
                             final campusBuilding = buildings.where((b) => b.id.startsWith('campus_')).firstOrNull;
                             
                             if (validBuildings.isEmpty && campusBuilding == null) return const Text("No buildings", style: TextStyle(color: Colors.white54));
                             
                             return Row(
                               children: [
                                 Expanded(
                                   child: DropdownButtonFormField<String>(
                                     value: _selectedBuildingId != null && !_selectedBuildingId!.startsWith('campus_') ? _selectedBuildingId : null,
                                     decoration: InputDecoration(
                                       labelText: 'Building',
                                       labelStyle: const TextStyle(color: electricGrid),
                                       enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: electricGrid.withOpacity(0.3))),
                                       focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: electricGrid)),
                                       filled: true,
                                       fillColor: darkCardColor,
                                       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                                     ),
                                     dropdownColor: darkCardColor,
                                     style: const TextStyle(color: paperWhite),
                                     items: validBuildings.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name, overflow: TextOverflow.ellipsis))).toList(),
                                     onChanged: (val) {
                                       if (val != null) _updateBuilding(val);
                                     }
                                   ),
                                 ),
                                 if (campusBuilding != null)
                                   Padding(
                                     padding: const EdgeInsets.only(left: 8.0),
                                     child: IconButton(
                                       onPressed: () => _updateBuilding(campusBuilding.id),
                                       tooltip: 'View Campus Map', 
                                       icon: Icon(Icons.public, color: _selectedBuildingId?.startsWith('campus_') == true ? Colors.greenAccent : electricGrid),
                                       style: IconButton.styleFrom(
                                          backgroundColor: _selectedBuildingId?.startsWith('campus_') == true ? Colors.greenAccent.withOpacity(0.1) : electricGrid.withOpacity(0.1),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                       ),
                                     ),
                                   )
                               ],
                             );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_,__) => const SizedBox(),
                        ),
                    ),
                    const SizedBox(width: 12),
                    // Floor Selector
                    Expanded(
                      flex: 2,
                      child: _selectedBuildingId == null 
                        ? const SizedBox() 
                        : Consumer(builder: (context, ref, _) {
                            final floorsAsync = ref.watch(floorsOfBuildingProvider(_selectedBuildingId!));
                            return floorsAsync.when(
                               data: (floors) {
                                  if (floors.isEmpty) return const Text("No floors", style: TextStyle(color: Colors.white54));
                                  return DropdownButtonFormField<String>(
                                     value: _selectedFloorId,
                                      decoration: InputDecoration(
                                       labelText: 'Floor',
                                       labelStyle: const TextStyle(color: electricGrid),
                                       enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: electricGrid.withOpacity(0.3))),
                                       focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: electricGrid)),
                                       filled: true,
                                       fillColor: darkCardColor,
                                       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                                     ),
                                     dropdownColor: darkCardColor,
                                     style: const TextStyle(color: paperWhite),
                                     items: floors.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name, overflow: TextOverflow.ellipsis))).toList(),
                                     onChanged: (val) {
                                        if (val != null) setState(() => _selectedFloorId = val);
                                     }
                                  );
                               },
                               loading: () => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: electricGrid))),
                               error: (_,__) => const Icon(Icons.error, color: Colors.orange, size: 20),
                            );
                        }),
                    ),
                  ],
                ),
              ),

              // Map Content
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(23)), 
                  child: (_selectedBuildingId != null && _selectedFloorId != null) 
                     ? _MapViewer(
                         buildingId: _selectedBuildingId!, 
                         floorId: _selectedFloorId!,
                         onEnterBuilding: (targetBid) => _updateBuilding(targetBid),
                       )
                     : const Center(child: Text("Select a Building and Floor", style: TextStyle(color: Colors.white54))),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _initializeSelection(List<Building> buildings) async {
     setState(() => _initialized = true);
     
     final navState = ref.read(navigationProvider);
     
     // 1. Try to start from current navigation start point
     if (navState.startRoom != null) {
        final graphService = ref.read(graphServiceProvider);
        final bId = graphService.getBuildingIdForFloor(navState.startRoom!.floorId); // This might be unreliable if graph not fully loaded?
        
        // Better way: we have buildlingId in rooms? No. 
        // We have to rely on graph service or find the floor in all floors?
        // Let's rely on standard init for now. 
        if (bId != null) {
           _updateBuilding(bId, initialFloorId: navState.startRoom!.floorId);
           return;
        }
     }
     
     // 2. Default to first valid building
     final validBuildings = buildings.where((b) => !b.id.startsWith('campus_')).toList();
     if (validBuildings.isNotEmpty) {
        _updateBuilding(validBuildings.first.id);
     }
  }

  void _updateBuilding(String buildingId, {String? initialFloorId}) {
     setState(() {
       _selectedBuildingId = buildingId;
       _selectedFloorId = null; // Clear floor until fetched
     });
     
     // Fetch floors to auto-select first one
     ref.read(floorsOfBuildingProvider(buildingId).future).then((floors) {
        if (mounted && _selectedBuildingId == buildingId) {
             if (initialFloorId != null && floors.any((f) => f.id == initialFloorId)) {
                setState(() => _selectedFloorId = initialFloorId);
             } else if (floors.isNotEmpty) {
                // Sort by floor number usually? 
                setState(() => _selectedFloorId = floors.first.id);
             }
        }
     });
  }
}

/// Widget that renders the map content (rooms, corridors, grid) for a specific floor.
class _MapViewer extends ConsumerWidget {
  final String buildingId;
  final String floorId;
  final Function(String buildingId)? onEnterBuilding;

  const _MapViewer({
    required this.buildingId, 
    required this.floorId,
    this.onEnterBuilding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = FloorParams(buildingId, floorId);
    final roomsAsync = ref.watch(roomsProvider(params));
    final corridorsAsync = ref.watch(corridorsProvider(params));
    final campusConnectionsAsync = ref.watch(campusConnectionsProvider);
    final navState = ref.watch(navigationProvider);
    final heading = ref.watch(compassProvider) ?? 0.0;

    return roomsAsync.when(
      data: (rooms) => corridorsAsync.when(
        data: (corridors) => InteractiveViewer(
          minScale: 0.1,
          maxScale: 4.0,
          constrained: false, // Allow canvas to exceed viewport
          boundaryMargin: const EdgeInsets.all(5000), // Allow panning
          child: SizedBox(
            width: 15000,
            height: 15000,
            child: Transform.rotate(
               angle: -(heading * 3.14159 / 180), // Rotate map opposite to heading
               alignment: Alignment.center, // Rotate around center of viewport? No, rotate around user? 
               // For now, simpler to just rotate the view. 
               // NOTE: Rotating the entire canvas might be disorienting if the pivot isn't the user. 
               // Ideally, we center on the user. But without user position tracking, we just rotate the map.
               child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GridPainter(),
                    ),
                  ),
                  // Edges and Path
                  Positioned.fill(
                     child: CustomPaint(
                       painter: buildingId.startsWith('campus_') 
                         ? CampusEdgePainter(
                             rooms: rooms,
                             connections: campusConnectionsAsync.asData?.value ?? [],
                             pathIds: navState.pathIds,
                           )
                         : EdgePainter(
                             rooms: rooms,
                             corridors: corridors,
                             positions: {}, // Static view
                             pathIds: navState.pathIds, // Pass global path
                           ),
                     )
                  ),
                  // Draw Rooms
                  ...rooms.map((room) {
                    final isStart = navState.startRoom?.id == room.id;
                    final isEnd = navState.endRoom?.id == room.id;
                    final isInPath = navState.pathIds.contains(room.id);
                    
                    Color color = Colors.blue.withValues(alpha: 0.5);
                    if (isStart) color = Colors.green;
                    else if (isEnd) color = Colors.red;
                    else if (isInPath) color = Colors.amber;
            
                    // Hide Hallway Nodes unless debug/path?
                    // Only hide if NOT in path and type is hallway
                    if (room.type == RoomType.hallway && !isInPath) {
                       return const SizedBox(); 
                    }
            
                    return Positioned(
                      left: room.x,
                      top: room.y,
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => SimpleDialog(
                              backgroundColor: darkCardColor,
                              title: Text(room.name, style: const TextStyle(color: paperWhite)),
                              children: [
                                if (buildingId.startsWith('campus_') && room.connectorId != null && onEnterBuilding != null)
                                   SimpleDialogOption(
                                    onPressed: () {
                                       Navigator.pop(ctx);
                                       onEnterBuilding!(room.connectorId!);
                                    },
                                    child: const Text('Enter Building', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                  ),
                                SimpleDialogOption(
                                  onPressed: () {
                                     ref.read(navigationProvider.notifier).setStart(room);
                                     Navigator.pop(ctx);
                                  },
                                  child: const Text('Set as Start', style: TextStyle(color: electricGrid)),
                                ),
                                SimpleDialogOption(
                                  onPressed: () {
                                     ref.read(navigationProvider.notifier).setEnd(room);
                                     Navigator.pop(ctx);
                                  },
                                  child: const Text('Set as Destination', style: TextStyle(color: electricGrid)),
                                ),
                              ],
                            )
                          );
                        },
                        child: Container(
                          width: room.type == RoomType.hallway ? 20 : 40,
                          height: room.type == RoomType.hallway ? 20 : 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                          ),
                          alignment: Alignment.center,
                          child: room.type == RoomType.hallway 
                            ? null 
                              : Transform.rotate(
                                  angle: (heading * 3.14159 / 180), // Counter-rotate icons so they stay upright?
                                  child: Icon(
                                    isStart || isEnd ? Icons.star : 
                                    (room.type == RoomType.elevator ? Icons.elevator : 
                                     (room.type == RoomType.stairs ? Icons.stairs : Icons.room)), 
                                    size: 20, 
                                    color: Colors.white
                                  ),
                              ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: electricGrid)),
        error: (e, _) => Center(child: Text('Error loading map: $e', style: const TextStyle(color: Colors.redAccent))),
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: electricGrid)),
      error: (e, _) => Center(child: Text('Error loading map: $e', style: const TextStyle(color: Colors.redAccent))),
    );
  }
}

class CampusEdgePainter extends CustomPainter {
  final List<Room> rooms;
  final List<CampusConnection> connections;
  final List<String> pathIds;

  CampusEdgePainter({
    required this.rooms, 
    required this.connections,
    this.pathIds = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Map connectorId -> Room (for quick lookup of building nodes)
    final connectorMap = <String, Room>{};
    for (var room in rooms) {
      if (room.connectorId != null) {
        connectorMap[room.connectorId!] = room;
      }
    }

    final paint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.6)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.6)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    for (final conn in connections) {
      final startNode = connectorMap[conn.fromBuildingId];
      final endNode = connectorMap[conn.toBuildingId];

      if (startNode != null && endNode != null) {
         // Determine if this connection is part of the path
         bool isPathEdge = false;
         if (pathIds.length > 1) {
             // Check if consecutive nodes in path match this connection
             // NOTE: pathIds contains ROOM IDs. startNode.id and endNode.id are ROOM IDs.
             for (int i=0; i < pathIds.length - 1; i++) {
                 final a = pathIds[i];
                 final b = pathIds[i+1];
                 if ((a == startNode.id && b == endNode.id) || (a == endNode.id && b == startNode.id)) {
                     isPathEdge = true;
                     break;
                 }
             }
         }

         final drawPaint = isPathEdge 
             ? (Paint()..color = Colors.redAccent..strokeWidth = 6..style = PaintingStyle.stroke..strokeCap = StrokeCap.round)
             : paint;

         // Draw line
         final p1 = Offset(startNode.x + 20, startNode.y + 20); // Center of 40x40 node
         final p2 = Offset(endNode.x + 20, endNode.y + 20);
         
         canvas.drawLine(p1, p2, drawPaint);
         
         // Distance label
         final mid = (p1 + p2) / 2;
         final textSpan = TextSpan(
           text: '${conn.distance.toStringAsFixed(0)}m',
           style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: Colors.black45),
         );
         final textPainter = TextPainter(
           text: textSpan,
           textDirection: TextDirection.ltr,
         );
         textPainter.layout();
         textPainter.paint(canvas, mid - Offset(textPainter.width / 2, textPainter.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CampusEdgePainter oldDelegate) {
    return oldDelegate.connections != connections || 
           oldDelegate.rooms != rooms ||
           oldDelegate.pathIds != pathIds;
  }
}
