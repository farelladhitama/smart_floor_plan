import 'package:smart_floor_plan/app/data/models/room_model.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/widgets/floor_plan_asset_overlay.dart';
import 'package:smart_floor_plan/app/widgets/professional_floor_plan_painter.dart';

class EditDenahPage extends StatefulWidget {
  final List<RoomModel> initialRooms;
  final double? inputLebarRumah;
  final double? inputPanjangRumah;
  final double? landWidth;
  final double? landLength;
  final double? initialLandWidth;
  final double? initialLandLength;

  const EditDenahPage({
    super.key,
    this.initialRooms = const [],
    this.inputLebarRumah,
    this.inputPanjangRumah,
    this.landWidth,
    this.landLength,
    this.initialLandWidth,
    this.initialLandLength,
  });

  @override
  State<EditDenahPage> createState() => _EditDenahPageState();
}

class _EditDenahPageState extends State<EditDenahPage> {
  late List<RoomModel> _rooms;
  int? _selectedIndex;

  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);
  static const Color bg = Color(0xFFF5F7FA);
  static const Color textDark = Color(0xFF102033);
  static const Color textSoft = Color(0xFF6B7A90);

  @override
  void initState() {
    super.initState();
    _rooms = _readInitialRooms();
  }

  List<RoomModel> _readInitialRooms() {
    if (widget.initialRooms.isNotEmpty) {
      return widget.initialRooms
          .map(
            (room) => RoomModel(
              nama: room.nama,
              category: room.category,
              x: room.x,
              y: room.y,
              width: room.width,
              height: room.height,
            ),
          )
          .toList();
    }

    final dynamic args = Get.arguments;

    if (args is Map && args['rooms'] is Iterable) {
      try {
        return (args['rooms'] as Iterable)
            .cast<RoomModel>()
            .map(
              (room) => RoomModel(
                nama: room.nama,
                category: room.category,
                x: room.x,
                y: room.y,
                width: room.width,
                height: room.height,
              ),
            )
            .toList();
      } catch (_) {
        return <RoomModel>[];
      }
    }

    return <RoomModel>[];
  }

  double get _landWidth {
    final dynamic args = Get.arguments;

    return widget.inputLebarRumah ??
        widget.landWidth ??
        widget.initialLandWidth ??
        _readDoubleFromArgs(args, [
          'inputLebarRumah',
          'landWidth',
          'initialLandWidth',
          'lebarRumah',
          'lebarLahan',
        ]) ??
        8.0;
  }

  double get _landLength {
    final dynamic args = Get.arguments;

    return widget.inputPanjangRumah ??
        widget.landLength ??
        widget.initialLandLength ??
        _readDoubleFromArgs(args, [
          'inputPanjangRumah',
          'landLength',
          'initialLandLength',
          'panjangRumah',
          'panjangLahan',
        ]) ??
        10.0;
  }

  double? _readDoubleFromArgs(dynamic args, List<String> keys) {
    if (args is! Map) return null;

    for (final String key in keys) {
      final dynamic value = args[key];

      if (value is num) {
        return value.toDouble();
      }

      if (value is String) {
        final double? parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final double landWidth = _landWidth;
    final double landLength = _landLength;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    _buildEditCanvas(
                      rooms: _rooms,
                      landWidth: landWidth,
                      landLength: landLength,
                    ),
                    const SizedBox(height: 16),
                    _buildEditInstruction(),
                    const SizedBox(height: 14),
                    _buildResizePanel(),
                    const SizedBox(height: 92),
                  ],
                ),
              ),
            ),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        InkWell(
          onTap: () => Get.back(),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: navy,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Layout Arsitektural',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Klik ruang untuk memilih • drag untuk menggeser',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: textSoft,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E8),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'EDIT MODE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: orange,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditCanvas({
    required List<RoomModel> rooms,
    required double landWidth,
    required double landLength,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE3E9F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCanvasTitle(),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              height: 560,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                border: Border.all(
                  color: const Color(0xFFDDE6EF),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: rooms.isEmpty
                  ? _buildEmptyPreview()
                  : InteractiveViewer(
                      minScale: 0.75,
                      maxScale: 3.2,
                      boundaryMargin: const EdgeInsets.all(80),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final Size canvasSize = Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );

                          return Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: ProfessionalFloorPlanPainter(
                                    rooms: rooms,
                                    inputLebarRumah: landWidth,
                                    inputPanjangRumah: landLength,
                                    title: 'EDITABLE SMARTFLOORPLAN',
                                  ),
                                ),
                              ),

                              // Overlay asset realistis.
                              Positioned.fill(
                                child: FloorPlanAssetOverlay(
                                  rooms: rooms,
                                  landWidth: landWidth,
                                  landLength: landLength,
                                ),
                              ),

                              // Gesture harus di paling atas supaya klik/drag tetap jalan.
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTapDown: (details) {
                                    final int? index = _findRoomIndexAt(
                                      details.localPosition,
                                      canvasSize,
                                      rooms,
                                      landWidth,
                                      landLength,
                                    );

                                    setState(() {
                                      _selectedIndex = index;
                                    });
                                  },
                                  onPanStart: (details) {
                                    final int? index = _findRoomIndexAt(
                                      details.localPosition,
                                      canvasSize,
                                      rooms,
                                      landWidth,
                                      landLength,
                                    );

                                    setState(() {
                                      _selectedIndex = index;
                                    });
                                  },
                                  onPanUpdate: (details) {
                                    if (_selectedIndex == null) return;

                                    _moveRoomByPixelDelta(
                                      index: _selectedIndex!,
                                      delta: details.delta,
                                      canvasSize: canvasSize,
                                      landWidth: landWidth,
                                      landLength: landLength,
                                    );
                                  },
                                  child: CustomPaint(
                                    painter: _EditSelectionPainter(
                                      rooms: rooms,
                                      selectedIndex: _selectedIndex,
                                      landWidth: landWidth,
                                      landLength: landLength,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Cubit atau scroll untuk zoom • klik ruang lalu drag untuk menggeser',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: textSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasTitle() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Edit Denah Rendered',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: textDark,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'DRAG MODE',
            style: TextStyle(
              color: orange,
              fontWeight: FontWeight.w900,
              fontSize: 10.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPreview() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 54,
              color: textSoft,
            ),
            SizedBox(height: 12),
            Text(
              'Data ruangan belum tersedia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Silakan buka edit dari hasil denah atau riwayat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSoft,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditInstruction() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFD5B5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: orange,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedIndex == null
                  ? 'Pilih salah satu ruang pada denah. Setelah dipilih, drag ruang untuk mengatur posisi layout.'
                  : 'Ruang sedang dipilih. Drag pada area denah untuk menggeser posisi ruang, gunakan panel ukuran, atau rotasi 90°.',
              style: const TextStyle(
                color: Color(0xFF7A4A1F),
                fontWeight: FontWeight.w600,
                fontSize: 13.2,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResizePanel() {
    if (_selectedIndex == null ||
        _selectedIndex! < 0 ||
        _selectedIndex! >= _rooms.length) {
      return const SizedBox.shrink();
    }

    final RoomModel selectedRoom = _rooms[_selectedIndex!];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE3E9F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.open_in_full_rounded,
                  color: orange,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedRoom.nama,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${selectedRoom.width.toStringAsFixed(1)} m x ${selectedRoom.height.toStringAsFixed(1)} m',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: textSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _resizeRow(
            title: 'Lebar Ruang',
            value: '${selectedRoom.width.toStringAsFixed(1)} m',
            onMinus: () => _resizeSelectedRoom(
              deltaWidth: -0.2,
              deltaHeight: 0,
            ),
            onPlus: () => _resizeSelectedRoom(
              deltaWidth: 0.2,
              deltaHeight: 0,
            ),
          ),
          const SizedBox(height: 12),
          _resizeRow(
            title: 'Panjang Ruang',
            value: '${selectedRoom.height.toStringAsFixed(1)} m',
            onMinus: () => _resizeSelectedRoom(
              deltaWidth: 0,
              deltaHeight: -0.2,
            ),
            onPlus: () => _resizeSelectedRoom(
              deltaWidth: 0,
              deltaHeight: 0.2,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _quickResizeButton(
                  label: 'Perkecil',
                  icon: Icons.compress_rounded,
                  onTap: () => _resizeSelectedRoom(
                    deltaWidth: -0.2,
                    deltaHeight: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickResizeButton(
                  label: 'Perbesar',
                  icon: Icons.expand_rounded,
                  onTap: () => _resizeSelectedRoom(
                    deltaWidth: 0.2,
                    deltaHeight: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _quickResizeButton(
            label: 'Rotasi Ruangan 90°',
            icon: Icons.rotate_90_degrees_ccw_rounded,
            onTap: _rotateSelectedRoom,
          ),
        ],
      ),
    );
  }

  Widget _resizeRow({
    required String title,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSoft,
                ),
              ),
            ],
          ),
        ),
        _resizeButton(
          icon: Icons.remove_rounded,
          onTap: onMinus,
        ),
        const SizedBox(width: 10),
        _resizeButton(
          icon: Icons.add_rounded,
          onTap: onPlus,
        ),
      ],
    );
  }

  Widget _resizeButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: navy,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 23,
        ),
      ),
    );
  }

  Widget _quickResizeButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE3E9F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: navy,
              size: 19,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: navy,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resizeSelectedRoom({
    required double deltaWidth,
    required double deltaHeight,
  }) {
    if (_selectedIndex == null) return;
    if (_selectedIndex! < 0 || _selectedIndex! >= _rooms.length) return;

    final double safeLandWidth = _landWidth <= 0 ? 1 : _landWidth;
    final double safeLandLength = _landLength <= 0 ? 1 : _landLength;

    final RoomModel oldRoom = _rooms[_selectedIndex!];

    const double minRoomWidth = 1.2;
    const double minRoomHeight = 1.2;

    final double maxWidth = math.max(
      minRoomWidth,
      safeLandWidth - oldRoom.x,
    );

    final double maxHeight = math.max(
      minRoomHeight,
      safeLandLength - oldRoom.y,
    );

    final double newWidth = (oldRoom.width + deltaWidth)
        .clamp(minRoomWidth, maxWidth)
        .toDouble();

    final double newHeight = (oldRoom.height + deltaHeight)
        .clamp(minRoomHeight, maxHeight)
        .toDouble();

    setState(() {
      _rooms[_selectedIndex!] = RoomModel(
        nama: oldRoom.nama,
        category: oldRoom.category,
        x: oldRoom.x,
        y: oldRoom.y,
        width: newWidth,
        height: newHeight,
      );
    });
  }

  void _rotateSelectedRoom() {
    if (_selectedIndex == null) return;
    if (_selectedIndex! < 0 || _selectedIndex! >= _rooms.length) return;

    final double safeLandWidth = _landWidth <= 0 ? 1 : _landWidth;
    final double safeLandLength = _landLength <= 0 ? 1 : _landLength;

    final RoomModel oldRoom = _rooms[_selectedIndex!];

    final double rotatedWidth = oldRoom.height;
    final double rotatedHeight = oldRoom.width;

    double newX = oldRoom.x;
    double newY = oldRoom.y;

    if (newX + rotatedWidth > safeLandWidth) {
      newX = math.max(0, safeLandWidth - rotatedWidth);
    }

    if (newY + rotatedHeight > safeLandLength) {
      newY = math.max(0, safeLandLength - rotatedHeight);
    }

    setState(() {
      _rooms[_selectedIndex!] = RoomModel(
        nama: oldRoom.nama,
        category: oldRoom.category,
        x: newX,
        y: newY,
        width: rotatedWidth,
        height: rotatedHeight,
      );
    });
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 58,
              child: OutlinedButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close_rounded, size: 20),
                label: const Text(
                  'BATAL',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: navy,
                  side: const BorderSide(color: navy, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 58,
              child: ElevatedButton.icon(
                onPressed: _rooms.isEmpty
                    ? null
                    : () {
                        Get.back(result: _rooms);

                        Get.snackbar(
                          'Berhasil',
                          'Hasil edit denah berhasil disimpan.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: navy,
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 16,
                          duration: const Duration(seconds: 2),
                        );
                      },
                icon: const Icon(
                  Icons.save_rounded,
                  size: 20,
                ),
                label: const Text(
                  'SIMPAN HASIL EDIT',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Rect _calcPlotRect(Size size, double landWidth, double landLength) {
    final Rect boardRect = Rect.fromLTWH(
      18,
      18,
      size.width - 36,
      size.height - 36,
    );

    const double leftPad = 58;
    const double rightPad = 52;
    const double topPad = 54;
    const double bottomPad = 54;

    final double availableWidth = boardRect.width - leftPad - rightPad;
    final double availableHeight = boardRect.height - topPad - bottomPad;

    final double safeW = landWidth <= 0 ? 1 : landWidth;
    final double safeL = landLength <= 0 ? 1 : landLength;

    final double scale = math.min(
      availableWidth / safeW,
      availableHeight / safeL,
    );

    final double plotWidth = safeW * scale;
    final double plotHeight = safeL * scale;

    final double left =
        boardRect.left + leftPad + ((availableWidth - plotWidth) / 2);

    final double top =
        boardRect.top + topPad + ((availableHeight - plotHeight) / 2);

    return Rect.fromLTWH(left, top, plotWidth, plotHeight);
  }

  Rect _roomRect({
    required RoomModel room,
    required Rect plotRect,
    required double landWidth,
    required double landLength,
  }) {
    final double safeW = landWidth <= 0 ? 1 : landWidth;
    final double safeL = landLength <= 0 ? 1 : landLength;

    final double scaleX = plotRect.width / safeW;
    final double scaleY = plotRect.height / safeL;

    return Rect.fromLTWH(
      plotRect.left + (room.x * scaleX),
      plotRect.top + (room.y * scaleY),
      room.width * scaleX,
      room.height * scaleY,
    );
  }

  int? _findRoomIndexAt(
    Offset localPosition,
    Size canvasSize,
    List<RoomModel> rooms,
    double landWidth,
    double landLength,
  ) {
    final Rect plotRect = _calcPlotRect(
      canvasSize,
      landWidth,
      landLength,
    );

    for (int i = rooms.length - 1; i >= 0; i--) {
      final Rect rect = _roomRect(
        room: rooms[i],
        plotRect: plotRect,
        landWidth: landWidth,
        landLength: landLength,
      );

      if (rect.contains(localPosition)) {
        return i;
      }
    }

    return null;
  }

  void _moveRoomByPixelDelta({
    required int index,
    required Offset delta,
    required Size canvasSize,
    required double landWidth,
    required double landLength,
  }) {
    if (index < 0 || index >= _rooms.length) return;

    final Rect plotRect = _calcPlotRect(
      canvasSize,
      landWidth,
      landLength,
    );

    final double safeW = landWidth <= 0 ? 1 : landWidth;
    final double safeL = landLength <= 0 ? 1 : landLength;

    final double meterDx = delta.dx / plotRect.width * safeW;
    final double meterDy = delta.dy / plotRect.height * safeL;

    final RoomModel oldRoom = _rooms[index];

    final double newX = (oldRoom.x + meterDx)
        .clamp(0.0, math.max(0.0, safeW - oldRoom.width))
        .toDouble();

    final double newY = (oldRoom.y + meterDy)
        .clamp(0.0, math.max(0.0, safeL - oldRoom.height))
        .toDouble();

    setState(() {
      _rooms[index] = RoomModel(
        nama: oldRoom.nama,
        category: oldRoom.category,
        x: newX,
        y: newY,
        width: oldRoom.width,
        height: oldRoom.height,
      );
    });
  }
}

class _EditSelectionPainter extends CustomPainter {
  final List<RoomModel> rooms;
  final int? selectedIndex;
  final double landWidth;
  final double landLength;

  _EditSelectionPainter({
    required this.rooms,
    required this.selectedIndex,
    required this.landWidth,
    required this.landLength,
  });

  static const Color orange = Color(0xFFE47B3E);

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedIndex == null) return;
    if (selectedIndex! < 0 || selectedIndex! >= rooms.length) return;

    final Rect plotRect = _calcPlotRect(size);
    final RoomModel room = rooms[selectedIndex!];

    final double safeW = landWidth <= 0 ? 1 : landWidth;
    final double safeL = landLength <= 0 ? 1 : landLength;

    final double scaleX = plotRect.width / safeW;
    final double scaleY = plotRect.height / safeL;

    final Rect roomRect = Rect.fromLTWH(
      plotRect.left + (room.x * scaleX),
      plotRect.top + (room.y * scaleY),
      room.width * scaleX,
      room.height * scaleY,
    );

    final RRect selectedRRect = RRect.fromRectAndRadius(
      roomRect.inflate(4),
      const Radius.circular(8),
    );

    canvas.drawRRect(
      selectedRRect,
      Paint()
        ..color = orange.withOpacity(0.12)
        ..style = PaintingStyle.fill,
    );

    canvas.drawRRect(
      selectedRRect,
      Paint()
        ..color = orange
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke,
    );
  }

  Rect _calcPlotRect(Size size) {
    final Rect boardRect = Rect.fromLTWH(
      18,
      18,
      size.width - 36,
      size.height - 36,
    );

    const double leftPad = 58;
    const double rightPad = 52;
    const double topPad = 54;
    const double bottomPad = 54;

    final double availableWidth = boardRect.width - leftPad - rightPad;
    final double availableHeight = boardRect.height - topPad - bottomPad;

    final double safeW = landWidth <= 0 ? 1 : landWidth;
    final double safeL = landLength <= 0 ? 1 : landLength;

    final double scale = math.min(
      availableWidth / safeW,
      availableHeight / safeL,
    );

    final double plotWidth = safeW * scale;
    final double plotHeight = safeL * scale;

    final double left =
        boardRect.left + leftPad + ((availableWidth - plotWidth) / 2);

    final double top =
        boardRect.top + topPad + ((availableHeight - plotHeight) / 2);

    return Rect.fromLTWH(left, top, plotWidth, plotHeight);
  }

  @override
  bool shouldRepaint(covariant _EditSelectionPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.rooms != rooms ||
        oldDelegate.landWidth != landWidth ||
        oldDelegate.landLength != landLength;
  }
}




