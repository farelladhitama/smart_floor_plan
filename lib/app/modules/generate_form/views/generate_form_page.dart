import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/core/floorplan/room_recommendation.dart';
import 'package:smart_floor_plan/app/core/floorplan/smart_floor_plan_engine.dart';
import 'package:smart_floor_plan/app/modules/generate_form/controllers/generate_form_controller.dart';

class GenerateFormPage extends GetView<GenerateFormController> {
  const GenerateFormPage({super.key});

  static const Color navy = Color(0xFF0D1B2A);
  static const Color navyLight = Color(0xFF1B263B);
  static const Color orange = Color(0xFFE47B3E);
  static const Color background = Color(0xFFF5F7FA);
  static const Color border = Color(0xFFE2E8F0);
  static const Color mutedText = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Kebutuhan Rumah',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: navy,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 600;
            final bool isSmallMobile = constraints.maxWidth < 380;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    isSmallMobile ? 16 : 22,
                    20,
                    isSmallMobile ? 16 : 22,
                    34,
                  ),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIntroCard(isSmallMobile),
                        const SizedBox(height: 26),
                        _buildDimensionSection(isMobile),
                        const SizedBox(height: 26),
                        _buildMaterialSection(),
                        const SizedBox(height: 26),
                        _buildRecommendationSection(),
                        const SizedBox(height: 28),
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

  Widget _buildIntroCard(bool isSmallMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallMobile ? 19 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navy, navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isSmallMobile ? 56 : 62,
            height: isSmallMobile ? 56 : 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.architecture_rounded,
              color: orange,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Layout Planner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Masukkan dimensi lahan, lalu sistem merekomendasikan ruang dan menyusun denah otomatis.',
                  style: TextStyle(
                    color: Color(0xFFC2CBD5),
                    fontSize: 12.5,
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

  Widget _buildDimensionSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          title: 'Dimensi Lahan',
          subtitle:
              'Masukkan lebar dan panjang tanah untuk dianalisis sistem.',
        ),
        const SizedBox(height: 14),
        isMobile
            ? Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'Lebar (m)',
                      textController: controller.lebarController,
                      icon: Icons.straighten_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      label: 'Panjang (m)',
                      textController: controller.panjangController,
                      icon: Icons.square_foot_rounded,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'Lebar (m)',
                      textController: controller.lebarController,
                      icon: Icons.straighten_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildInputField(
                      label: 'Panjang (m)',
                      textController: controller.panjangController,
                      icon: Icons.square_foot_rounded,
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildMaterialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          title: 'Pilihan Material Dinding',
          subtitle: 'Material digunakan untuk estimasi biaya RAB.',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: navy.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 6),
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
                  size: 27,
                ),
                items: controller.materialOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.layers_rounded,
                          color: navy,
                          size: 21,
                        ),
                        const SizedBox(width: 11),
                        Text(
                          value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: navy,
                            fontSize: 14,
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
        ),
      ],
    );
  }

  Widget _buildRecommendationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          title: 'Rekomendasi Sistem',
          subtitle:
              'Ruang ideal akan ditentukan otomatis berdasarkan kapasitas lahan.',
        ),
        const SizedBox(height: 14),
        AnimatedBuilder(
          animation: Listenable.merge([
            controller.lebarController,
            controller.panjangController,
          ]),
          builder: (context, _) {
            final double lebar =
                double.tryParse(controller.lebarController.text.trim()) ?? 0;
            final double panjang =
                double.tryParse(controller.panjangController.text.trim()) ?? 0;
            final double luas = lebar * panjang;

            if (lebar <= 0 || panjang <= 0) {
              return _buildWaitingRecommendation();
            }

            final _HouseRecommendation profile = _profileFromArea(luas);

            final List<RoomRecommendation> roomRecommendations =
                SmartFloorPlanEngine.getRecommendations(
              landWidth: lebar,
              landLength: panjang,
              bedroomCount: profile.bedrooms,
            );

            final List<RoomRecommendation> supportingRooms =
                roomRecommendations.where((room) {
              return room.category != 'bedroom' && room.category != 'bath';
            }).toList();

            return _buildRecommendationCard(
              lebar: lebar,
              panjang: panjang,
              luas: luas,
              profile: profile,
              rooms: supportingRooms,
            );
          },
        ),
      ],
    );
  }

  Widget _buildWaitingRecommendation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: orange,
              size: 29,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Rekomendasi belum tersedia',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Isi ukuran lebar dan panjang lahan untuk melihat kebutuhan ruang yang disarankan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedText,
              fontWeight: FontWeight.w500,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard({
    required double lebar,
    required double panjang,
    required double luas,
    required _HouseRecommendation profile,
    required List<RoomRecommendation> rooms,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: orange,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Plan Analysis',
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Rekomendasi siap digunakan',
                      style: TextStyle(
                        color: mutedText,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SESUAI',
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: _analysisTile(
                  label: 'Luas',
                  value: '${luas.toStringAsFixed(1)} m²',
                  icon: Icons.square_foot_rounded,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _analysisTile(
                  label: 'Tipe',
                  value: profile.shortCategory,
                  icon: Icons.home_work_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _analysisTile(
            label: 'Kapasitas Penghuni',
            value: profile.capacity,
            icon: Icons.groups_rounded,
          ),
          const SizedBox(height: 18),
          const Text(
            'Kebutuhan Utama yang Disarankan',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _primarySuggestionChip(
                icon: Icons.bed_rounded,
                text: '${profile.bedrooms} Kamar Tidur',
              ),
              _primarySuggestionChip(
                icon: Icons.bathroom_rounded,
                text: '${profile.bathrooms} Kamar Mandi',
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'Ruang Pendukung',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: rooms.map((room) {
              return _supportingRoomChip(room.name);
            }).toList(),
          ),
          const SizedBox(height: 17),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: orange.withValues(alpha: 0.12),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tips_and_updates_rounded,
                  color: orange,
                  size: 19,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Denah akan disusun otomatis dengan peletakan ruang natural dan pengecekan tabrakan ruang.',
                    style: TextStyle(
                      color: navy,
                      fontSize: 11.8,
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _analysisTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: orange, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _primarySuggestionChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: orange.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: orange, size: 17),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _supportingRoomChip(String roomName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: border),
      ),
      child: Text(
        roomName,
        style: const TextStyle(
          color: navy,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
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
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: navy,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.5,
            color: mutedText,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController textController,
    required IconData icon,
  }) {
    return TextFormField(
      controller: textController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(
        color: navy,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: mutedText,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: navy, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.3),
        ),
      ),
      validator: controller.validateNumber,
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 57,
      child: ElevatedButton.icon(
        onPressed: _generateUsingRecommendation,
        icon: const Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 20,
        ),
        label: const Text(
          'GENERATE SESUAI REKOMENDASI',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 13.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: orange.withValues(alpha: 0.27),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  void _generateUsingRecommendation() {
    final formState = controller.formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final double lebar =
        double.tryParse(controller.lebarController.text.trim()) ?? 0;
    final double panjang =
        double.tryParse(controller.panjangController.text.trim()) ?? 0;

    final _HouseRecommendation profile = _profileFromArea(lebar * panjang);

    controller.jumlahKamar.value = profile.bedrooms;
    controller.updateRekomendasiRuang();
    controller.prosesGenerate();
  }

  _HouseRecommendation _profileFromArea(double area) {
    if (area >= 180) {
      return const _HouseRecommendation(
        category: 'Rumah Keluarga Besar',
        shortCategory: 'Besar',
        capacity: '4 - 6 Orang',
        bedrooms: 3,
        bathrooms: 2,
      );
    }

    if (area >= 120) {
      return const _HouseRecommendation(
        category: 'Rumah Keluarga Sedang',
        shortCategory: 'Sedang',
        capacity: '3 - 5 Orang',
        bedrooms: 3,
        bathrooms: 2,
      );
    }

    if (area >= 70) {
      return const _HouseRecommendation(
        category: 'Rumah Minimalis Sedang',
        shortCategory: 'Minimalis',
        capacity: '2 - 4 Orang',
        bedrooms: 2,
        bathrooms: 1,
      );
    }

    return const _HouseRecommendation(
      category: 'Rumah Minimalis Kecil',
      shortCategory: 'Kecil',
      capacity: '1 - 2 Orang',
      bedrooms: 1,
      bathrooms: 1,
    );
  }
}

class _HouseRecommendation {
  final String category;
  final String shortCategory;
  final String capacity;
  final int bedrooms;
  final int bathrooms;

  const _HouseRecommendation({
    required this.category,
    required this.shortCategory,
    required this.capacity,
    required this.bedrooms,
    required this.bathrooms,
  });
}