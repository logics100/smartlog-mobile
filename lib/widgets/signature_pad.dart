import 'package:flutter/material.dart';

class SignaturePad extends StatefulWidget {
  final GlobalKey signatureKey;

  const SignaturePad({super.key, required this.signatureKey});

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<Offset?> points = [];

  bool get hasSignature => points.whereType<Offset>().isNotEmpty;

  void clear() {
    setState(points.clear);
  }

  Offset? _safePoint(BuildContext context, Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;

    final point = box.globalToLocal(globalPosition);

    if (point.dx < 0 ||
        point.dy < 0 ||
        point.dx > box.size.width ||
        point.dy > box.size.height) {
      return null;
    }

    return point;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.signatureKey,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              final point = _safePoint(context, details.globalPosition);
              if (point != null) {
                setState(() => points.add(point));
              }
            },
            onPanUpdate: (details) {
              final point = _safePoint(context, details.globalPosition);

              setState(() {
                if (point != null) {
                  points.add(point);
                } else if (points.isNotEmpty && points.last != null) {
                  points.add(null);
                }
              });
            },
            onPanEnd: (_) {
              setState(() => points.add(null));
            },
            child: CustomPaint(
              painter: SignaturePainter(points: points),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

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
        canvas.drawLine(current, next, paint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) => true;
}
