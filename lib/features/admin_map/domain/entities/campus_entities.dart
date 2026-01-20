import 'package:equatable/equatable.dart';

class CampusConnection extends Equatable {
  final String id;
  final String fromBuildingId;
  final String toBuildingId;
  final double distance;
  final bool bidirectional;

  const CampusConnection({
    required this.id,
    required this.fromBuildingId,
    required this.toBuildingId,
    required this.distance,
    this.bidirectional = true,
  });

  @override
  List<Object?> get props => [id, fromBuildingId, toBuildingId, distance, bidirectional];
}
