import 'package:flutter/material.dart';

class GradientContainer extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final List<BoxShadow>? boxShadow;

  const GradientContainer({
    super.key,
    required this.child,
    this.colors = const [],
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(20),
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: colors.length >= 2
            ? LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}
