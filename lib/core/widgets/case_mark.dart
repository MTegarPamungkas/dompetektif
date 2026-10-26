import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class CaseMark extends StatelessWidget {
  const CaseMark({super.key, this.size = 44, this.showShadow = true});

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3D27E), Color(0xFFD3A131), Color(0xFF9A6B0D)],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: const Color(0xFFE8B84B).withValues(alpha: 0.3),
                  blurRadius: size * 0.7,
                  offset: Offset(0, size * 0.18),
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            color: const Color(0xFF1B1403),
            size: size * 0.48,
          ),
          Positioned(
            right: size * 0.12,
            bottom: size * 0.11,
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: BoxDecoration(
                color: const Color(0xFF1B1403),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFF3D27E),
                  width: size * 0.03,
                ),
              ),
              child: Icon(
                Icons.search_rounded,
                color: const Color(0xFFF3D27E),
                size: size * 0.23,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CaseBackground extends StatelessWidget {
  const CaseBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.dompet;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.8, -1.1),
          radius: 1.35,
          colors: [
            colors.accent.withValues(alpha: 0.055),
            colors.background,
            colors.background,
          ],
          stops: const [0, 0.52, 1],
        ),
      ),
      child: CustomPaint(
        painter: _GridPainter(color: colors.line.withValues(alpha: 0.16)),
        child: child,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.75;
    const step = 46.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
