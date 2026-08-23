import 'package:flutter/material.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';

class LoadingSpinner extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingSpinner({
    super.key,
    this.size = 36,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppTheme.orange500,
          ),
        ),
      ),
    );
  }
}
