import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:smart_floor_plan/app/data/models/room_model.dart';

class FloorPlanAssetOverlay extends StatelessWidget {
  final List<RoomModel> rooms;
  final double landWidth;
  final double landLength;

  const FloorPlanAssetOverlay({
    super.key,
    required this.rooms,
    required this.landWidth,
    required this.landLength,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final plotRect = _calcPlotRect(size);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final room in rooms)
              ..._buildAssetsForRoom(
                room: room,
                roomRect: _roomRect(room: room, plotRect: plotRect),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _buildAssetsForRoom({
    required RoomModel room,
    required Rect roomRect,
  }) {
    final name = room.nama.toLowerCase();

    if (roomRect.width < 20 || roomRect.height < 20) {
      return [];
    }

    if (name.contains('carport')) {
      return _carportAssets(roomRect);
    }

    if (name.contains('taman') || name.contains('inner court')) {
      return _gardenAssets(roomRect);
    }

    // Asset indoor dimatikan dulu supaya denah tidak terlihat tempelan dan berantakan.
    return [];
  }

  List<Widget> _carportAssets(Rect roomRect) {
    return [
      _assetWidget(
        asset: 'assets/images/car.jpg',
        fallbackAsset: 'assets/images/car.png',
        rect: Rect.fromCenter(
          center: roomRect.center,
          width: roomRect.width * 0.42,
          height: roomRect.height * 0.56,
        ),
      ),
    ];
  }

  List<Widget> _gardenAssets(Rect roomRect) {
    final widgets = <Widget>[];

    final treeSize = math.min(
      roomRect.width * 0.10,
      roomRect.height * 0.16,
    ).clamp(9.0, 16.0);

    final plantSize = math.min(
      roomRect.width * 0.08,
      roomRect.height * 0.12,
    ).clamp(7.0, 12.0);

    widgets.add(
      _assetWidget(
        asset: 'assets/images/tree.jpeg',
        fallbackAsset: 'assets/images/tree.png',
        rect: Rect.fromCenter(
          center: Offset(
            roomRect.left + roomRect.width * 0.18,
            roomRect.top + roomRect.height * 0.25,
          ),
          width: treeSize,
          height: treeSize,
        ),
      ),
    );

    if (roomRect.width > 70) {
      widgets.add(
        _assetWidget(
          asset: 'assets/images/tree.jpeg',
          fallbackAsset: 'assets/images/tree.png',
          rect: Rect.fromCenter(
            center: Offset(
              roomRect.left + roomRect.width * 0.78,
              roomRect.top + roomRect.height * 0.65,
            ),
            width: treeSize,
            height: treeSize,
          ),
        ),
      );
    }

    widgets.add(
      _assetWidget(
        asset: 'assets/images/plant.webp',
        fallbackAsset: 'assets/images/plant.png',
        rect: Rect.fromCenter(
          center: Offset(
            roomRect.left + roomRect.width * 0.55,
            roomRect.top + roomRect.height * 0.30,
          ),
          width: plantSize,
          height: plantSize,
        ),
      ),
    );

    return widgets;
  }

  Widget _assetWidget({
    required String asset,
    String? fallbackAsset,
    required Rect rect,
  }) {
    if (rect.width <= 0 || rect.height <= 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: IgnorePointer(
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            if (fallbackAsset == null) {
              return const SizedBox.shrink();
            }

            return Image.asset(
              fallbackAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }

  Rect _calcPlotRect(Size size) {
    final boardRect = Rect.fromLTWH(
      18,
      18,
      size.width - 36,
      size.height - 36,
    );

    const leftPad = 58.0;
    const rightPad = 52.0;
    const topPad = 54.0;
    const bottomPad = 54.0;

    final safeW = landWidth <= 0 ? 1 : landWidth;
    final safeL = landLength <= 0 ? 1 : landLength;

    final availableWidth = boardRect.width - leftPad - rightPad;
    final availableHeight = boardRect.height - topPad - bottomPad;

    final scale = math.min(
      availableWidth / safeW,
      availableHeight / safeL,
    );

    final plotWidth = safeW * scale;
    final plotHeight = safeL * scale;

    final left = boardRect.left + leftPad + ((availableWidth - plotWidth) / 2);
    final top = boardRect.top + topPad + ((availableHeight - plotHeight) / 2);

    return Rect.fromLTWH(left, top, plotWidth, plotHeight);
  }

  Rect _roomRect({
    required RoomModel room,
    required Rect plotRect,
  }) {
    final safeW = landWidth <= 0 ? 1 : landWidth;
    final safeL = landLength <= 0 ? 1 : landLength;

    final scaleX = plotRect.width / safeW;
    final scaleY = plotRect.height / safeL;

    return Rect.fromLTWH(
      plotRect.left + (room.x * scaleX),
      plotRect.top + (room.y * scaleY),
      room.width * scaleX,
      room.height * scaleY,
    );
  }
}