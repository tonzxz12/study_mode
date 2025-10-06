import 'package:flutter/material.dart';

class ShadcnBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final BadgeSize size;

  const ShadcnBadge({
    super.key,
    required this.text,
    this.variant = BadgeVariant.primary,
    this.size = BadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color backgroundColor;
    Color textColor;

    switch (variant) {
      case BadgeVariant.primary:
        backgroundColor = colorScheme.primary;
        textColor = colorScheme.onPrimary;
        break;
      case BadgeVariant.secondary:
        backgroundColor = colorScheme.secondary.withOpacity(0.1);
        textColor = colorScheme.onSurface;
        break;
      case BadgeVariant.success:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green.shade700;
        break;
      case BadgeVariant.warning:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange.shade700;
        break;
      case BadgeVariant.error:
        backgroundColor = colorScheme.error.withOpacity(0.1);
        textColor = colorScheme.error;
        break;
      case BadgeVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = colorScheme.onSurface;
        break;
    }

    EdgeInsets padding;
    double fontSize;

    switch (size) {
      case BadgeSize.small:
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
        fontSize = 10;
        break;
      case BadgeSize.medium:
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
        fontSize = 12;
        break;
      case BadgeSize.large:
        padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
        fontSize = 14;
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: variant == BadgeVariant.outline
            ? Border.all(color: colorScheme.outline.withOpacity(0.5))
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

enum BadgeVariant {
  primary,
  secondary,
  success,
  warning,
  error,
  outline,
}

enum BadgeSize {
  small,
  medium,
  large,
}

class ShadcnChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onDeleted;
  final IconData? icon;
  final Color? color;

  const ShadcnChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.onDeleted,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chipColor = color ?? colorScheme.primary;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      onDeleted: onDeleted,
      avatar: icon != null ? Icon(icon, size: 16) : null,
      backgroundColor: chipColor.withOpacity(0.1),
      selectedColor: chipColor.withOpacity(0.2),
      checkmarkColor: chipColor,
      deleteIconColor: chipColor,
      side: BorderSide(
        color: selected ? chipColor : colorScheme.outline.withOpacity(0.3),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      labelStyle: TextStyle(
        color: selected ? chipColor : colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
      ),
    );
  }
}
