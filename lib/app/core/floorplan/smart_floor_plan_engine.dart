import 'dart:math' as math;

import 'package:smart_floor_plan/app/core/floorplan/layout_templates/floor_plan_layout_catalog.dart';
import 'package:smart_floor_plan/app/core/floorplan/layout_templates/floor_plan_template.dart';
import 'package:smart_floor_plan/app/core/floorplan/room_recommendation.dart';
import 'package:smart_floor_plan/app/data/models/room_model.dart';

class SmartFloorPlanResult {
  final double landWidth;
  final double landLength;
  final List<RoomModel> rooms;
  final List<RoomRecommendation> recommendations;

  final String templateId;
  final String templateName;
  final String templateDescription;

  const SmartFloorPlanResult({
    required this.landWidth,
    required this.landLength,
    required this.rooms,
    required this.recommendations,
    this.templateId = '',
    this.templateName = '',
    this.templateDescription = '',
  });
}

class SmartFloorPlanEngine {
  static List<RoomRecommendation> getRecommendations({
    required double landWidth,
    required double landLength,
    required int bedroomCount,
  }) {
    final double safeWidth = math.max(4.0, landWidth).toDouble();
    final double safeLength = math.max(5.0, landLength).toDouble();

    final FloorPlanTemplate template = FloorPlanLayoutCatalog.select(
      landWidth: safeWidth,
      landLength: safeLength,
    );

    return _buildRecommendations(
      template.buildRooms(
        landWidth: safeWidth,
        landLength: safeLength,
      ),
    );
  }

  static SmartFloorPlanResult generate({
    required double landWidth,
    required double landLength,
    required int bedroomCount,
    List<RoomRecommendation> extraRooms = const [],
  }) {
    final double safeWidth = math.max(4.0, landWidth).toDouble();
    final double safeLength = math.max(5.0, landLength).toDouble();

    final FloorPlanTemplate template = FloorPlanLayoutCatalog.select(
      landWidth: safeWidth,
      landLength: safeLength,
    );

    final List<RoomModel> generatedRooms = template.buildRooms(
      landWidth: safeWidth,
      landLength: safeLength,
    );

    return SmartFloorPlanResult(
      landWidth: safeWidth,
      landLength: safeLength,
      rooms: generatedRooms,
      recommendations: _buildRecommendations(generatedRooms),
      templateId: template.id,
      templateName: template.name,
      templateDescription: template.description,
    );
  }

  static List<RoomRecommendation> _buildRecommendations(
    List<RoomModel> rooms,
  ) {
    return rooms.map((room) {
      return RoomRecommendation(
        name: room.nama,
        category: room.category,
        width: room.width,
        height: room.height,
      );
    }).toList();
  }

  static String selectedDesignName({
    required double landWidth,
    required double landLength,
  }) {
    return FloorPlanLayoutCatalog.select(
      landWidth: landWidth,
      landLength: landLength,
    ).name;
  }

  static String selectedDesignDescription({
    required double landWidth,
    required double landLength,
  }) {
    return FloorPlanLayoutCatalog.select(
      landWidth: landWidth,
      landLength: landLength,
    ).description;
  }

  static List<String> availableAlternativeDesignNames({
    required double landWidth,
    required double landLength,
  }) {
    return FloorPlanLayoutCatalog.alternatives(
      landWidth: landWidth,
      landLength: landLength,
    ).map((template) => template.name).toList();
  }
}