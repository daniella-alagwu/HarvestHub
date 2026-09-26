import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, this.dotColor = Colors.black54, this.dotSize = 7});

  final Color dotColor;
  final double dotSize;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.dotSize * 5,
      height: widget.dotSize * 2.2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              // Each dot's bounce is offset by 1/3 of the cycle, so they
              // rise in a left-to-right wave instead of moving in unison.
              final t = (_controller.value - (i * 0.18)) % 1.0;
              final bounce = Curves.easeInOut.transform(
                t < 0.5 ? t * 2 : (1 - t) * 2,
              );
              return Transform.translate(
                offset: Offset(0, -bounce * widget.dotSize * 0.8),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: widget.dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}