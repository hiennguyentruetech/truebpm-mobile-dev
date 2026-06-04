import 'package:flutter/material.dart';
import 'package:truebpm/screens/predictions_screens/body/predictions_ui_helpers.dart';

class PredictionStakeAmount extends StatelessWidget {
  const PredictionStakeAmount({
    super.key,
    required this.value,
    this.signed = false,
    this.color,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w900,
    this.iconSize = 15,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.textAlign = TextAlign.center,
  });

  final dynamic value;
  final bool signed;
  final Color? color;
  final double fontSize;
  final FontWeight fontWeight;
  final double iconSize;
  final MainAxisAlignment mainAxisAlignment;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color ??
        DefaultTextStyle.of(context).style.color ??
        const Color(0xFF243447);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          Text(
            predictionShortMoney(value, signed: signed),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: TextStyle(
              color: resolvedColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
          SizedBox(width: iconSize * 0.22),
          GoldfishStakeIcon(size: iconSize),
        ],
      ),
    );
  }
}

class GoldfishStakeIcon extends StatelessWidget {
  const GoldfishStakeIcon({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoldfishPainter()),
    );
  }
}

class _GoldfishPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFC83D), Color(0xFFFF8E24)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    final finPaint = Paint()..color = const Color(0xFFFFA11E);
    final strokePaint = Paint()
      ..color = const Color(0xFFD66A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.07).clamp(0.8, 1.4)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final tail = Path()
      ..moveTo(w * 0.18, h * 0.50)
      ..lineTo(w * 0.02, h * 0.22)
      ..quadraticBezierTo(w * 0.24, h * 0.28, w * 0.31, h * 0.43)
      ..quadraticBezierTo(w * 0.24, h * 0.60, w * 0.02, h * 0.78)
      ..close();
    canvas.drawPath(tail, finPaint);
    canvas.drawPath(tail, strokePaint);

    final body = Path()
      ..moveTo(w * 0.22, h * 0.50)
      ..cubicTo(w * 0.36, h * 0.18, w * 0.74, h * 0.16, w * 0.94, h * 0.50)
      ..cubicTo(w * 0.74, h * 0.84, w * 0.36, h * 0.82, w * 0.22, h * 0.50)
      ..close();
    canvas.drawPath(body, bodyPaint);
    canvas.drawPath(body, strokePaint);

    final topFin = Path()
      ..moveTo(w * 0.43, h * 0.27)
      ..quadraticBezierTo(w * 0.54, h * 0.03, w * 0.66, h * 0.27)
      ..close();
    canvas.drawPath(topFin, finPaint);

    canvas.drawCircle(
      Offset(w * 0.73, h * 0.42),
      w * 0.055,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(w * 0.75, h * 0.43),
      w * 0.028,
      Paint()..color = const Color(0xFF4A2A00),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
