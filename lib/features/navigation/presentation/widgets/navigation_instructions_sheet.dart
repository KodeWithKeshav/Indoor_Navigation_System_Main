import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';

// Theme Constants (matching UserHomeScreen)
const Color electricGrid = Color(0xFF38BDF8); 
const Color darkCardColor = Color(0xFF1E293B);
const Color paperWhite = Color(0xFFE2E8F0);

class NavigationInstructionsSheet extends ConsumerWidget {
  const NavigationInstructionsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);
    
    // Only show if navigating
    if (!navState.isNavigating) return const SizedBox.shrink();

    return Container(
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
               const Text(
                 'NEXT STEPS', 
                 style: TextStyle(
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
            child: navState.instructions.isEmpty 
              ? const Center(child: Text("Follow the path on the map", style: TextStyle(color: Colors.white54)))
              : ListView.separated(
              padding: const EdgeInsets.only(top: 8),
              separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 16),
              itemCount: navState.instructions.length,
              itemBuilder: (context, index) {
                final step = navState.instructions[index];
                IconData icon;
                switch(step.icon) {
                  case 'left': icon = Icons.turn_left; break;
                  case 'right': icon = Icons.turn_right; break;
                  case 'sharp_left': icon = Icons.u_turn_left; break; 
                  case 'sharp_right': icon = Icons.u_turn_right; break; 
                  case 'straight': icon = Icons.arrow_upward; break;
                  case 'stairs_up': icon = Icons.stairs; break;
                  case 'stairs_down': icon = Icons.stairs_outlined; break;
                  case 'elevator_up': icon = Icons.elevator; break;
                  case 'elevator_down': icon = Icons.elevator_outlined; break;
                  case 'finish': icon = Icons.flag; break;
                  case 'uturn': icon = Icons.u_turn_left; break;
                  case 'start': icon = Icons.trip_origin; break;
                  case 'enter': icon = Icons.door_front_door; break;
                  case 'exit': icon = Icons.door_back_door; break;
                  default: icon = Icons.circle;
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: electricGrid.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: electricGrid.withOpacity(0.5)),
                      ),
                      child: Icon(icon, color: electricGrid, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.message,
                            style: const TextStyle(color: paperWhite, fontWeight: FontWeight.w600, fontSize: 14)
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
                                  fontFamily: 'Courier',
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
    );
  }
}
