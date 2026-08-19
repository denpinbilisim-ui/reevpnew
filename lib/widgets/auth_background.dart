import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Kayıt / Giriş ekranları için ortak, profesyonel görünümlü arka plan.
/// Ana degrade üzerine yumuşak, bulanık dekoratif daireler ekler
/// (web sürümündeki radial-gradient efektine benzer).
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.backgroundDecoration,
      child: Stack(
        children: [
          // Sol üst dekoratif daire
          Positioned(
            top: -80,
            left: -60,
            child: _blurCircle(220, AppTheme.primaryColor.withOpacity(0.18)),
          ),
          // Sağ üst dekoratif daire
          Positioned(
            top: -40,
            right: -70,
            child: _blurCircle(180, Colors.white.withOpacity(0.12)),
          ),
          // Sağ alt dekoratif daire
          Positioned(
            bottom: -100,
            right: -80,
            child: _blurCircle(260, AppTheme.secondaryColor.withOpacity(0.16)),
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
