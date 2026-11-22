import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 44 × 44 round icon button. Disabled when [onPressed] is null.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.background = AppColors.surfaceMuted,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 22),
      style: IconButton.styleFrom(
        fixedSize: const Size(44, 44),
        backgroundColor: background,
        foregroundColor: AppColors.ink,
        disabledBackgroundColor: background,
        disabledForegroundColor: AppColors.disabled,
      ),
    );
  }
}
