import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/modules/generate_form/controllers/generate_form_controller.dart';
import 'package:smart_floor_plan/app/routes/app_routes.dart';

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

                        // ===== AI ASSISTANT =====
                        _buildAIAssistant(),
                        const SizedBox(height: 28),

                        _sectionTitle(
                          title: 'Dimensi Lahan',
                          subtitle: 'Masukkan ukuran lebar dan panjang tanah untuk memulai analisis denah.',
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
                                    textController: controller.panjangController,
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
                                      textController: controller.lebarController,
                                      icon: Icons.straighten_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _buildInputField(
                                      label: 'Panjang Lahan (m)',
                                      hint: 'Contoh: 12',
                                      textController: controller.panjangController,
                                      icon: Icons.square_foot_rounded,
                                    ),
                                  ),
                                ],
                              ),

                        const SizedBox(height: 28),

                        _sectionTitle(
                          title: 'Pilihan Material Utama',
                          subtitle: 'Pilih material utama sesuai data harga dari hasil Big Data/API.',
                        ),
                        const SizedBox(height: 14),
                        _buildMaterialDropdown(),

                        const SizedBox(height: 28),

                        _sectionTitle(
                          title: 'Tambahan Ruangan',
                          subtitle: 'Tulis kebutuhan ruang tambahan, pisahkan dengan koma. Contoh: mushola, gudang, ruang kerja.',
                        ),
                        const SizedBox(height: 14),
                        _buildTambahanRuanganField(),

                        const SizedBox(height: 28),

                        _sectionTitle(
                          title: 'Jenis Tukang',
                          subtitle: 'Pilih metode pengerjaan proyek.',
                        ),
                        const SizedBox(height: 14),

                        Obx(
                          () => DropdownButtonFormField<String>(
                            value: controller.selectedTukang.value,
                            decoration: InputDecoration(
                              labelText: 'Pilih Jenis Tukang',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            items: controller.tukangOptions.map((item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                controller.selectedTukang.value = value;
                              }
                            },
                          ),
                        ),
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

  // ============= AI ASSISTANT WIDGET =============
  Widget _buildAIAssistant() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            navy,
            navySoft,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: orange,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  '🧠 AI Smart Design Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Obx(
                () => Visibility(
                  visible: controller.useAIAnalysis.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: const Text(
                      'AI Active',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Jelaskan kebutuhan rumah Anda secara natural. AI akan menganalisis dan memberikan rekomendasi desain terbaik.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          // TextField Prompt
          TextFormField(
            controller: controller.aiPromptController,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Contoh: Saya ingin rumah minimalis modern untuk keluarga 5 orang dengan 3 kamar tidur, 2 kamar mandi, ruang kerja, mushola, taman belakang, garasi 2 mobil...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 12,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: orange.withOpacity(0.6),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: controller.isLoadingAI.value
                          ? null
                          : controller.analisisAI,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        disabledBackgroundColor: orange.withOpacity(0.5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: controller.isLoadingAI.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Analisis dengan AI',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Obx(
                () => Visibility(
                  visible: controller.useAIAnalysis.value,
                  child: SizedBox(
                    height: 48,
                    child: IconButton(
                      onPressed: controller.resetAI,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Hasil AI
          Obx(
            () {
              final params = controller.aiParams.value;
              if (params == null) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(top: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 Hasil Analisis AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildAITag('🏠 ${params.style}'),
                        _buildAITag('👤 ${params.familySize} orang'),
                        _buildAITag('🛏️ ${params.bedroom} kamar'),
                        _buildAITag('🚿 ${params.bathroom} km/wc'),
                        if (params.garage > 0)
                          _buildAITag('🚗 ${params.garage} mobil'),
                        _buildAITag('🎯 ${params.priority}'),
                        ...params.extraRooms.map(
                          (room) => _buildAITag('➕ $room'),
                        ),
                        if (params.garden != 'Tidak Ada')
                          _buildAITag('🌿 Taman ${params.garden.toLowerCase()}'),
                      ],
                    ),
                    if (params.budget != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '💰 Budget: Rp ${_formatCurrency(params.budget!)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)} Miliar';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)} Juta';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  Widget _buildAITag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============= EXISTING WIDGETS =============
  
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
    return Obx(
      () {
        if (controller.isLoadingMaterials.value &&
            controller.materialOptionsByCategory.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: orange,
                    strokeWidth: 2.4,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Memuat pilihan material dari Supabase...',
                    style: TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: controller.materialCategories.map((category) {
            final options =
                controller.materialOptionsByCategory[category] ?? <String>[];

            if (options.isEmpty) {
              return const SizedBox.shrink();
            }

            final selected = controller.selectedMaterials[category];

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 13),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: navy.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selected != null && options.contains(selected)
                      ? selected
                      : options.first,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: navy,
                    size: 28,
                  ),
                  items: options.map((String value) {
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: mutedText,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: navy,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    controller.changeMaterialForCategory(category, value);
                  },
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTambahanRuanganField() {
    return TextFormField(
      controller: controller.tambahanRuanganController,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      minLines: 1,
      maxLines: 3,
      style: const TextStyle(
        color: navy,
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        hintText: 'Contoh: mushola, gudang, ruang kerja',
        helperText: 'Boleh kosong. Gunakan koma untuk lebih dari satu ruangan.',
        helperStyle: const TextStyle(
          color: mutedText,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: const Icon(
          Icons.add_home_work_rounded,
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
      ),
    );
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