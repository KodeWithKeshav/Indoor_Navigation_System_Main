import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indoor_navigation_system/features/navigation/presentation/providers/navigation_provider.dart';
import '../providers/ar_navigation_provider.dart';

/// Theme constants (matching UserHomeScreen Deep Void theme).
const Color _deepVoidBlue = Color(0xFF0F172A);
const Color _electricGrid = Color(0xFF38BDF8);
const Color _darkCardColor = Color(0xFF1E293B);
const Color _paperWhite = Color(0xFFE2E8F0);

/// A frosted glass instruction banner for the AR navigation screen.
///
/// Shows the current step icon, message, distance, progress bar,
/// walk distance, and prev/next controls.
///
/// On-track status and next landmark are computed from the instruction icon,
/// consistent with the AR arrow direction logic.
class ArInstructionBanner extends ConsumerWidget {
  const ArInstructionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);

    if (!navState.isNavigating || navState.instructions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use the same instruction-based AR state computation as the arrow
    final arState = computeArState(navState);

    final instruction =
        navState.instructions[navState.currentInstructionIndex.clamp(
          0,
          navState.instructions.length - 1,
        )];
    final isFirst = navState.currentInstructionIndex == 0;
    final isLast =
        navState.currentInstructionIndex >= navState.instructions.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: _deepVoidBlue.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _electricGrid.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // On-track indicator strip
                _buildOnTrackStrip(arState.onTrackStatus),
                const SizedBox(height: 10),

                // Main instruction row
                Row(
                  children: [
                    _buildStepIcon(instruction.icon),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            instruction.message,
                            style: const TextStyle(
                              color: _paperWhite,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (instruction.distance > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.straighten_rounded,
                                  color: _electricGrid.withValues(alpha: 0.7),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${instruction.distance.toStringAsFixed(0)}m',
                                  style: TextStyle(
                                    color: _electricGrid.withValues(alpha: 0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (arState.nextLandmarkName != null) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '→ ${arState.nextLandmarkName}',
                                      style: TextStyle(
                                        color: _paperWhite.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Progress bar
                _buildProgressBar(navState),

                const SizedBox(height: 10),

                // Step counter + walk distance + prev/next
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step ${navState.currentInstructionIndex + 1}/${navState.instructions.length}',
                          style: TextStyle(
                            color: _paperWhite.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        if (navState.distanceWalked > 0) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.directions_walk_rounded,
                                color: _electricGrid.withValues(alpha: 0.6),
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${navState.distanceWalked.toStringAsFixed(1)}m walked',
                                style: TextStyle(
                                  color: _electricGrid.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),

                    Row(
                      children: [
                        _buildNavButton(
                          icon: Icons.chevron_left_rounded,
                          enabled: !isFirst,
                          onTap: () => ref
                              .read(navigationProvider.notifier)
                              .previousInstruction(),
                        ),
                        const SizedBox(width: 8),
                        _buildNavButton(
                          icon: Icons.chevron_right_rounded,
                          enabled: !isLast,
                          onTap: () => ref
                              .read(navigationProvider.notifier)
                              .nextInstruction(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(NavigationState navState) {
    final progress = navState.instructions.isEmpty
        ? 0.0
        : (navState.currentInstructionIndex + 1) / navState.instructions.length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toStringAsFixed(0)}% complete',
              style: TextStyle(
                color: _electricGrid.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: _darkCardColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? const Color(0xFF22C55E) : _electricGrid,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOnTrackStrip(OnTrackStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case OnTrackStatus.onTrack:
        color = const Color(0xFF22C55E);
        text = 'On Track';
        icon = Icons.check_circle_outline_rounded;
        break;
      case OnTrackStatus.slightTurn:
        color = const Color(0xFFFBBF24);
        text = 'Turn Ahead';
        icon = Icons.turn_slight_right_rounded;
        break;
      case OnTrackStatus.offTrack:
        color = const Color(0xFFEF4444);
        text = 'Turn Around';
        icon = Icons.u_turn_right_rounded;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIcon(String iconName) {
    IconData iconData;
    switch (iconName) {
      case 'left':
      case 'sharp_left':
        iconData = Icons.turn_left_rounded;
        break;
      case 'right':
      case 'sharp_right':
        iconData = Icons.turn_right_rounded;
        break;
      case 'straight':
        iconData = Icons.arrow_upward_rounded;
        break;
      case 'stairs':
      case 'stairs_up':
      case 'stairs_down':
        iconData = Icons.stairs_rounded;
        break;
      case 'elevator':
      case 'elevator_up':
      case 'elevator_down':
        iconData = Icons.elevator_rounded;
        break;
      case 'finish':
        iconData = Icons.flag_rounded;
        break;
      case 'start':
        iconData = Icons.my_location_rounded;
        break;
      case 'uturn':
        iconData = Icons.u_turn_right_rounded;
        break;
      case 'enter':
        iconData = Icons.door_front_door_rounded;
        break;
      case 'exit':
        iconData = Icons.exit_to_app_rounded;
        break;
      default:
        iconData = Icons.navigation_rounded;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _electricGrid.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _electricGrid.withValues(alpha: 0.3)),
      ),
      child: Icon(iconData, color: _electricGrid, size: 22),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? _darkCardColor
              : _darkCardColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? _electricGrid.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? _paperWhite : _paperWhite.withValues(alpha: 0.3),
          size: 20,
        ),
      ),
    );
  }
}
