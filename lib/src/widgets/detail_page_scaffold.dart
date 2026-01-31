// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';

/// Centralized detail page scaffold used by ALL detail pages (medications, schedules, etc.)
/// This ensures 100% consistent styling across all detail views
class DetailPageScaffold extends StatelessWidget {
  const DetailPageScaffold({
    required this.title,
    required this.statsBannerContent,
    required this.sections,
    required this.onEdit,
    required this.onDelete,
    this.expandedTitle,
    this.topRightAction,
    this.expandedHeight,
    this.collapsedHeight,
    this.toolbarHeight,
    super.key,
  });

  final String title;
  final String? expandedTitle;
  final Widget statsBannerContent;
  final List<Widget> sections;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;
  final Widget? topRightAction;
  final double? expandedHeight;
  final double? collapsedHeight;
  final double? toolbarHeight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final headerForeground = cs.onPrimary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Combined AppBar and Stats Banner
          SliverAppBar(
            toolbarHeight: toolbarHeight ?? kDetailHeaderCollapsedHeight,
            expandedHeight: expandedHeight ?? kDetailHeaderExpandedHeight,
            collapsedHeight: collapsedHeight ?? kDetailHeaderCollapsedHeight,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            foregroundColor: headerForeground,
            elevation: 0,
            actions: [
              if (topRightAction != null)
                Padding(
                  padding: const EdgeInsets.only(right: kSpacingS),
                  child: Center(child: topRightAction),
                ),
              PopupMenuButton<String>(
                tooltip: 'Menu',
                icon: Icon(Icons.menu, color: headerForeground),
                onSelected: (value) async {
                  switch (value) {
                    case 'home':
                      context.go('/');
                    case 'medications':
                      context.go('/medications');
                    case 'supplies':
                      context.go('/supplies');
                    case 'schedules':
                      context.go('/schedules');
                    case 'calendar':
                      context.go('/calendar');
                    case 'reconstitution':
                      context.push('/medications/reconstitution');
                    case 'analytics':
                      context.go('/analytics');
                    case 'settings':
                      context.go('/settings');
                    case 'edit':
                      onEdit();
                    case 'delete':
                      await onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'home', child: Text('Home')),
                  PopupMenuItem(
                    value: 'medications',
                    child: Text('Medications'),
                  ),
                  PopupMenuItem(value: 'supplies', child: Text('Supplies')),
                  PopupMenuItem(value: 'schedules', child: Text('Schedules')),
                  PopupMenuItem(value: 'calendar', child: Text('Calendar')),
                  PopupMenuItem(
                    value: 'reconstitution',
                    child: Text('Reconstitution Calculator'),
                  ),
                  PopupMenuItem(value: 'analytics', child: Text('Analytics')),
                  PopupMenuItem(value: 'settings', child: Text('Settings')),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline),
                        SizedBox(width: 12),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final expanded = expandedHeight ?? kDetailHeaderExpandedHeight;
                final collapsed =
                    collapsedHeight ?? kDetailHeaderCollapsedHeight;
                final scrollProgress =
                    ((expanded - constraints.maxHeight) / (expanded - collapsed))
                        .clamp(0.0, 1.0);

                return Container(
                  decoration: const BoxDecoration(
                    gradient: kDetailHeaderGradient,
                  ),
                  child: FlexibleSpaceBar(
                    titlePadding: EdgeInsets.only(
                      left: scrollProgress > 0.5 ? 0 : kToolbarHeight,
                      bottom: kSpacingL,
                    ),
                    centerTitle: scrollProgress > 0.5,
                    title: LayoutBuilder(
                      builder: (context, constraints) {
                        final appBarHeight = constraints.maxHeight;
                        final expanded =
                            expandedHeight ?? kDetailHeaderExpandedHeight;
                        final collapsed =
                            collapsedHeight ?? kDetailHeaderCollapsedHeight;
                        final scrollProgress =
                            ((expanded - appBarHeight) / (expanded - collapsed))
                                .clamp(0.0, 1.0);

                        final textStyle = detailCollapsedTitleTextStyle(
                          context,
                        );

                        if (expandedTitle == null || expandedTitle!.isEmpty) {
                          return Opacity(
                            opacity: scrollProgress,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: kToolbarHeight,
                              ),
                              child: Text(
                                title,
                                style: textStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kToolbarHeight,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: 1 - scrollProgress,
                                child: Text(
                                  expandedTitle!,
                                  style: textStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Opacity(
                                opacity: scrollProgress,
                                child: Text(
                                  title,
                                  style: textStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    background: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          kPageHorizontalPadding,
                          56,
                          kPageHorizontalPadding,
                          kPageHorizontalPadding,
                        ),
                        child: statsBannerContent,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Main content sections
          SliverPadding(
            padding: kDetailPageSectionsPadding,
            sliver: SliverList(delegate: SliverChildListDelegate(sections)),
          ),
        ],
      ),
    );
  }
}

/// Centralized stats banner builder - 4-row grid structure
/// Used by ALL detail pages to ensure consistent layout
class DetailStatsBanner extends StatelessWidget {
  const DetailStatsBanner({
    required this.title,
    required this.row1Left,
    required this.row1Right,
    required this.row2Left,
    required this.row2Right,
    required this.row3Left,
    required this.row3Right,
    this.headerChips,
    super.key,
  });

  final String title;
  final Widget row1Left;
  final Widget row1Right;
  final Widget row2Left;
  final Widget row2Right;
  final Widget row3Left;
  final Widget row3Right;
  final Widget? headerChips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title - centered
        Center(
          child: Text(
            title,
            style: detailHeaderBannerTitleTextStyle(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        if (headerChips != null) ...[
          const SizedBox(height: kSpacingS),
          headerChips!,
        ],
        const SizedBox(height: kCardInnerSpacing),

        // Row 1
        Row(
          children: [
            Expanded(child: row1Left),
            const SizedBox(width: kSpacingS),
            row1Right,
          ],
        ),
        const SizedBox(height: kCardInnerSpacing),

        // Row 2: 2-column grid
        Row(
          children: [
            Expanded(child: row2Left),
            const SizedBox(width: kPageHorizontalPadding),
            Expanded(child: row2Right),
          ],
        ),
        const SizedBox(height: kCardInnerSpacing),

        // Row 3: 2-column grid
        Row(
          children: [
            Expanded(child: row3Left),
            const SizedBox(width: kPageHorizontalPadding),
            Expanded(child: row3Right),
          ],
        ),
      ],
    );
  }
}

/// Centralized stat item widget for detail page banners
class DetailStatItem extends StatelessWidget {
  const DetailStatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.alignEnd = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onPrimary.withValues(alpha: kOpacityMedium);
    final alignment = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final rowAlignment =
        alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start;
    final textAlign = alignEnd ? TextAlign.right : TextAlign.left;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Row(
          mainAxisAlignment: rowAlignment,
          children: [
            Icon(icon, size: kIconSizeSmall, color: muted),
            const SizedBox(width: kSpacingXS),
            Text(
              label,
              style: helperTextStyle(context)?.copyWith(color: muted),
              textAlign: textAlign,
            ),
          ],
        ),
        const SizedBox(height: kSpacingXXS),
        Text(
          value,
          style: bodyTextStyle(
            context,
          )?.copyWith(color: cs.onPrimary, fontWeight: kFontWeightSemiBold),
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Centralized info row widget used in detail page sections
Widget buildDetailInfoRow(
  BuildContext context, {
  required String label,
  required String value,
  VoidCallback? onTap,
  bool highlighted = false,
  bool warning = false,
  int maxLines = 1,
}) {
  final theme = Theme.of(context);

  if (value.isEmpty) return const SizedBox.shrink();

  final row = Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          SizedBox(
            width: 140,
            child: Text(label, style: fieldLabelStyle(context)),
          ),
          const SizedBox(width: kPageHorizontalPadding),
        ],
        Expanded(
          child: Text(
            value,
            style: bodyTextStyle(context)?.copyWith(
              fontWeight: highlighted ? kFontWeightBold : kFontWeightNormal,
              color: warning
                  ? theme.colorScheme.error
                  : highlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(
                      alpha: kOpacityMediumHigh,
                    ),
            ),
            maxLines: maxLines,
            overflow: maxLines == 1 ? TextOverflow.ellipsis : null,
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: kCardInnerSpacing),
          Icon(
            Icons.edit_outlined,
            size: kIconSizeSmall,
            color: theme.colorScheme.primary.withValues(
              alpha: kOpacityMediumLow,
            ),
          ),
        ],
      ],
    ),
  );

  if (onTap != null) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kBorderRadiusMedium),
      child: row,
    );
  }

  return row;
}

/// Centralized info row widget used in detail page sections, with a custom
/// value widget.
Widget buildDetailInfoWidgetRow(
  BuildContext context, {
  required String label,
  required Widget child,
}) {
  if (label.isEmpty) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: fieldLabelStyle(context)),
        ),
        const SizedBox(width: kPageHorizontalPadding),
        Expanded(child: child),
      ],
    ),
  );
}
