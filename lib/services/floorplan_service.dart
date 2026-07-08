import '../models/room_model.dart';

class FloorplanService {

  static List<RoomModel> generateFloorplan({

    required int jumlahKamar,
    required double lebarRumah,
    required double panjangRumah,

  }) {

    List<RoomModel> rooms = [];

    // SCALE
    double scale = 4;

    double rumahWidth =
        lebarRumah * scale;

    double rumahHeight =
        panjangRumah * scale;

    // RUANG TAMU
    rooms.add(

      RoomModel(
        nama: "Ruang Tamu",
        category: 'room',

        x: 0,
        y: 0,

        width: rumahWidth * 0.5,
        height: rumahHeight * 0.2,
      ),
    );

    // DAPUR
    rooms.add(

      RoomModel(
        nama: "Dapur",
        category: 'room',

        x: rumahWidth * 0.55,
        y: 0,

        width: rumahWidth * 0.4,
        height: rumahHeight * 0.2,
      ),
    );

    // KAMAR
    for (int i = 0; i < jumlahKamar; i++) {

      rooms.add(

        RoomModel(
          nama: "Kamar ${i + 1}",
          category: 'room',

          x: 0,
          y: 120 + (i * 90),

          width: rumahWidth * 0.4,
          height: 80,
        ),
      );
    }

    return rooms;
  }
}