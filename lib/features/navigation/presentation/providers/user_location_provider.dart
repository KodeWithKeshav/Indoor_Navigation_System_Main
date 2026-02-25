import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../admin_map/domain/entities/map_entities.dart';

// State for User Interaction
class UserLocationState {
  final Building? selectedBuilding;
  final Floor? selectedFloor;
  final Room? selectedStartRoom;
  final Room? selectedDestinationRoom;

  UserLocationState({
    this.selectedBuilding,
    this.selectedFloor,
    this.selectedStartRoom,
    this.selectedDestinationRoom,
  });

  UserLocationState copyWith({
    Building? selectedBuilding,
    Floor? selectedFloor,
    Room? selectedStartRoom,
    Room? selectedDestinationRoom,
  }) {
    return UserLocationState(
      selectedBuilding: selectedBuilding,
      selectedFloor: selectedFloor,
      selectedStartRoom: selectedStartRoom,
      selectedDestinationRoom: selectedDestinationRoom,
    );
  }
}

class UserLocationNotifier extends Notifier<UserLocationState> {
  @override
  UserLocationState build() {
    return UserLocationState();
  }

  void selectBuilding(Building building) {
    state = UserLocationState(selectedBuilding: building); // Reset others
  }

  void selectFloor(Floor floor) {
    state = state.copyWith(
      selectedFloor: floor,
      selectedStartRoom: null,
      selectedDestinationRoom: null,
    );
  }

  void selectStartRoom(Room room) {
    state = state.copyWith(selectedStartRoom: room);
  }

  void selectDestinationRoom(Room room) {
    state = state.copyWith(selectedDestinationRoom: room);
  }
}

final userLocationProvider =
    NotifierProvider<UserLocationNotifier, UserLocationState>(
      UserLocationNotifier.new,
    );
