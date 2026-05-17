import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:smart_floor_plan/app/routes/app_routes.dart';

class CinematicSplashScreen extends StatelessWidget {
  const CinematicSplashScreen({super.key});

  static const Color navy = Color(0xFF0D1B2A);
  static const Color darkNavy = Color(0xFF08111F);
  static const Color orange = Color(0xFFE47B3E);
  static const Color softWhite = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          final bool isSmallPhone = width < 380;
          final bool isTablet = width > 700;

          final double maxWidth = isTablet ? 520 : double.infinity;
          final double horizontalPadding = isSmallPhone ? 20 : 28;
          final double logoSize = isSmallPhone ? 92 : 112;
          final double titleSize = isSmallPhone ? 31 : 38;
          final double subtitleSize = isSmallPhone ? 15.5 : 18;
          final double descSize = isSmallPhone ? 13 : 15;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  darkNavy,
                  navy,
                  Color(0xFF102A43),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    minHeight: height,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isSmallPhone ? 20 : 26,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom -
                            52,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 10),

                          Column(
                            children: [
                              Container(
                                width: logoSize,
                                height: logoSize,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(34),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.16),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.22),
                                      blurRadius: 28,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.architecture_rounded,
                                  color: Colors.white,
                                  size: isSmallPhone ? 48 : 58,
                                ),
                              ),

                              SizedBox(height: isSmallPhone ? 24 : 30),

                              Text(
                                'SmartFloorPlan',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w900,
                                  height: 1.08,
                                  letterSpacing: -0.7,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                'AI Smart House Planner',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: orange,
                                  fontSize: subtitleSize,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),

                              SizedBox(height: isSmallPhone ? 16 : 20),

                              Text(
                                'Buat rancangan denah rumah lebih cepat dengan fitur generate layout, edit ruangan, estimasi biaya, dan scan sketsa.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: descSize,
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(isSmallPhone ? 14 : 18),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _buildFeatureIcon(
                                      icon: Icons.auto_awesome_rounded,
                                      isSmallPhone: isSmallPhone,
                                    ),
                                    SizedBox(width: isSmallPhone ? 9 : 12),
                                    _buildFeatureIcon(
                                      icon: Icons.edit_location_alt_rounded,
                                      isSmallPhone: isSmallPhone,
                                    ),
                                    SizedBox(width: isSmallPhone ? 9 : 12),
                                    _buildFeatureIcon(
                                      icon: Icons.document_scanner_rounded,
                                      isSmallPhone: isSmallPhone,
                                    ),
                                    SizedBox(width: isSmallPhone ? 9 : 12),
                                    Expanded(
                                      child: Text(
                                        'Generate • Edit • RAB • Scan Sketsa',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSmallPhone ? 12 : 14,
                                          fontWeight: FontWeight.w700,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: isSmallPhone ? 18 : 24),

                              SizedBox(
                                width: double.infinity,
                                height: isSmallPhone ? 52 : 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Get.offNamed(AppRoutes.onboarding);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: orange,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontSize: isSmallPhone ? 15 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'SmartFloorPlan Capstone Project',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: softWhite.withOpacity(0.55),
                                  fontSize: isSmallPhone ? 11.5 : 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureIcon({
    required IconData icon,
    required bool isSmallPhone,
  }) {
    return Container(
      width: isSmallPhone ? 34 : 38,
      height: isSmallPhone ? 34 : 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: isSmallPhone ? 19 : 21,
      ),
    );
  }
}