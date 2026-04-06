import 'package:flutter/material.dart';

class InsightSkeleton extends StatefulWidget {
  const InsightSkeleton({super.key});

  @override
  State<InsightSkeleton> createState() => _InsightSkeletonState();
}

class _InsightSkeletonState extends State<InsightSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            _SkeletonBox(width: 180, height: 14, opacity: _animation.value * 0.3),
            const SizedBox(height: 8),
            _SkeletonBox(width: 80, height: 32, opacity: _animation.value * 0.4),
            const SizedBox(height: 8),
            _SkeletonBox(width: 220, height: 14, opacity: _animation.value * 0.3),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}