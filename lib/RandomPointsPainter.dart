// ignore_for_file: file_names, use_key_in_widget_constructors, library_private_types_in_public_api
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class RandomPointsPainter extends StatefulWidget {
  final Color color; // Добавляем параметр color

  const RandomPointsPainter({required this.color});

  @override
  _RandomPointsPainterState createState() => _RandomPointsPainterState();
}

class _RandomPointsPainterState extends State<RandomPointsPainter> {
  final _random = Random();
  List<Offset>? _points;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RandomPointsPainter(
          _points, widget.color), // Передаем параметр color
      size: MediaQuery.of(context).size,
    );
  }

  List<Offset> _generatePoints(Size size) {
    final points = <Offset>[];
    for (int i = 0; i < 500; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      points.add(Offset(x, y));
    }
    return points;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _points = _generatePoints(MediaQuery.of(context).size);
      });
    });
  }
}

class _RandomPointsPainter extends CustomPainter {
  final List<Offset>? _points;
  final Color color; // Добавляем параметр color

  _RandomPointsPainter(this._points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (_points == null) return;

    final paint = Paint()
      ..color = color // Используем переданный цвет
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = const Color.fromARGB(255, 102, 102, 102).withOpacity(0.5);

    for (final point in _points!) {
      canvas.drawCircle(point, 3.05, shadowPaint);
      canvas.drawPoints(PointMode.points, [point], paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
