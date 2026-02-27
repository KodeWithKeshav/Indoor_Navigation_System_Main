import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indoor_navigation_system/features/admin_map/domain/entities/map_entities.dart';
import 'package:indoor_navigation_system/features/admin_map/presentation/providers/admin_map_providers.dart';
import 'package:indoor_navigation_system/core/services/navigation_instruction_service.dart';
import 'package:indoor_navigation_system/core/services/compass_service.dart';
import 'package:indoor_navigation_system/core/services/voice_guidance_service.dart';
import 'package:indoor_navigation_system/core/services/pedometer_service.dart';
import 'package:indoor_navigation_system/core/providers/settings_provider.dart';

class NavigationState {
  final Room? startRoom;
  final Room? endRoom;
  final List<String> pathIds;
  final List<Room> pathRooms;
  final List<NavigationInstruction> instructions;
  final int currentInstructionIndex;
  final bool isNavigating;
  final String? organizationId;
  final bool isAccessible;
  final double distanceWalked; // Distance walked for current step (pedometer)

  NavigationState({
    this.startRoom,
    this.endRoom,
    this.pathIds = const [],
    this.pathRooms = const [],
    this.instructions = const [],
    this.currentInstructionIndex = 0,
    this.isNavigating = false,
    this.organizationId,
    this.isAccessible = false,
    this.distanceWalked = 0.0,
  });

  NavigationState copyWith({
    Room? startRoom,
    Room? endRoom,
    List<String>? pathIds,
    List<Room>? pathRooms,
    List<NavigationInstruction>? instructions,
    int? currentInstructionIndex,
    bool? isNavigating,
    String? organizationId,
    bool? isAccessible,
    double? distanceWalked,
  }) {
    return NavigationState(
      startRoom: startRoom ?? this.startRoom,
      endRoom: endRoom ?? this.endRoom,
      pathIds: pathIds ?? this.pathIds,
      pathRooms: pathRooms ?? this.pathRooms,
      instructions: instructions ?? this.instructions,
      currentInstructionIndex:
          currentInstructionIndex ?? this.currentInstructionIndex,
      isNavigating: isNavigating ?? this.isNavigating,
      organizationId: organizationId ?? this.organizationId,
      isAccessible: isAccessible ?? this.isAccessible,
      distanceWalked: distanceWalked ?? this.distanceWalked,
    );
  }
}

class NavigationNotifier extends Notifier<NavigationState> {
  StreamSubscription? _pedometerSubscription;
  StreamSubscription? _compassSubscription;
  double? _turnStartHeading; // Heading when turn step began

  @override
  NavigationState build() {
    debugPrint('NavigationNotifier: build() called');

    // Clean up subscriptions on dispose
    ref.onDispose(() {
      _pedometerSubscription?.cancel();
      _compassSubscription?.cancel();
      ref.read(voiceGuidanceServiceProvider).stop();
    });

    return NavigationState();
  }

  /// Speak the current instruction if voice guidance is enabled.
  void _speakCurrentInstruction() {
    final settings = ref.read(settingsProvider);
    if (!settings.isVoiceEnabled) return;
    if (state.instructions.isEmpty) return;
    if (state.currentInstructionIndex >= state.instructions.length) return;

    final instruction = state.instructions[state.currentInstructionIndex];
    String text = instruction.message;

    // Append distance info for walk steps
    if (instruction.distance > 0) {
      text += ', ${instruction.distance.toStringAsFixed(0)} meters';
    }

    ref.read(voiceGuidanceServiceProvider).speak(text);
  }

  /// Start listening to pedometer distance updates for auto-advancing steps.
  void _startPedometerTracking() {
    final pedometer = ref.read(pedometerServiceProvider);
    if (!PedometerService.isSupported) return;

    pedometer.resetDistance();
    pedometer.startTracking();

    _pedometerSubscription?.cancel();
    _pedometerSubscription = pedometer.distanceStream.listen((distance) {
      if (!state.isNavigating) return;
      if (state.currentInstructionIndex >= state.instructions.length) return;

      final currentStep = state.instructions[state.currentInstructionIndex];

      // Update distance walked in state
      state = state.copyWith(distanceWalked: distance);

      // Auto-advance only for steps that have a distance > 0
      if (currentStep.distance > 0 && distance >= currentStep.distance) {
        _autoAdvanceStep();
      }
    });
  }

