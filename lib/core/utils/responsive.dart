import 'package:flutter/material.dart';

/// Breakpoints for responsive layouts.
class AppBreakpoints {
  AppBreakpoints._();

  /// Phone (portrait) — default mobile layout
  static const double phone = 480;

  /// Tablet (portrait) — content constrained, larger padding
  static const double tablet = 768;

  /// Desktop — sidebar layout possible, max-width content
  static const double desktop = 1024;

  /// Maximum content width for any screen.
  static const double maxContentWidth = 600;
}

/// A widget that constrains its child to [AppBreakpoints.maxContentWidth]
/// and centers it on wider screens.
class ResponsiveConstrained extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  const ResponsiveConstrained({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Returns the number of grid columns based on available width.
int responsiveGridColumns(double width, {double minItemWidth = 160}) {
  if (width < AppBreakpoints.phone) return 2;
  if (width < AppBreakpoints.tablet) return 3;
  return 4;
}

/// Returns true if the screen is at least [breakpoint] wide.
bool isAtLeast(BuildContext context, double breakpoint) {
  return MediaQuery.sizeOf(context).width >= breakpoint;
}
