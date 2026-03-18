import 'package:flutter/material.dart';
import 'package:circle_flags/circle_flags.dart';
import '../../../core/helpers/colors.dart';


// ===== LANGUAGE BUTTON =====
class LanguageButton extends StatelessWidget {
  final String label;
  final String flagCode;
  final VoidCallback onTap;

  const LanguageButton({
    super.key,
    required this.label,
    required this.flagCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              CircleFlag(flagCode, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}