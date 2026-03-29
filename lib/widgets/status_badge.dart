import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String state;
  final bool isError;
  final bool isReady;

  const StatusBadge({
    super.key,
    required this.state,
    required this.isError,
    required this.isReady,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isError
            ? AppTheme.errorContainer.withValues(alpha: 0.1)
            : (isReady
                ? AppTheme.success.withValues(alpha: 0.1)
                : AppTheme.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(2),
        border: isError
            ? Border.all(color: AppTheme.error.withValues(alpha: 0.2))
            : (isReady
                ? Border.all(color: AppTheme.success.withValues(alpha: 0.2))
                : null),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isReady
                  ? AppTheme.success
                  : (isError ? AppTheme.error : AppTheme.secondary),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            state.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: isError
                  ? AppTheme.error
                  : (isReady ? AppTheme.success : AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
