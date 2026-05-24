import 'package:flutter/material.dart';

import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'package:smart_floor_plan/widgets/furniture/bathroom_furniture.dart';
import 'package:smart_floor_plan/widgets/furniture/bed_furniture.dart';
import 'package:smart_floor_plan/widgets/furniture/car_furniture.dart';
import 'package:smart_floor_plan/widgets/furniture/dining_furniture.dart';
import 'package:smart_floor_plan/widgets/furniture/kitchen_furniture.dart';
import 'package:smart_floor_plan/widgets/furniture/sofa_furniture.dart';

class RoomFurnitureRenderer {
  static void draw({
    required Canvas canvas,
    required Rect roomRect,
    required RoomModel room,
    required Color lineColor,
  }) {
    if (roomRect.width < 30 || roomRect.height < 28) return;

    final String roomName = room.nama.toLowerCase();

    canvas.save();
    canvas.clipRect(roomRect.deflate(3));

    switch (room.category) {
      case 'bedroom':
        BedFurniture.draw(
          canvas,
          roomRect,
          lineColor: lineColor,
          isMaster: roomName.contains('utama') ||
              roomName.contains('master'),
        );
        break;

      case 'living':
        SofaFurniture.draw(
          canvas,
          roomRect,
          lineColor: lineColor,
        );
        break;

      case 'family':
        SofaFurniture.draw(
          canvas,
          roomRect,
          lineColor: lineColor,
          familyRoom: true,
        );
        break;

      case 'kitchen':
        KitchenFurniture.draw(
          canvas,
          roomRect,
          lineColor: lineColor,
        );
        break;

      case 'dining':
        DiningFurniture.draw(
          canvas,
          roomRect,
          lineColor: lineColor,
        );
        break;

      case 'bath':
        BathroomFurniture.draw(
          canvas,
          roomRect,
          lineColor: lineColor,
        );
        break;

      case 'outdoor':
        if (roomName.contains('carport') ||
            roomName.contains('garasi')) {
          CarFurniture.draw(
            canvas,
            roomRect,
            lineColor: lineColor,
          );
        }
        break;

      default:
        if (roomName.contains('kamar tidur') ||
            roomName.contains('k. tidur')) {
          BedFurniture.draw(
            canvas,
            roomRect,
            lineColor: lineColor,
            isMaster: roomName.contains('utama'),
          );
        } else if (roomName.contains('tamu') ||
            roomName.contains('keluarga')) {
          SofaFurniture.draw(
            canvas,
            roomRect,
            lineColor: lineColor,
            familyRoom: roomName.contains('keluarga'),
          );
        } else if (roomName.contains('dapur')) {
          KitchenFurniture.draw(
            canvas,
            roomRect,
            lineColor: lineColor,
          );
        } else if (roomName.contains('makan')) {
          DiningFurniture.draw(
            canvas,
            roomRect,
            lineColor: lineColor,
          );
        } else if (roomName.contains('mandi') ||
            roomName.contains('wc')) {
          BathroomFurniture.draw(
            canvas,
            roomRect,
            lineColor: lineColor,
          );
        }
        break;
    }

    canvas.restore();
  }
}