import 'package:flutter/material.dart';

class TaskFlowIcon extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? accentColor;

  const TaskFlowIcon({
    super.key,
    this.size = 60,
    this.primaryColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? const Color(0xFF4A4EE8);
    final accent = accentColor ?? const Color(0xFFF5A623);
    
    return CustomPaint(
      size: Size(size, size),
      painter: TaskFlowIconPainter(
        primaryColor: primary,
        accentColor: accent,
      ),
    );
  }
}

class TaskFlowIconPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  TaskFlowIconPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.48; // Aumentado de 0.45 para 0.48

    // Fundo branco com borda
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paint);

    // Borda cinza mais fina
    paint.color = Colors.grey.shade400;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = size.width * 0.03; // Reduzido de 0.05 para 0.03
    canvas.drawCircle(center, radius, paint);

    // Configurações para os elementos
    final itemHeight = size.height * 0.14; // Aumentado de 0.12 para 0.14
    final itemWidth = size.width * 0.65; // Aumentado de 0.6 para 0.65
    final startY = size.height * 0.22; // Reduzido de 0.25 para 0.22
    final itemSpacing = size.height * 0.16; // Aumentado de 0.15 para 0.16

    // Primeiro item (completo - com check laranja)
    _drawTaskItem(
      canvas,
      size,
      Offset(size.width * 0.175, startY), // Mais centralizado: 0.175 em vez de 0.2
      itemWidth,
      itemHeight,
      isCompleted: true,
    );

    // Segundo item (incompleto)
    _drawTaskItem(
      canvas,
      size,
      Offset(size.width * 0.175, startY + itemSpacing), // Mais centralizado
      itemWidth,
      itemHeight,
      isCompleted: false,
    );

    // Terceiro item (incompleto)
    _drawTaskItem(
      canvas,
      size,
      Offset(size.width * 0.2, startY + itemSpacing * 2),
      itemWidth,
      itemHeight,
      isCompleted: false,
    );
  }

  void _drawTaskItem(
    Canvas canvas,
    Size size,
    Offset position,
    double width,
    double height,
    {required bool isCompleted}
  ) {
    final paint = Paint();
    final checkboxSize = height * 0.8;
    
    // Checkbox
    final checkboxRect = Rect.fromLTWH(
      position.dx,
      position.dy,
      checkboxSize,
      checkboxSize,
    );

    if (isCompleted) {
      // Checkbox preenchido com check laranja
      paint.color = accentColor;
      paint.style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(checkboxRect, Radius.circular(checkboxSize * 0.15)),
        paint,
      );

      // Check mark branco
      paint.color = Colors.white;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = checkboxSize * 0.15;
      paint.strokeCap = StrokeCap.round;

      final checkPath = Path();
      checkPath.moveTo(
        checkboxRect.left + checkboxSize * 0.25,
        checkboxRect.top + checkboxSize * 0.5,
      );
      checkPath.lineTo(
        checkboxRect.left + checkboxSize * 0.45,
        checkboxRect.top + checkboxSize * 0.7,
      );
      checkPath.lineTo(
        checkboxRect.left + checkboxSize * 0.75,
        checkboxRect.top + checkboxSize * 0.3,
      );
      canvas.drawPath(checkPath, paint);
    } else {
      // Checkbox vazio
      paint.color = primaryColor;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = checkboxSize * 0.1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(checkboxRect, Radius.circular(checkboxSize * 0.15)),
        paint,
      );
    }

    // Linha da tarefa
    final lineY = position.dy + height * 0.4;
    final lineStartX = position.dx + checkboxSize + height * 0.3;
    final lineEndX = position.dx + width;

    paint.color = primaryColor;
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        lineStartX,
        lineY,
        lineEndX,
        lineY + height * 0.2,
        topLeft: Radius.circular(height * 0.1),
        topRight: Radius.circular(height * 0.1),
        bottomLeft: Radius.circular(height * 0.1),
        bottomRight: Radius.circular(height * 0.1),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}