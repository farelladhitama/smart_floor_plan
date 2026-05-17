import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/scan_denah_controller.dart';

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
                    _buildResultCard(isMobile),
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
                          'Pilih gambar sketsa denah dari galeri.',
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
                onPressed:
                    controller.isProcessing.value ? null : controller.pickImage,
                icon: Icon(
                  Icons.upload_file_rounded,
                  size: isMobile ? 20 : 22,
                ),
                label: Text(
                  'Pilih Gambar Denah',
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
}