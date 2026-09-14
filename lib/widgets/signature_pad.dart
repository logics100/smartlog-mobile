import 'package:flutter/material.dart';

class SignaturePad extends StatefulWidget {
  final GlobalKey signatureKey;

  const SignaturePad({
    super.key,
    required this.signatureKey,
  });

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<Offset?> points = [];

  bool get hasSignature {
    return points.whereType<Offset>().isNotEmpty;
  }

  void clear() {
    setState(() {
      points.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.signatureKey,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,

          onPanStart: (details) {
            final box =
                context.findRenderObject() as RenderBox;

            setState(() {
              points.add(
                box.globalToLocal(
                  details.globalPosition,
                ),
              );
            });
          },

          onPanUpdate: (details) {
            final box =
                context.findRenderObject() as RenderBox;

            setState(() {
              points.add(
                box.globalToLocal(
                  details.globalPosition,
                ),
              );
            });
          },

          onPanEnd: (_) {
            setState(() {
              points.add(null);
            });
          },

          child: CustomPaint(
            painter: SignaturePainter(
              points: points,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter({
    required this.points,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..color = Colors.black;

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      if (current != null && next != null) {
        canvas.drawLine(
          current,
          next,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant SignaturePainter oldDelegate,
  ) {
    return true;
  }
}