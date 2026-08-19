import 'package:flutter/material.dart';

/// Kayıt / Giriş ekranları için ortak, profesyonel, siyah-beyaz (monokrom)
/// görünümlü arka plan. Ana degrade üzerine yumuşak, bulanık dekoratif
/// daireler ekler.
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A0A), Color(0xFF2B2B2B)],
        ),
      ),
      child: Stack(
        children: [
          // Sol üst dekoratif daire
          Positioned(
            top: -80,
            left: -60,
            child: _blurCircle(220, Colors.white.withOpacity(0.10)),
          ),
          // Sağ üst dekoratif daire
          Positioned(
            top: -40,
            right: -70,
            child: _blurCircle(180, Colors.white.withOpacity(0.06)),
          ),
          // Sağ alt dekoratif daire
          Positioned(
            bottom: -100,
            right: -80,
            child: _blurCircle(260, Colors.white.withOpacity(0.08)),
          ),
          // İçerik
          child,
        ],
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
        ),
      ),
    );
  }
}
