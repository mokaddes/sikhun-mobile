import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/theme.dart';

class SikhunMarkPainter extends CustomPainter {
  final Color strokeColor;

  const SikhunMarkPainter({this.strokeColor = const Color(0xFFFFFEFA)});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 200.0;
    canvas.save();
    canvas.scale(scale, scale);

    final ribbonPath = Path()
      ..moveTo(44, 104)
      ..cubicTo(30, 60, 70, 26, 120, 30)
      ..cubicTo(148, 32, 164, 44, 166, 58)
      ..cubicTo(168, 74, 166, 86, 160, 96)
      ..cubicTo(148, 78, 126, 68, 104, 68)
      ..cubicTo(82, 68, 64, 80, 56, 98)
      ..close();

    final ribbonGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4A3FD6), Color(0xFF7181E9), Color(0xFF58D6F2)],
      stops: [0.0, 0.48, 1.0],
    ).createShader(const Rect.fromLTWH(20, 20, 160, 160));

    final ribbonFill = Paint()
      ..shader = ribbonGradient
      ..style = PaintingStyle.fill;

    final ribbonStroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(ribbonPath, ribbonFill);
    canvas.drawPath(ribbonPath, ribbonStroke);

    canvas.save();
    canvas.translate(100, 100);
    canvas.rotate(math.pi);
    canvas.translate(-100, -100);
    canvas.drawPath(ribbonPath, ribbonFill);
    canvas.drawPath(ribbonPath, ribbonStroke);
    canvas.restore();

    final glowPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x66FF9D3C), Color(0x00FF9D3C)],
      ).createShader(Rect.fromCircle(center: const Offset(100, 106), radius: 30));
    canvas.drawCircle(const Offset(100, 106), 30, glowPaint);

    final flamePath = Path()
      ..moveTo(100, 82)
      ..cubicTo(107, 92, 117, 99, 117, 111)
      ..cubicTo(117, 121, 109, 127, 100, 127)
      ..cubicTo(91, 127, 83, 121, 83, 111)
      ..cubicTo(83, 99, 93, 92, 100, 82)
      ..close();

    final flamePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFF8A1F), Color(0xFFFFD25A)],
      ).createShader(const Rect.fromLTWH(83, 82, 34, 45));
    canvas.drawPath(flamePath, flamePaint);

    final innerFlamePath = Path()
      ..moveTo(100, 100)
      ..cubicTo(104, 106, 110, 109, 110, 115)
      ..cubicTo(110, 121, 105, 124, 100, 124)
      ..cubicTo(95, 124, 90, 121, 90, 115)
      ..cubicTo(90, 109, 96, 106, 100, 100)
      ..close();

    final innerFlamePaint = Paint()
      ..color = const Color(0xD9FFE28A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(innerFlamePath, innerFlamePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SikhunMarkPainter oldDelegate) =>
      oldDelegate.strokeColor != strokeColor;
}

class SikhunMark extends StatelessWidget {
  final double size;

  const SikhunMark({super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: SikhunMarkPainter(
          strokeColor: isDark ? SikhunTheme.darkSurface : const Color(0xFFFFFEFA),
        ),
      ),
    );
  }
}

class SikhunBrandLogo extends StatelessWidget {
  final bool compact;
  final bool showTagline;
  final bool isBangla;
  final double markSize;
  final String? customTitle;
  final String? customTagline;

  const SikhunBrandLogo({
    super.key,
    this.compact = false,
    this.showTagline = true,
    this.isBangla = true,
    this.markSize = 36,
    this.customTitle,
    this.customTagline,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final taglineColor = isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C);
    final brandName = customTitle?.isNotEmpty == true
        ? customTitle!
        : (isBangla ? 'শিখুন' : 'SIKHUN');
    final tagline = customTagline?.isNotEmpty == true
        ? customTagline!
        : (isBangla ? 'আপনার এআই পড়ার টেবিল' : 'YOUR AI STUDY DESK');

    if (compact) {
      return SikhunMark(size: markSize);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SikhunMark(size: markSize),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isBangla)
              Text(
                brandName,
                style: TextStyle(
                  fontSize: markSize * 0.56,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1.05,
                ),
              )
            else
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: markSize * 0.48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: textColor,
                    height: 1.05,
                  ),
                  children: [
                    TextSpan(text: brandName.replaceAll(RegExp(r'\.com.*$', caseSensitive: false), '').toUpperCase()),
                    TextSpan(
                      text: '.COM',
                      style: TextStyle(
                        color: isDark ? SikhunTheme.darkPrimary : SikhunTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            if (showTagline) ...[
              const SizedBox(height: 2),
              Text(
                '— ◆ $tagline',
                style: TextStyle(
                  fontSize: markSize * 0.25,
                  fontWeight: FontWeight.w700,
                  color: taglineColor,
                  letterSpacing: isBangla ? 0.2 : 1.0,
                  height: 1.1,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
