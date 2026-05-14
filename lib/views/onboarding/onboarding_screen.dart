import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  static const Color navy = Color(0xFF0D1B2A);
  static const Color orange = Color(0xFFE47B3E);
  static const Color softBg = Color(0xFFF6F8FB);
  static const Color textGrey = Color(0xFF7A8493);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 430,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20),
                          _buildContent(),
                          const SizedBox(height: 24),
                          _buildStartButton(),
                        ],
                      ),
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

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: navy.withOpacity(0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.architecture_rounded,
                color: Colors.white,
                size: 25,
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'SmartFloorPlan',
          style: TextStyle(
            color: navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Get.offNamed('/login'),
          style: TextButton.styleFrom(
            foregroundColor: textGrey,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text(
            'Lewati',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeroIllustration(),
        const SizedBox(height: 28),
        _buildFeatureBadge(),
        const SizedBox(height: 18),
        const Text(
          'SmartFloorPlan',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: navy,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Buat denah rumah 2D otomatis dari ukuran lahan, edit tata letak ruangan, dan hitung estimasi RAB dengan lebih cepat.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.55,
            color: textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        _buildMiniFeatures(),
      ],
    );
  }

  Widget _buildHeroIllustration() {
    return SizedBox(
      height: 255,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 20,
            child: Container(
              width: 205,
              height: 205,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: navy.withOpacity(0.05),
              ),
            ),
          ),

          Positioned(
            top: 36,
            child: Transform.rotate(
              angle: -0.07,
              child: Container(
                width: 270,
                height: 165,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: navy.withOpacity(0.22),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _BlueprintPainter(),
                ),
              ),
            ),
          ),

          Positioned(
            top: 18,
            right: 42,
            child: Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: navy.withOpacity(0.13),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'AI',
                  style: TextStyle(
                    color: orange,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 4,
            bottom: 22,
            child: _floatingInfoCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Generate',
              subtitle: 'Denah Otomatis',
            ),
          ),

          Positioned(
            right: 2,
            bottom: 14,
            child: _floatingInfoCard(
              icon: Icons.receipt_long_rounded,
              title: 'RAB',
              subtitle: 'Estimasi Biaya',
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.09),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: orange, size: 18),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: orange.withOpacity(0.13),
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.home_work_rounded,
            color: orange,
            size: 17,
          ),
          SizedBox(width: 7),
          Text(
            'AI Floor Plan Generator',
            style: TextStyle(
              color: orange,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFeatures() {
    return Row(
      children: [
        Expanded(
          child: _featureItem(
            icon: Icons.grid_view_rounded,
            label: 'Denah 2D',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _featureItem(
            icon: Icons.edit_location_alt_rounded,
            label: 'Edit Layout',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _featureItem(
            icon: Icons.calculate_rounded,
            label: 'Hitung RAB',
          ),
        ),
      ],
    );
  }

  Widget _featureItem({
    required IconData icon,
    required String label,
  }) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE7ECF2),
        ),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: navy,
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: navy,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: () => Get.offNamed('/login'),
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          elevation: 8,
          shadowColor: navy.withOpacity(0.28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mulai Sekarang',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 10),
            Icon(
              Icons.arrow_forward_rounded,
              color: orange,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _BlueprintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 18) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    for (double y = 0; y < size.height; y += 18) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final wallPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final thinPaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final orangeStrokePaint = Paint()
      ..color = OnboardingScreen.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    final orangeFillPaint = Paint()
      ..color = OnboardingScreen.orange.withOpacity(0.16)
      ..style = PaintingStyle.fill;

    final mainRect = Rect.fromLTWH(
      size.width * 0.12,
      size.height * 0.15,
      size.width * 0.76,
      size.height * 0.68,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        mainRect,
        const Radius.circular(5),
      ),
      wallPaint,
    );

    canvas.drawLine(
      Offset(mainRect.left + size.width * 0.30, mainRect.top),
      Offset(mainRect.left + size.width * 0.30, mainRect.bottom),
      wallPaint,
    );

    canvas.drawLine(
      Offset(mainRect.left + size.width * 0.30, mainRect.top + size.height * 0.34),
      Offset(mainRect.right, mainRect.top + size.height * 0.34),
      wallPaint,
    );

    canvas.drawLine(
      Offset(mainRect.left + size.width * 0.57, mainRect.top + size.height * 0.34),
      Offset(mainRect.left + size.width * 0.57, mainRect.bottom),
      wallPaint,
    );

    canvas.drawLine(
      Offset(mainRect.left, mainRect.top + size.height * 0.40),
      Offset(mainRect.left + size.width * 0.30, mainRect.top + size.height * 0.40),
      thinPaint,
    );

    canvas.drawLine(
      Offset(mainRect.left + size.width * 0.57, mainRect.top + size.height * 0.55),
      Offset(mainRect.right, mainRect.top + size.height * 0.55),
      thinPaint,
    );

    final highlightRect = Rect.fromLTWH(
      mainRect.left + size.width * 0.35,
      mainRect.top + size.height * 0.07,
      size.width * 0.34,
      size.height * 0.22,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        highlightRect,
        const Radius.circular(8),
      ),
      orangeFillPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        highlightRect,
        const Radius.circular(8),
      ),
      orangeStrokePaint,
    );

    final dotPaint = Paint()
      ..color = OnboardingScreen.orange
      ..style = PaintingStyle.fill;

    canvas.drawCircle(highlightRect.topLeft, 4, dotPaint);
    canvas.drawCircle(highlightRect.topRight, 4, dotPaint);
    canvas.drawCircle(highlightRect.bottomLeft, 4, dotPaint);
    canvas.drawCircle(highlightRect.bottomRight, 4, dotPaint);

    final doorPaint = Paint()
      ..color = Colors.white.withOpacity(0.68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawArc(
      Rect.fromLTWH(
        mainRect.left + 14,
        mainRect.bottom - 42,
        42,
        42,
      ),
      -1.57,
      1.57,
      false,
      doorPaint,
    );

    canvas.drawArc(
      Rect.fromLTWH(
        mainRect.right - 58,
        mainRect.top + 18,
        42,
        42,
      ),
      1.57,
      1.57,
      false,
      doorPaint,
    );

    final sparklePaint = Paint()
      ..color = OnboardingScreen.orange
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    _drawPlus(canvas, Offset(size.width * 0.84, size.height * 0.22), sparklePaint);
    _drawPlus(canvas, Offset(size.width * 0.20, size.height * 0.75), sparklePaint);
  }

  void _drawPlus(Canvas canvas, Offset center, Paint paint) {
    canvas.drawLine(
      Offset(center.dx - 7, center.dy),
      Offset(center.dx + 7, center.dy),
      paint,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy - 7),
      Offset(center.dx, center.dy + 7),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}