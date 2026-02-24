import 'package:flutter/material.dart';

class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const Shimmer({
    required this.child,
    this.duration = const Duration(milliseconds: 1100),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary: performans için
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (Rect bounds) {
              final w = bounds.width;

              // -1..+1 arası kaydırma
              final t = (_c.value * 2) - 1;
              final dx = t * w;

              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.03),
                  Colors.black.withOpacity(0.10),
                  Colors.black.withOpacity(0.03),
                ],
                stops: const [0.0, 0.5, 1.0],
                transform: _SlidingGradientTransform(dx),
              ).createShader(bounds);
            },
            child: widget.child,
          );
        },
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slideX;
  const _SlidingGradientTransform(this.slideX);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(slideX, 0.0, 0.0);
  }
}