  /// Stop pedometer tracking.
  void _stopPedometerTracking() {
    _pedometerSubscription?.cancel();
    _pedometerSubscription = null;
    final pedometer = ref.read(pedometerServiceProvider);
    pedometer.stopTracking();
  }

  /// Auto-advance to the next step (called by pedometer when distance threshold met).
  void _autoAdvanceStep() {
    if (state.currentInstructionIndex < state.instructions.length - 1) {
      final pedometer = ref.read(pedometerServiceProvider);
      pedometer.resetDistance();

      state = state.copyWith(
        currentInstructionIndex: state.currentInstructionIndex + 1,
        distanceWalked: 0.0,
      );

      _speakCurrentInstruction();

      // For zero-distance steps (turns), use compass-based detection on mobile
      final newStep = state.instructions[state.currentInstructionIndex];
      if (newStep.distance == 0 &&
          state.currentInstructionIndex < state.instructions.length - 1 &&
          newStep.icon != 'finish') {
        _startCompassTurnDetection(newStep);
      }
    }
  }

  /// Start monitoring compass heading to detect when user completes a turn.
  /// Falls back to a 3-second timer on platforms without compass.
  void _startCompassTurnDetection(NavigationInstruction turnStep) {
    _compassSubscription?.cancel();
    _turnStartHeading = null;

    final isTurnStep =
        turnStep.icon == 'left' ||
        turnStep.icon == 'right' ||
        turnStep.icon == 'sharp_left' ||
        turnStep.icon == 'sharp_right' ||
        turnStep.icon == 'uturn';

    if (!isTurnStep || !PedometerService.isSupported) {
      // Not a turn or not on mobile — use timer fallback
      Future.delayed(const Duration(seconds: 3), () {
        if (state.isNavigating) {
          _autoAdvanceStep();
        }
      });
      return;
    }

    // Determine required heading change direction and threshold
    double requiredChange = 45.0; // degrees
    bool expectRight =
        turnStep.icon == 'right' || turnStep.icon == 'sharp_right';
    bool expectLeft = turnStep.icon == 'left' || turnStep.icon == 'sharp_left';
    if (turnStep.icon == 'uturn') requiredChange = 135.0;

    final currentHeading = ref.read(compassProvider);
    _turnStartHeading = currentHeading;

    debugPrint(
      '🧭 Turn detection started: icon=${turnStep.icon}, startHeading=${_turnStartHeading?.toStringAsFixed(1)}',
    );

    // Listen to compass changes
    _compassSubscription = Stream.periodic(const Duration(milliseconds: 200))
        .listen((_) {
          if (!state.isNavigating) {
            _compassSubscription?.cancel();
            return;
          }

          final newHeading = ref.read(compassProvider);
          if (_turnStartHeading == null || newHeading == null) return;

          // Calculate signed heading difference (positive = clockwise/right)
          double diff = newHeading - _turnStartHeading!;
          while (diff > 180) diff -= 360;
          while (diff <= -180) diff += 360;

          if (expectRight && diff >= requiredChange) {
            debugPrint('🧭 Right turn detected: Δ${diff.toStringAsFixed(1)}°');
            _compassSubscription?.cancel();
            _autoAdvanceStep();
          } else if (expectLeft && diff <= -requiredChange) {
            debugPrint('🧭 Left turn detected: Δ${diff.toStringAsFixed(1)}°');
            _compassSubscription?.cancel();
            _autoAdvanceStep();
          } else if (turnStep.icon == 'uturn' && diff.abs() >= requiredChange) {
            debugPrint('🧭 U-turn detected: Δ${diff.toStringAsFixed(1)}°');
            _compassSubscription?.cancel();
            _autoAdvanceStep();
          }
        });

    // Fallback: if compass doesn't trigger within 10 seconds, auto-advance anyway
    Future.delayed(const Duration(seconds: 10), () {
      if (state.isNavigating &&
          state.instructions.isNotEmpty &&
          state.currentInstructionIndex < state.instructions.length &&
          state.instructions[state.currentInstructionIndex].icon ==
              turnStep.icon) {
        debugPrint('🧭 Turn detection timeout — auto-advancing');
        _compassSubscription?.cancel();
        _autoAdvanceStep();
      }
    });
  }

