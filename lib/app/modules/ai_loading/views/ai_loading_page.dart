import 'package:flutter/material.dart';

class AILoadingPage extends StatelessWidget {

  const AILoadingPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          const Color(0xFF0D1B2A),

      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 80,
              ),

              const SizedBox(height: 32),

              const CircularProgressIndicator(
                color: Colors.white,
              ),

              const SizedBox(height: 32),

              const Text(
                "AI Sedang Membuat Denah Rumah...",

                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Mohon tunggu beberapa saat",

                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}