import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/campus_entities.dart';

class CampusConnectionModel extends CampusConnection {
  const CampusConnectionModel({
    required super.id,
    required super.fromBuildingId,
    required super.toBuildingId,
    required super.distance,
    super.bidirectional,
  });

  factory CampusConnectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CampusConnectionModel(
      id: doc.id,
      fromBuildingId: data['fromBuildingId'] ?? '',
      toBuildingId: data['toBuildingId'] ?? '',
      distance: (data['distance'] as num?)?.toDouble() ?? 0.0,
      bidirectional: data['bidirectional'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromBuildingId': fromBuildingId,
      'toBuildingId': toBuildingId,
      'distance': distance,
      'bidirectional': bidirectional,
    };
  }
}
