import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A custom widget rendering the exact TAILOR CONNECT logo with hanger & suit motif,
/// custom stitched line details, typography, divider, and tagline.
class TailorConnectLogo extends StatelessWidget {
  final double scale;

  const TailorConnectLogo({
    super.key,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    const brandNavy = Color(0xFF132238);
    const brandGold = Color(0xFFC78828);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Hanger & Suit Custom Icon Graphic
        SizedBox(
          width: 130 * scale,
          height: 110 * scale,
          child: CustomPaint(
            painter: HangerJacketPainter(),
          ),
        ),
        const SizedBox(height: 16),

        // Brand Title "TAILOR"
        Text(
          'TAILOR',
          style: GoogleFonts.montserrat(
            fontSize: 32 * scale,
            fontWeight: FontWeight.w800,
            letterSpacing: 7.0,
            color: brandNavy,
            height: 1.1,
          ),
        ),

        const SizedBox(height: 2),

        // Brand Subtitle "CONNECT"
        Text(
          'CONNECT',
          style: GoogleFonts.montserrat(
            fontSize: 22 * scale,
            fontWeight: FontWeight.w500,
            letterSpacing: 10.5,
            color: brandGold,
            height: 1.1,
          ),
        ),

        const SizedBox(height: 14),

        // Thin Divider Line
        Container(
          width: 175 * scale,
          height: 1.0,
          color: const Color(0xFFDCDFE5),
        ),

        const SizedBox(height: 10),

        // Tagline
        Text(
          'Find. Book. Get Measured.',
          style: GoogleFonts.inter(
            fontSize: 13 * scale,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF758195),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

/// CustomPainter to draw the hanger hook + yellow stitched left jacket + dark navy right jacket
class HangerJacketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Paints
    final navyPaint = Paint()
      ..color = const Color(0xFF132238)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final navyStrokePaint = Paint()
      ..color = const Color(0xFF132238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final goldStrokePaint = Paint()
      ..color = const Color(0xFFD49228)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final goldDashedPaint = Paint()
      ..color = const Color(0xFFDA952B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Center coordinates
    final double cx = w / 2;

    // 1. Draw Hanger Hook at top (Center top)
    final Path hookPath = Path();
    hookPath.moveTo(cx + 2, h * 0.16);
    hookPath.cubicTo(
      cx + 2, h * 0.05,
      cx - 14, h * 0.03,
      cx - 10, h * 0.12,
    );
    canvas.drawPath(hookPath, navyStrokePaint);

    // 2. Draw Hanger Neck Joint / Neck Bar
    final Path neckPath = Path();
    neckPath.moveTo(cx - 12, h * 0.22);
    neckPath.lineTo(cx, h * 0.16);
    neckPath.lineTo(cx + 12, h * 0.22);
    canvas.drawPath(neckPath, navyStrokePaint);

    // 3. Draw Right Jacket (Solid Navy Silhouette)
    final Path rightJacket = Path();
    // Shoulder start
    rightJacket.moveTo(cx + 2, h * 0.17);
    rightJacket.lineTo(cx + 38, h * 0.32); // shoulder right
    rightJacket.lineTo(cx + 45, h * 0.44); // outer arm
    rightJacket.lineTo(cx + 42, h * 0.88); // bottom right corner
    rightJacket.lineTo(cx + 22, h * 0.88); // bottom waist right
    rightJacket.lineTo(cx + 25, h * 0.65); // inner waist indent
    rightJacket.lineTo(cx + 4, h * 0.50);  // lapel notch right
    rightJacket.lineTo(cx + 12, h * 0.36); // upper collar notch right
    rightJacket.lineTo(cx + 2, h * 0.30);  // center chest
    rightJacket.close();
    canvas.drawPath(rightJacket, navyPaint);

    // Collar / Lapel fold highlight on right suit
    final Path rightLapelFold = Path();
    rightLapelFold.moveTo(cx + 2, h * 0.25);
    rightLapelFold.lineTo(cx + 16, h * 0.35);
    rightLapelFold.lineTo(cx + 6, h * 0.52);
    canvas.drawPath(
      rightLapelFold,
      Paint()
        ..color = const Color(0xFF1F3554)
        ..style = PaintingStyle.fill,
    );

    // 4. Draw Left Jacket (Yellow / Gold Tailor Stitch Lines)
    // Shoulder diagonal outline
    _drawDashedLine(
      canvas,
      Offset(cx - 2, h * 0.17),
      Offset(cx - 38, h * 0.32),
      goldDashedPaint,
      dashWidth: 4,
      dashSpace: 3,
    );

    // Outer arm line
    _drawDashedLine(
      canvas,
      Offset(cx - 38, h * 0.32),
      Offset(cx - 45, h * 0.44),
      goldDashedPaint,
      dashWidth: 4,
      dashSpace: 3,
    );

    // Vertical seam / arm side
    _drawDashedLine(
      canvas,
      Offset(cx - 45, h * 0.44),
      Offset(cx - 40, h * 0.88),
      goldDashedPaint,
      dashWidth: 5,
      dashSpace: 4,
    );

    // Bottom hem left line
    _drawDashedLine(
      canvas,
      Offset(cx - 40, h * 0.88),
      Offset(cx - 18, h * 0.88),
      goldDashedPaint,
      dashWidth: 4,
      dashSpace: 3,
    );

    // Inner tailoring lapel lines (Left side)
    final Path leftLapel = Path();
    leftLapel.moveTo(cx - 2, h * 0.25);
    leftLapel.lineTo(cx - 16, h * 0.35);
    leftLapel.lineTo(cx - 6, h * 0.52);
    leftLapel.lineTo(cx - 22, h * 0.65);
    leftLapel.lineTo(cx - 18, h * 0.88);
    canvas.drawPath(leftLapel, goldStrokePaint);

    // Additional dashed measurement line down the left breast
    _drawDashedLine(
      canvas,
      Offset(cx - 24, h * 0.36),
      Offset(cx - 28, h * 0.78),
      goldDashedPaint,
      dashWidth: 3,
      dashSpace: 3,
    );
  }

  /// Helper to draw dashed line segments between two points
  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint, {
    required double dashWidth,
    required double dashSpace,
  }) {
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double len = (dx * dx + dy * dy) > 0 ? (p2 - p1).distance : 0;
    if (len == 0) return;

    final double unitX = dx / len;
    final double unitY = dy / len;

    double drawn = 0.0;
    while (drawn < len) {
      final double currentDash = (drawn + dashWidth > len) ? (len - drawn) : dashWidth;
      canvas.drawLine(
        Offset(p1.dx + unitX * drawn, p1.dy + unitY * drawn),
        Offset(p1.dx + unitX * (drawn + currentDash), p1.dy + unitY * (drawn + currentDash)),
        paint,
      );
      drawn += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
