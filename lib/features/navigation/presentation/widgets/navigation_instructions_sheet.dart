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
    final navNotifier = ref.read(navigationProvider.notifier);

    // Only show if navigating
    if (!navState.isNavigating) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 40),
      decoration: BoxDecoration(
        color: darkCardColor.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: electricGrid, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: electricGrid.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CURRENT STEP',
                style: TextStyle(
                  color: paperWhite,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
              if (navState.instructions.isNotEmpty)
                Text(
                  'STEP ${navState.currentInstructionIndex + 1} OF ${navState.instructions.length}',
                  style: const TextStyle(
                    color: electricGrid,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          Divider(color: electricGrid.withOpacity(0.3)),

          navState.instructions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      "Follow the path on the map",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              : _buildStepView(navState, navNotifier),
        ],
      ),
    );
  }

  Widget _buildStepView(
    NavigationState navState,
    NavigationNotifier navNotifier,
  ) {
    final step = navState.instructions[navState.currentInstructionIndex];
    IconData icon;
    switch (step.icon) {
      case 'left':
        icon = Icons.turn_left;
        break;
      case 'right':
        icon = Icons.turn_right;
        break;
      case 'sharp_left':
        icon = Icons.u_turn_left;
        break;
      case 'sharp_right':
        icon = Icons.u_turn_right;
        break;
      case 'straight':
        icon = Icons.arrow_upward;
        break;
      case 'stairs_up':
        icon = Icons.stairs;
        break;
      case 'stairs_down':
        icon = Icons.stairs_outlined;
        break;
      case 'elevator_up':
        icon = Icons.elevator;
        break;
      case 'elevator_down':
        icon = Icons.elevator_outlined;
        break;
      case 'finish':
        icon = Icons.flag;
        break;
      case 'uturn':
        icon = Icons.u_turn_left;
        break;
      case 'start':
        icon = Icons.trip_origin;
        break;
      case 'enter':
        icon = Icons.door_front_door;
        break;
      case 'exit':
        icon = Icons.door_back_door;
        break;
      default:
        icon = Icons.circle;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big Icon Background
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: electricGrid.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: electricGrid, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Header & Counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (step.distance > 0)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              step.distance.toStringAsFixed(0),
                              style: const TextStyle(
                                color: electricGrid,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'm',
                              style: TextStyle(
                                color: electricGrid,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Step ${navState.currentInstructionIndex + 1}',
                          style: TextStyle(
                            color: electricGrid.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Courier',
                            letterSpacing: 1.2,
                          ),
                        ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${navState.currentInstructionIndex + 1} / ${navState.instructions.length}',
                          style: TextStyle(
                            color: paperWhite.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Instruction message
                  Text(
                    step.message,
                    style: const TextStyle(
                      color: paperWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: Colors.white.withOpacity(0.1), height: 1),
        const SizedBox(height: 12),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Prev Button
            navState.currentInstructionIndex > 0
                ? InkWell(
                    onTap: () => navNotifier.previousInstruction(),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chevron_left,
                            color: paperWhite.withOpacity(0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PREV',
                            style: TextStyle(
                              color: paperWhite.withOpacity(0.6),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(width: 70), // Spacer for flex layout
            // Next/Done Button
            if (navState.currentInstructionIndex <
                navState.instructions.length - 1)
              FilledButton(
                onPressed: () => navNotifier.nextInstruction(),
                style: FilledButton.styleFrom(
                  backgroundColor: electricGrid,
                  foregroundColor: darkCardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Next',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              )
            else
              FilledButton.icon(
                onPressed: () => navNotifier.clear(),
                icon: const Icon(Icons.check, size: 18),
                label: const Text(
                  'Finish',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade400,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
