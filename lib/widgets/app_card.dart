import 'package:flutter/material.dart';
import 'package:anantata/config/app_theme.dart';

/// Картка Anantata
/// Версія: 1.0
/// Дата: 12.12.2025

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final List<BoxShadow>? shadow;
  final Border? border;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.shadow,
    this.border,
    this.onTap,
    this.width,
    this.height,
  });

  /// Проста картка
  const AppCard.simple({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.width,
    this.height,
  })  : borderRadius = null,
        shadow = null,
        border = null;

  /// Картка з тінню
  factory AppCard.elevated({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding = const EdgeInsets.all(16),
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return AppCard(
      key: key,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor,
      shadow: AppTheme.shadowMedium,
      onTap: onTap,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Картка з бордером
  factory AppCard.outlined({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding = const EdgeInsets.all(16),
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    Color? borderColor,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return AppCard(
      key: key,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor ?? Colors.white,
      border: Border.all(
        color: borderColor ?? AppTheme.primaryColor.withOpacity(0.2),
        width: 1,
      ),
      onTap: onTap,
      width: width,
      height: height,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppTheme.paddingM),
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusL),
        boxShadow: shadow ?? AppTheme.shadowSmall,
        border: border,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusL),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Картка для відображення статистики
class AppStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const AppStatsCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.iconColor,
    this.backgroundColor,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.all(AppTheme.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? AppTheme.primaryColor,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.primaryColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Картка для кроку плану
class AppStepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isActive;
  final VoidCallback? onTap;

  const AppStepCard({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      backgroundColor: isActive ? AppTheme.primaryColor.withOpacity(0.05) : null,
      border: isActive
          ? Border.all(color: AppTheme.primaryColor, width: 2)
          : null,
      padding: const EdgeInsets.all(AppTheme.paddingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Номер кроку
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppTheme.successColor
                  : isActive
                      ? AppTheme.primaryColor
                      : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    )
                  : Text(
                      '$stepNumber',
                      style: TextStyle(
                        color: isActive ? Colors.white : AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Контент
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.headingSmall.copyWith(
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Стрілка
          Icon(
            Icons.chevron_right,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}