  Future<void> setStart(Room room, {String? organizationId}) async {
    debugPrint(
      'NavigationNotifier: setStart(${room.name}) - Current End: ${state.endRoom?.name}, Org: $organizationId',
    );
    state = state.copyWith(
      startRoom: room,
      isNavigating: false,
      pathIds: [],
      instructions: [],
      organizationId: organizationId,
    );
    await _computePath();
  }

  Future<void> setEnd(Room room) async {
    debugPrint(
      'NavigationNotifier: setEnd(${room.name}) - Current Start: ${state.startRoom?.name}',
    );
    state = state.copyWith(endRoom: room);
    await _computePath();
  }

  Future<void> toggleAccessibility(bool value) async {
    state = state.copyWith(isAccessible: value);
    if (state.startRoom != null && state.endRoom != null) {
      await _computePath();
    }
  }

  /// Refreshes the path computation, useful when graph data changes.
  Future<void> refreshPath() async {
    if (state.isNavigating) {
      await _computePath();
    }
  }

  void clear() {
    ref.read(voiceGuidanceServiceProvider).stop();
    _stopPedometerTracking();
    _compassSubscription?.cancel();
    _turnStartHeading = null;
    state = NavigationState();
  }

  void nextInstruction() {
    if (state.currentInstructionIndex < state.instructions.length - 1) {
      final pedometer = ref.read(pedometerServiceProvider);
      pedometer.resetDistance();

      state = state.copyWith(
        currentInstructionIndex: state.currentInstructionIndex + 1,
        distanceWalked: 0.0,
      );
      _speakCurrentInstruction();
    }
  }

  void previousInstruction() {
    if (state.currentInstructionIndex > 0) {
      final pedometer = ref.read(pedometerServiceProvider);
      pedometer.resetDistance();

      state = state.copyWith(
        currentInstructionIndex: state.currentInstructionIndex - 1,
        distanceWalked: 0.0,
      );
      _speakCurrentInstruction();
    }
  }

  Future<void> _computePath() async {
    debugPrint('NavigationNotifier: Computing Path...');
    if (state.startRoom == null || state.endRoom == null) {
      debugPrint('NavigationNotifier: MISSING START OR END');
      return;
    }

    // Ensure Graph IS Built
    final graphService = ref.read(graphServiceProvider);
    await graphService.buildGraph(organizationId: state.organizationId);

    final pathIds = graphService.findPath(
      state.startRoom!.id,
      state.endRoom!.id,
      isAccessible: state.isAccessible,
    );

    if (pathIds.isNotEmpty) {
      debugPrint('NavigationNotifier: Path Found (${pathIds.length} nodes)');
      final pathRooms = <Room>[];
      for (final id in pathIds) {
        try {
          final room = graphService.allRooms.firstWhere((r) => r.id == id);
          pathRooms.add(room);
        } catch (_) {}
      }

      final currentHeading = ref.read(compassProvider);

      final instructions = ref
          .read(navigationInstructionServiceProvider)
          .generateInstructions(
            pathRooms,
            corridors: graphService.allCorridors,
            floorLevels: graphService.floorLevels,
            currentHeading: currentHeading,
            mapNorthOffset: 0.0,
          );

      state = state.copyWith(
        pathIds: pathIds,
        pathRooms: pathRooms,
        instructions: instructions,
        currentInstructionIndex: 0,
        isNavigating: true,
        distanceWalked: 0.0,
      );

      // Speak the first instruction
      _speakCurrentInstruction();

      // Start pedometer tracking on mobile
      _startPedometerTracking();
    } else {
      debugPrint('NavigationNotifier: No Path Found');
      _stopPedometerTracking();
      state = state.copyWith(
        isNavigating: false,
        pathIds: [],
        instructions: [
          NavigationInstruction(
            message: "No Path Found",
            distance: 0,
            icon: 'error',
          ),
        ],
        currentInstructionIndex: 0,
      );
    }
  }
}

final navigationProvider =
    NotifierProvider<NavigationNotifier, NavigationState>(
      NavigationNotifier.new,
    );
