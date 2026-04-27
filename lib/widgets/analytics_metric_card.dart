import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnalyticsMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final double? change;
  final bool invertChange;
  final IconData icon;

  const AnalyticsMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.change,
    this.invertChange = false,
    required this.icon,
  });

  bool get isPositive {
    if (change == null) return true;
    return invertChange ? change! <= 0 : change! >= 0;
  }

  Color get changeColor {
    if (change == null) return Colors.grey;
    return isPositive ? AppTheme.success : AppTheme.error;
  }

  String? get changeText {
    if (change == null) return null;
    final prefix = change! >= 0 ? '+' : '';
    return '$prefix${change!.toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppTheme.onSurfaceVariant.withOpacity(0.5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceVariant.withOpacity(0.6),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          if (changeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: changeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 10,
                    color: changeColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    changeText!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: changeColor,
                    ),
                  ),
                ],
              ),
            )
          else
            const Text(
              '—',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
