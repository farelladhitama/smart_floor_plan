import 'dart:math';

import 'package:smart_floor_plan/app/core/floorplan/room_recommendation.dart';
import 'package:smart_floor_plan/app/data/models/room_model.dart';

class RoomPlacer {
  final double landWidth;
  final double landLength;
  final List<RoomRecommendation> rooms;

  final Random _random = Random();

  RoomPlacer({
    required this.landWidth,
    required this.landLength,
    required this.rooms,
  });

  List<RoomModel> generate() {
    final List<RoomModel> placedRooms = [];

    final List<RoomRecommendation> indoor = [];
    final List<RoomRecommendation> outdoor = [];

    //-------------------------------------
    // Pisahkan indoor & outdoor
    //-------------------------------------

    for (final room in rooms) {
      if (room.category == "outdoor") {
        outdoor.add(room);
      } else {
        indoor.add(room);
      }
    }

    //-------------------------------------
    // Prioritas
    //-------------------------------------

    indoor.sort((a, b) {

      return _priority(b.category)
          .compareTo(_priority(a.category));

    });

    //-------------------------------------
    // Zona Bangunan
    //-------------------------------------

    final double frontDepth = landLength * 0.30;

    final double middleDepth = landLength * 0.35;

    final double backDepth =
        landLength - frontDepth - middleDepth;

    //-------------------------------------

    _placeFrontZone(
      placedRooms,
      indoor,
      frontDepth,
    );

    _placeMiddleZone(
      placedRooms,
      indoor,
      frontDepth,
      middleDepth,
    );

    _placeBackZone(
      placedRooms,
      indoor,
      frontDepth,
      middleDepth,
      backDepth,
    );

    //-------------------------------------

    _placeOutdoor(
      placedRooms,
      outdoor,
    );

    return placedRooms;
  }

  //----------------------------------------------------
  // PRIORITY
  //----------------------------------------------------

  int _priority(String category) {

    switch (category) {

      case "living":
        return 100;

      case "family":
        return 95;

      case "bedroom":
        return 90;

      case "bath":
        return 80;

      case "kitchen":
        return 70;

      case "dining":
        return 60;

      case "service":
        return 50;

      default:
        return 10;

    }

  }

  //----------------------------------------------------
  // FRONT ZONE
  //----------------------------------------------------

  void _placeFrontZone(

    List<RoomModel> output,

    List<RoomRecommendation> source,

    double depth,

  ) {

    double cursorX = 0;

    final frontRooms = source.where((e) {

      return e.category == "living";

    }).toList();

    for (final room in frontRooms) {

      output.add(

        RoomModel(

          nama: room.name,

          x: cursorX,

          y: 0,

          width: room.width,

          height: room.height,

          category: room.category,

        ),

      );

      cursorX += room.width;

      source.remove(room);

    }

  }

  //----------------------------------------------------
  // MIDDLE ZONE
  //----------------------------------------------------

  void _placeMiddleZone(

    List<RoomModel> output,

    List<RoomRecommendation> source,

    double frontDepth,

    double middleDepth,

  ) {

    double cursorX = 0;

    double cursorY = frontDepth;

    final middleRooms = source.where((e) {

      return

      e.category == "family" ||

      e.category == "dining";

    }).toList();

    for (final room in middleRooms) {

      output.add(

        RoomModel(

          nama: room.name,

          x: cursorX,

          y: cursorY,

          width: room.width,

          height: room.height,

          category: room.category,

        ),

      );

      cursorX += room.width;

      source.remove(room);

    }

  }

  //----------------------------------------------------
  // BACK ZONE
  //----------------------------------------------------

  void _placeBackZone(

    List<RoomModel> output,

    List<RoomRecommendation> source,

    double frontDepth,

    double middleDepth,

    double backDepth,

  ) {

    double cursorX = 0;

    double cursorY = frontDepth + middleDepth;

    final backRooms = List<RoomRecommendation>.from(source);

    backRooms.shuffle(_random);

    for (final room in backRooms) {

      output.add(

        RoomModel(

          nama: room.name,

          x: cursorX,

          y: cursorY,

          width: room.width,

          height: room.height,

          category: room.category,

        ),

      );

      cursorX += room.width;

      source.remove(room);

    }

  }

  //----------------------------------------------------
  // OUTDOOR
  //----------------------------------------------------

  void _placeOutdoor(

    List<RoomModel> output,

    List<RoomRecommendation> outdoor,

  ) {

    outdoor.shuffle(_random);

    double left = 0;

    for (final room in outdoor) {

      output.add(

        RoomModel(

          nama: room.name,

          x: left,

          y: 0,

          width: room.width,

          height: room.height,

          category: room.category,

          isOutdoor: true,

        ),

      );

      left += room.width;

    }

  }

}