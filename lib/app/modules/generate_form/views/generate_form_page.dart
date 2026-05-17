import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/modules/generate_form/controllers/generate_form_controller.dart';

class GenerateFormPage extends GetView<GenerateFormController> {
  const GenerateFormPage({super.key});

  static const Color navy = Color(0xFF0D1B2A);
  static const Color navyLight = Color(0xFF1B263B);
  static const Color orange = Color(0xFFE47B3E);
  static const Color background = Color(0xFFF5F7FA);

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
            final bool isMobile = constraints.maxWidth < 600;
            final bool isSmallMobile = constraints.maxWidth < 380;
            final double horizontalPadding = isSmallMobile ? 18 : 24;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 520,
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
                        _buildIntroCard(isSmallMobile),

                        const SizedBox(height: 28),

                        _sectionTitle(
                          title: 'Dimensi Lahan',
                          subtitle: 'Masukkan ukuran lebar dan panjang tanah.',
                        ),

                        const SizedBox(height: 14),

                        isMobile
                            ? Column(
                                children: [
                                  _buildInputField(
                                    label: 'Lebar (m)',
                                    textController: controller.lebarController,
                                    icon: Icons.straighten_rounded,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildInputField(
                                    label: 'Panjang (m)',
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
                                      label: 'Lebar (m)',
                                      textController:
                                          controller.lebarController,
                                      icon: Icons.straighten_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildInputField(
                                      label: 'Panjang (m)',
                                      textController:
                                          controller.panjangController,
                                      icon: Icons.square_foot_rounded,
                                    ),
                                  ),
                                ],
                              ),

                        const SizedBox(height: 28),

                        _sectionTitle(
                          title: 'Jumlah Kamar Tidur',
                          subtitle: 'Tentukan jumlah kamar utama.',
                        ),

                        const SizedBox(height: 14),

                        _buildCounterSection(),

                        const SizedBox(height: 28),

                        _sectionTitle(
                          title: 'Pilihan Material Dinding',
                          subtitle: 'Material akan digunakan untuk estimasi RAB.',
                        ),

                        const SizedBox(height: 14),

                        _buildMaterialDropdown(),

                        const SizedBox(height: 28),

                        _sectionTitle(
                          title: 'Ruang Tambahan',
                          subtitle: 'Tambahkan ruang lain sesuai kebutuhan.',
                        ),

                        const SizedBox(height: 14),

                        _buildDynamicInputSection(isMobile),

                        const SizedBox(height: 18),

                        Obx(
                          () => controller.listRuangCustom.isEmpty
                              ? const SizedBox.shrink()
                              : _buildRoomChips(),
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

  Widget _buildIntroCard(bool isSmallMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            navy,
            navyLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
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
            width: isSmallMobile ? 58 : 66,
            height: isSmallMobile ? 58 : 66,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.architecture_rounded,
              color: orange,
              size: 36,
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
                const SizedBox(height: 6),
                Text(
                  'Isi kebutuhan rumah Anda untuk membuat denah 2D otomatis.',
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
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
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
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: orange,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.red.shade300,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1.4,
          ),
        ),
      ),
      validator: controller.validateNumber,
    );
  }

  Widget _buildCounterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.bed_rounded,
              color: orange,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Jumlah Kamar',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: navy,
                fontSize: 15,
              ),
            ),
          ),
          Row(
            children: [
              _counterBtn(
                Icons.remove_rounded,
                controller.kurangKamar,
              ),
              SizedBox(
                width: 52,
                child: Center(
                  child: Obx(
                    () => Text(
                      '${controller.jumlahKamar.value}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: navy,
                      ),
                    ),
                  ),
                ),
              ),
              _counterBtn(
                Icons.add_rounded,
                controller.tambahKamar,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: navy,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: Colors.white,
            size: 23,
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
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
                    const Icon(
                      Icons.layers_rounded,
                      color: navy,
                      size: 22,
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

  Widget _buildDynamicInputSection(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildAdditionalRoomField(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: _buildAddRoomButton(),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildAdditionalRoomField(),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 68,
          height: 56,
          child: _buildAddRoomButton(),
        ),
      ],
    );
  }

  Widget _buildAdditionalRoomField() {
    return TextFormField(
      controller: controller.ruangTambahanController,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => controller.tambahRuang(),
      style: const TextStyle(
        color: navy,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: 'Contoh: Mushola, Gudang...',
        hintStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
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
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: orange,
            width: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildAddRoomButton() {
    return ElevatedButton(
      onPressed: controller.tambahRuang,
      style: ElevatedButton.styleFrom(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: navy.withOpacity(0.20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: const Icon(
        Icons.add_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildRoomChips() {
    return Obx(
      () => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: controller.listRuangCustom.map((ruang) {
          return Chip(
            label: Text(
              ruang,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: orange,
            deleteIcon: const Icon(
              Icons.cancel_rounded,
              size: 17,
              color: Colors.white,
            ),
            onDeleted: () => controller.hapusRuang(ruang),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          );
        }).toList(),
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
            borderRadius: BorderRadius.circular(20),
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
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}