import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/modules/generate_form/controllers/generate_form_controller.dart';

class GenerateFormPage extends GetView<GenerateFormController> {
  const GenerateFormPage({super.key});

  static const Color navy = Color(0xFF0D1B2A);
  static const Color navySoft = Color(0xFF132A42);
  static const Color orange = Color(0xFFE47B3E);
  static const Color orangeSoft = Color(0xFFFFF1E8);
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color mutedText = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Kebutuhan Rumah',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: navy,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 620;
            final bool isSmallMobile = constraints.maxWidth < 380;
            final double horizontalPadding = isSmallMobile ? 16 : 22;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 560,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    22,
                    horizontalPadding,
                    34,
                  ),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroCard(isSmallMobile),
                        const SizedBox(height: 28),

                        _sectionTitle(
                          title: 'Dimensi Lahan',
                          subtitle:
                              'Masukkan ukuran lebar dan panjang tanah untuk memulai analisis denah.',
                        ),
                        const SizedBox(height: 14),

                        isMobile
                            ? Column(
                                children: [
                                  _buildInputField(
                                    label: 'Lebar Lahan (m)',
                                    hint: 'Contoh: 10',
                                    textController: controller.lebarController,
                                    icon: Icons.straighten_rounded,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildInputField(
                                    label: 'Panjang Lahan (m)',
                                    hint: 'Contoh: 12',
                                    textController:
                                        controller.panjangController,
                                    icon: Icons.square_foot_rounded,
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _buildInputField(
                                      label: 'Lebar Lahan (m)',
                                      hint: 'Contoh: 10',
                                      textController:
                                          controller.lebarController,
                                      icon: Icons.straighten_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _buildInputField(
                                      label: 'Panjang Lahan (m)',
                                      hint: 'Contoh: 12',
                                      textController:
                                          controller.panjangController,
                                      icon: Icons.square_foot_rounded,
                                    ),
                                  ),
                                ],
                              ),

                        const SizedBox(height: 28),

                        _sectionTitle(
                          title: 'Pilihan Material Dinding',
                          subtitle:
                              'Material digunakan sebagai dasar estimasi biaya RAB.',
                        ),
                        const SizedBox(height: 14),
                        _buildMaterialDropdown(),

                        const SizedBox(height: 28),

                        _sectionTitle(
                          title: 'Rekomendasi Ruangan',
                          subtitle:
                              'Sistem akan menyarankan tipe rumah, kebutuhan ruang, dan estimasi luas berdasarkan ukuran lahan.',
                        ),
                        const SizedBox(height: 14),
                        _buildRecommendationButton(),
                        const SizedBox(height: 16),
                        _buildRecommendationSection(),

                        const SizedBox(height: 34),
                        _buildGenerateButton(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroCard(bool isSmallMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            navy,
            navySoft,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isSmallMobile ? 58 : 68,
            height: isSmallMobile ? 58 : 68,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.architecture_rounded,
              color: orange,
              size: 38,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSmallMobile ? 'Generate Denah' : 'Generate Denah Rumah',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallMobile ? 20 : 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Masukkan ukuran lahan, pilih material, lalu sistem akan menyusun rekomendasi ruang otomatis.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: navy,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController textController,
    required IconData icon,
  }) {
    return TextFormField(
      controller: textController,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      style: const TextStyle(
        color: navy,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: navy,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: orange,
            width: 1.7,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.red.shade300,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1.4,
          ),
        ),
      ),
      validator: controller.validateNumber,
    );
  }

  Widget _buildMaterialDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Obx(
        () => DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: controller.selectedMaterial.value,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: navy,
              size: 28,
            ),
            items: controller.materialOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: navy.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.layers_rounded,
                        color: navy,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: navy,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              controller.changeMaterial(value);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationButton() {
    return Obx(
      () {
        final bool isLoading = controller.isAnalyzingRecommendation.value;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed:
                isLoading ? null : () => controller.analisisRekomendasiRuang(),
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : const Icon(
                    Icons.auto_fix_high_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
            label: Text(
              isLoading ? 'Menganalisis...' : 'Rekomendasi Ruangan',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: navy,
              disabledBackgroundColor: navy.withOpacity(0.65),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: navy.withOpacity(0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationSection() {
    return Obx(
      () {
        final bool isLoading = controller.isAnalyzingRecommendation.value;
        final bool hasResult = controller.hasAnalyzedRecommendation.value;
        final bool hasRecommendation = controller.rekomendasiRuang.isNotEmpty;

        if (!isLoading && !hasResult && !hasRecommendation) {
          return _buildRecommendationPlaceholder();
        }

        if (isLoading) {
          return _buildRecommendationLoading();
        }

        if (hasResult && !hasRecommendation) {
          return _buildRecommendationEmpty();
        }

        return _buildRecommendationResult();
      },
    );
  }

  Widget _buildRecommendationPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: orangeSoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.tips_and_updates_rounded,
              color: orange,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Klik tombol Rekomendasi Ruangan setelah mengisi lebar, panjang, dan material.',
              style: TextStyle(
                color: mutedText,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: orange.withOpacity(0.22),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: orange,
              strokeWidth: 2.8,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Sistem sedang menyusun rekomendasi ruang berdasarkan ukuran lahan...',
              style: TextStyle(
                color: navy,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: mutedText,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Belum ada rekomendasi. Coba perbesar ukuran lahan atau ubah dimensi.',
              style: TextStyle(
                color: mutedText,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationResult() {
    final double landWidth =
        double.tryParse(controller.lebarController.text.trim()) ?? 0;
    final double landLength =
        double.tryParse(controller.panjangController.text.trim()) ?? 0;
    final double landArea = landWidth * landLength;

    final double totalRecommendedArea = controller.rekomendasiRuang.fold<double>(
      0,
      (total, room) => total + (room.width * room.height),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisCard(
            landWidth: landWidth,
            landLength: landLength,
            landArea: landArea,
            totalRecommendedArea: totalRecommendedArea,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Daftar Ruangan',
                  style: TextStyle(
                    color: navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: orangeSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${controller.rekomendasiRuang.length} ruang',
                  style: const TextStyle(
                    color: orange,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...controller.rekomendasiRuang.map((room) {
            final double area = room.width * room.height;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: orangeSoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      _recommendationIcon(room.category),
                      color: orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: navy,
                            fontSize: 13.8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${room.width.toStringAsFixed(1)} m x ${room.height.toStringAsFixed(1)} m • ${area.toStringAsFixed(1)} m²',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: mutedText,
                            fontSize: 11.7,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard({
    required double landWidth,
    required double landLength,
    required double landArea,
    required double totalRecommendedArea,
  }) {
    final String typeTitle = _getHouseTypeTitle(landArea);
    final String description = _getHouseTypeDescription(landArea);
    final String roomSummary = _getRecommendedRoomSummary();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            orange.withOpacity(0.13),
            orange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: orange.withOpacity(0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeTitle,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${landWidth.toStringAsFixed(1)} m x ${landLength.toStringAsFixed(1)} m • ${landArea.toStringAsFixed(1)} m²',
                      style: const TextStyle(
                        color: mutedText,
                        fontSize: 11.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: const TextStyle(
              color: navy,
              fontSize: 12.7,
              height: 1.48,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            roomSummary,
            style: const TextStyle(
              color: mutedText,
              fontSize: 12.2,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMiniInfo(
                  title: 'Luas Lahan',
                  value: '${landArea.toStringAsFixed(1)} m²',
                  icon: Icons.crop_square_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniInfo(
                  title: 'Luas Ruang',
                  value: '${totalRecommendedArea.toStringAsFixed(1)} m²',
                  icon: Icons.meeting_room_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: orange,
            size: 17,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 11.7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getHouseTypeTitle(double area) {
    if (area <= 45) {
      return 'Kategori: Rumah Tipe Kecil';
    }

    if (area <= 90) {
      return 'Kategori: Rumah Tipe Sedang';
    }

    if (area <= 140) {
      return 'Kategori: Rumah Tipe Besar';
    }

    return 'Kategori: Rumah Tipe Sangat Besar';
  }

  String _getHouseTypeDescription(double area) {
    if (area <= 45) {
      return 'Berdasarkan luas lahan, rumah ini cocok menggunakan konsep kompak dan efisien. Pembagian ruang dibuat sederhana agar area utama tetap nyaman digunakan.';
    }

    if (area <= 90) {
      return 'Berdasarkan luas lahan, rumah ini termasuk tipe sedang. Sistem menyarankan pembagian ruang yang seimbang antara area privat, area keluarga, dan area servis.';
    }

    if (area <= 140) {
      return 'Berdasarkan luas lahan, rumah ini termasuk tipe besar. Denah dapat memuat ruang yang lebih lengkap dengan sirkulasi yang lebih leluasa dan pembagian fungsi ruang yang jelas.';
    }

    return 'Berdasarkan luas lahan, rumah ini termasuk tipe sangat besar. Sistem menyarankan pembagian ruang yang lebih lengkap, termasuk area keluarga, ruang tamu, kamar tambahan, area servis, dan ruang luar.';
  }

  String _getRecommendedRoomSummary() {
    if (controller.rekomendasiRuang.isEmpty) {
      return 'Belum ada daftar ruangan yang direkomendasikan.';
    }

    final List<String> roomNames = controller.rekomendasiRuang
        .map((room) => room.name)
        .take(6)
        .toList();

    final String joinedRooms = roomNames.join(', ');

    if (controller.rekomendasiRuang.length > 6) {
      return 'Ruangan yang cocok untuk luas tersebut antara lain $joinedRooms, dan beberapa ruang pendukung lainnya.';
    }

    return 'Ruangan yang cocok untuk luas tersebut antara lain $joinedRooms.';
  }

  IconData _recommendationIcon(String category) {
    switch (category) {
      case 'bedroom':
        return Icons.bed_rounded;
      case 'bath':
        return Icons.bathtub_rounded;
      case 'kitchen':
        return Icons.kitchen_rounded;
      case 'dining':
        return Icons.dining_rounded;
      case 'living':
        return Icons.chair_rounded;
      case 'family':
        return Icons.weekend_rounded;
      case 'outdoor':
        return Icons.yard_rounded;
      case 'service':
        return Icons.cleaning_services_rounded;
      default:
        return Icons.meeting_room_rounded;
    }
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: controller.prosesGenerate,
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: orange.withOpacity(0.30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(21),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'GENERATE SEKARANG',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 15,
              ),
            ),
            SizedBox(width: 10),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}