import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../theme/styles.dart';

/// Responsive dialog that adapts to different screen sizes
/// Provides consistent dialog experience across mobile, tablet, and desktop
class ResponsiveDialog extends StatelessWidget {
  final Widget title;
  final Widget content;
  final List<Widget>? actions;
  final EdgeInsets? contentPadding;
  final bool scrollable;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;

  const ResponsiveDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.contentPadding,
    this.scrollable = true,
    this.backgroundColor,
    this.elevation,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: backgroundColor ?? AppStyles.card,
      elevation: elevation ?? 8,
      shape: shape ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          context.responsive(
            mobile: 16,
            tablet: 20,
            desktop: 24,
          ),
        ),
      ),
      child: ConstrainedBox(
        constraints: context.modalConstraints,
        child: Container(
          width: context.dialogWidth,
          padding: context.responsive(
            mobile: const EdgeInsets.all(24),
            tablet: const EdgeInsets.all(32),
            desktop: const EdgeInsets.all(40),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              DefaultTextStyle(
                style: context.scaleTextStyle(AppStyles.sectionHeader),
                child: title,
              ),
              
              SizedBox(height: context.spacing(20)),
              
              // Content
              Flexible(
                child: scrollable
                    ? SingleChildScrollView(
                        child: content,
                      )
                    : content,
              ),
              
              // Actions
              if (actions != null && actions!.isNotEmpty) ...[
                SizedBox(height: context.spacing(24)),
                _buildActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (actions == null || actions!.isEmpty) return const SizedBox.shrink();

    // On mobile, stack actions vertically
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: actions!
            .map((action) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    height: 48,
                    child: action,
                  ),
                ))
            .toList(),
      );
    }

    // On tablet/desktop, arrange actions horizontally
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: actions!
          .map((action) => Padding(
                padding: const EdgeInsets.only(left: 12),
                child: action,
              ))
          .toList(),
    );
  }
}

/// Responsive modal bottom sheet that adapts to screen sizes
class ResponsiveModalBottomSheet extends StatelessWidget {
  final Widget child;
  final double? height;
  final bool isScrollControlled;
  final Color? backgroundColor;
  final ShapeBorder? shape;

  const ResponsiveModalBottomSheet({
    super.key,
    required this.child,
    this.height,
    this.isScrollControlled = true,
    this.backgroundColor,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    // On desktop/tablet, show as dialog instead of bottom sheet
    if (context.isTablet || context.isDesktop) {
      return Dialog(
        backgroundColor: backgroundColor ?? AppStyles.card,
        shape: shape ?? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.dialogWidth,
            maxHeight: height ?? MediaQuery.of(context).size.height * 0.8,
          ),
          child: child,
        ),
      );
    }

    // On mobile, show as bottom sheet
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppStyles.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: child,
    );
  }

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    double? height,
    bool isScrollControlled = true,
    Color? backgroundColor,
    ShapeBorder? shape,
  }) {
    final responsiveSheet = ResponsiveModalBottomSheet(
      height: height,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      shape: shape,
      child: child,
    );

    // Show as dialog on larger screens
    if (context.isTablet || context.isDesktop) {
      return showDialog<T>(
        context: context,
        builder: (context) => responsiveSheet,
      );
    }

    // Show as modal bottom sheet on mobile
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => responsiveSheet,
    );
  }
}

/// Helper function to show responsive dialogs
Future<T?> showResponsiveDialog<T>(
  BuildContext context, {
  required Widget title,
  required Widget content,
  List<Widget>? actions,
  bool scrollable = true,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => ResponsiveDialog(
      title: title,
      content: content,
      actions: actions,
      scrollable: scrollable,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
    ),
  );
}