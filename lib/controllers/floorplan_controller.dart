import 'package:get/get.dart';

class FloorplanController
    extends GetxController {

  RxDouble lebarRumah =
      36.0.obs;

  RxDouble panjangRumah =
      72.0.obs;

  RxInt jumlahKamar =
      2.obs;

  RxDouble jumlahKamarMandi =
      1.0.obs;

  RxList<String> ruangTambahan =
      <String>[].obs;

  void toggleRuang(String ruang) {

    if (ruangTambahan
        .contains(ruang)) {

      ruangTambahan.remove(ruang);

    } else {

      ruangTambahan.add(ruang);
    }
  }
}