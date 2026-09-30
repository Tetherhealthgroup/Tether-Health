import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

String localized(bool isSpanish, String english, String spanish) {
  return isSpanish ? spanish : english;
}

void showResourceInformation(
  BuildContext context, {
  required String title,
  required String body,
  required String closeLabel,
}) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 22,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(closeLabel),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class ResourcePageHeader extends StatelessWidget {
  const ResourcePageHeader({
    required this.title,
    required this.subtitle,
    this.onBack,
    this.backSemanticLabel,
    this.actions = const <Widget>[],
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final String? backSemanticLabel;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 10, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null) ...[
            Semantics(
              label: backSemanticLabel,
              button: true,
              onTap: onBack,
              excludeSemantics: true,
              child: IconButton(
                tooltip: backSemanticLabel,
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.deepTeal,
                ),
              ),
            ),
            const SizedBox(width: 2),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 28,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.tealSecondary,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class ResourceCard extends StatelessWidget {
  const ResourceCard({
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);

    Widget result = Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: color ?? AppColors.paper,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    if (semanticLabel != null) {
      result = Semantics(
        button: onTap != null,
        label: semanticLabel,
        child: result,
      );
    }

    return result;
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      color: AppColors.deepTeal,
      fontSize: 19,
      height: 1.15,
      fontWeight: FontWeight.w800,
    );

    if (trailing == null) {
      return Semantics(
        header: true,
        child: Text(title, style: titleStyle),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: titleStyle),
          ),
        ),
        const SizedBox(width: 8),
        trailing!,
      ],
    );
  }
}

class ResourceBottomNavigation extends StatelessWidget {
  const ResourceBottomNavigation({
    required this.selectedIndex,
    required this.isSpanish,
    required this.onHome,
    required this.onPlan,
    required this.onProgress,
    required this.onLearn,
    required this.onSupport,
    super.key,
  });

  final int selectedIndex;
  final bool isSpanish;
  final VoidCallback onHome;
  final VoidCallback onPlan;
  final VoidCallback onProgress;
  final VoidCallback onLearn;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final items = <({
      IconData icon,
      String label,
      VoidCallback onTap,
      Key key,
    })>[
      (
        icon: Icons.home_outlined,
        label: localized(isSpanish, 'Home', 'Inicio'),
        onTap: onHome,
        key: const ValueKey('learn-nav-home'),
      ),
      (
        icon: Icons.description_outlined,
        label: 'Plan',
        onTap: onPlan,
        key: const ValueKey('learn-nav-plan'),
      ),
      (
        icon: Icons.bar_chart_rounded,
        label: localized(isSpanish, 'Progress', 'Progreso'),
        onTap: onProgress,
        key: const ValueKey('learn-nav-progress'),
      ),
      (
        icon: Icons.menu_book_outlined,
        label: localized(isSpanish, 'Learn', 'Aprender'),
        onTap: onLearn,
        key: const ValueKey('learn-nav-learn'),
      ),
      (
        icon: Icons.person_outline_rounded,
        label: localized(isSpanish, 'Support', 'Apoyo'),
        onTap: onSupport,
        key: const ValueKey('learn-nav-support'),
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(
          top: BorderSide(color: Color(0xFFE1E9E4)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _ResourceBottomNavItem(
                    key: items[index].key,
                    icon: items[index].icon,
                    label: items[index].label,
                    selected: selectedIndex == index,
                    onTap: items[index].onTap,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceBottomNavItem extends StatelessWidget {
  const _ResourceBottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.deepTeal : AppColors.mutedTeal;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      selected ? const Color(0xFFE6F1EA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
