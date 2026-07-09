import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/scan_denah_controller.dart';
import 'scan_camera_capture_page.dart';

class ScanDenahPage extends GetView<ScanDenahController> {
  const ScanDenahPage({super.key});

  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);
  static const Color background = Color(0xFFF5F7FA);
  static const Color softGrey = Color(0xFFEDEFF3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Scan Sketsa Denah',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final bool isMobile = screenWidth < 600;
          final bool isWide = screenWidth > 760;

          final double maxWidth = isWide ? 720 : double.infinity;
          final double horizontalPadding = isMobile ? 16 : 22;
          final double verticalPadding = isMobile ? 16 : 20;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  verticalPadding,
                  horizontalPadding,
                  28,
                ),
                child: Column(
                  children: [
                    _buildHeader(isMobile),
                    SizedBox(height: isMobile ? 16 : 20),
                    _buildImageCard(isMobile),
                    SizedBox(height: isMobile ? 16 : 20),
                    _buildDimensionInput(isMobile), // ✅ TAMBAHKAN INI
                    SizedBox(height: isMobile ? 16 : 20),
                    _buildResultCard(isMobile),
                    SizedBox(height: isMobile ? 16 : 20),
                    _buildMaterialSection(isMobile),
                    SizedBox(height: isMobile ? 16 : 20),
                    _buildButtons(isMobile),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(isMobile ? 22 : 26),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isMobile ? 46 : 52,
            height: isMobile ? 46 : 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.document_scanner_rounded,
              color: Colors.white,
              size: isMobile ? 28 : 32,
            ),
          ),
          SizedBox(height: isMobile ? 14 : 18),
          Text(
            'Computer Vision Denah',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 23 : 28,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 10),
          Text(
            'Upload gambar sketsa denah rumah, lalu sistem akan membaca garis dan bentuk ruangan untuk menghasilkan denah digital sederhana.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: isMobile ? 13.5 : 15,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DIMENSION INPUT ====================
  Widget _buildDimensionInput(bool isMobile) {
    final lebarController = TextEditingController(
      text: controller.scanLandWidth.value.toString(),
    );
    final panjangController = TextEditingController(
      text: controller.scanLandLength.value.toString(),
    );

    lebarController.addListener(() {
      final value = double.tryParse(lebarController.text.replaceAll(',', '.'));
      if (value != null && value > 0) {
        controller.scanLandWidth.value = value;
      }
    });

    panjangController.addListener(() {
      final value = double.tryParse(panjangController.text.replaceAll(',', '.'));
      if (value != null && value > 0) {
        controller.scanLandLength.value = value;
      }
    });

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 22 : 26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isMobile ? 38 : 42,
                height: isMobile ? 38 : 42,
                decoration: BoxDecoration(
                  color: softGrey,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.straighten_rounded,
                  color: navy,
                  size: isMobile ? 21 : 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ukuran Lahan',
                  style: TextStyle(
                    color: navy,
                    fontSize: isMobile ? 18 : 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lebar (m)',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      keyboardType: TextInputType.number,
                      controller: lebarController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        suffixText: 'm',
                        suffixStyle: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panjang (m)',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      keyboardType: TextInputType.number,
                      controller: panjangController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        suffixText: 'm',
                        suffixStyle: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            final luas = controller.scanLandWidth.value *
                controller.scanLandLength.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calculate_rounded,
                    size: 16,
                    color: orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Luas: ${luas.toStringAsFixed(1)} m²',
                    style: TextStyle(
                      color: orange,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 13 : 14,
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

  Widget _buildImageCard(bool isMobile) {
    return Obx(() {
      final imageBytes = controller.selectedImageBytes.value;
      final previewHeight = isMobile ? 240.0 : 330.0;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 22 : 26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            if (imageBytes == null)
              Container(
                height: previewHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_search_rounded,
                          size: isMobile ? 52 : 62,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada gambar denah',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: isMobile ? 13.5 : 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ambil dari kamera atau pilih gambar dari galeri/file.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: isMobile ? 12 : 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  height: previewHeight,
                  color: Colors.white,
                  child: InteractiveViewer(
                    minScale: 0.7,
                    maxScale: 5.0,
                    panEnabled: true,
                    scaleEnabled: true,
                    boundaryMargin: const EdgeInsets.all(100),
                    child: Center(
                      child: Image.memory(
                        imageBytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(height: isMobile ? 14 : 16),
            SizedBox(
              width: double.infinity,
              height: isMobile ? 50 : 54,
              child: ElevatedButton.icon(
                onPressed: controller.isProcessing.value
                    ? null
                    : () => _showImageSourceSheet(controller),
                icon: Icon(
                  Icons.upload_file_rounded,
                  size: isMobile ? 20 : 22,
                ),
                label: Text(
                  'Pilih Kamera / Galeri',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            if (imageBytes != null) ...[
              const SizedBox(height: 10),
              Text(
                'Geser untuk melihat bagian lain. Cubit atau scroll untuk zoom.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: isMobile ? 11.5 : 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildResultCard(bool isMobile) {
    return Obx(() {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 16 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 22 : 26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isMobile ? 38 : 42,
                  height: isMobile ? 38 : 42,
                  decoration: BoxDecoration(
                    color: softGrey,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.auto_awesome_motion_rounded,
                    color: navy,
                    size: isMobile ? 21 : 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hasil Deteksi OpenCV',
                    style: TextStyle(
                      color: navy,
                      fontSize: isMobile ? 18 : 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 14 : 16),
            if (controller.isProcessing.value)
              Padding(
                padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
                child: Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        'Memproses gambar dengan OpenCV...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (controller.detectedRooms.isEmpty)
              Text(
                controller.message.value.isEmpty
                    ? 'Belum ada ruangan terdeteksi.'
                    : controller.message.value,
                style: TextStyle(
                  color: Colors.black54,
                  height: 1.5,
                  fontSize: isMobile ? 13 : 14,
                ),
              )
            else ...[
              Text(
                controller.message.value,
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 13 : 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              ...controller.detectedRooms.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final room = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 14,
                      vertical: isMobile ? 11 : 13,
                    ),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: isMobile ? 24 : 28,
                          height: isMobile ? 24 : 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: navy,
                                fontSize: isMobile ? 11 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            room.nama,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: navy,
                              fontSize: isMobile ? 13.5 : 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${room.width.toStringAsFixed(0)} x ${room.height.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.black45,
                            fontSize: isMobile ? 11.5 : 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildMaterialSection(bool isMobile) {
    return Obx(() {
      if (controller.isLoadingMaterials.value &&
          controller.materialOptionsByCategory.isEmpty) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 16 : 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isMobile ? 22 : 26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.045),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
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
                  'Memuat pilihan material...',
                  style: TextStyle(
                    color: navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 16 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 22 : 26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isMobile ? 38 : 42,
                  height: isMobile ? 38 : 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E8),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.layers_rounded,
                    color: orange,
                    size: isMobile ? 21 : 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pilihan Material Scan',
                    style: TextStyle(
                      color: navy,
                      fontSize: isMobile ? 18 : 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih material untuk hasil scan agar RAB mengikuti pilihan bahan bangunan.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: isMobile ? 12.5 : 13.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            ...controller.materialCategories.map((category) {
              final List<String> options =
                  controller.materialOptionsByCategory[category] ?? <String>[];

              if (options.isEmpty) {
                return const SizedBox.shrink();
              }

              final String? selected = controller.selectedMaterials[category];

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
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
                    ),
                    items: options.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.layers_rounded,
                                color: navy,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 11),
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
                                      color: Colors.black45,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: navy,
                                      fontSize: isMobile ? 13 : 14,
                                      fontWeight: FontWeight.bold,
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
            }),
          ],
        ),
      );
    });
  }

  Widget _buildButtons(bool isMobile) {
    return Obx(() {
      final hasRooms = controller.detectedRooms.isNotEmpty;

      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: isMobile ? 50 : 54,
            child: ElevatedButton.icon(
              onPressed: hasRooms ? controller.openResult : null,
              icon: Icon(
                Icons.map_rounded,
                size: isMobile ? 20 : 22,
              ),
              label: Text(
                'Buka Hasil Denah',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: isMobile ? 50 : 54,
            child: OutlinedButton.icon(
              onPressed: controller.reset,
              icon: Icon(
                Icons.refresh_rounded,
                size: isMobile ? 20 : 22,
              ),
              label: Text(
                'Reset',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: navy,
                side: const BorderSide(color: navy),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  void _showImageSourceSheet(ScanDenahController controller) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(26),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pilih Sumber Denah',
                  style: TextStyle(
                    color: navy,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Gunakan kamera atau pilih gambar denah kosong dari galeri/file.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _imageSourceButton(
                icon: Icons.camera_alt_rounded,
                title: 'Ambil dari Kamera',
                subtitle: 'Buka kamera HP atau kamera laptop/browser',
                onTap: () async {
                  Get.back();

                  final result = await Get.to<Map<String, dynamic>>(
                    () => const ScanCameraCapturePage(),
                  );

                  if (result == null) return;

                  final dynamic bytes = result['bytes'];
                  final String filename =
                      (result['filename'] ?? 'scan_camera.jpg').toString();

                  if (bytes is Uint8List) {
                    await controller.scanPickedImageBytes(
                      bytes: bytes,
                      filename: filename,
                      fromCamera: true,
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _imageSourceButton(
                icon: Icons.photo_library_rounded,
                title: 'Pilih dari Galeri / File',
                subtitle: 'Ambil gambar denah kosong yang sudah tersimpan',
                onTap: () {
                  Get.back();
                  controller.pickImageFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Widget _imageSourceButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.withOpacity(0.14),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1E8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: orange,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: navy,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 