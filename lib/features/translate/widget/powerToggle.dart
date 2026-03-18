import 'package:flutter/material.dart';
import '../../../core/helpers/colors.dart';

// ===== POWER TOGGLE =====
class PowerToggleSection extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const PowerToggleSection({
    super.key,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.primaryGradientDark
            : AppColors.primaryGradientLight,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(200),
          bottomRight: Radius.circular(200),
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.onPrimary,
          ),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(50),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
              ),
              child: Icon(
                isActive
                    ? Icons.stop_circle_outlined
                    : Icons.power_settings_new,
                size: 80,
                color: isActive
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
