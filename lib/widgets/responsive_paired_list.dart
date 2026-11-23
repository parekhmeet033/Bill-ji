import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/utils/responsive.dart';

/// A vertical list that renders one item per row on phones — identical to
/// a plain `ListView.separated`, so phone layouts are completely
/// untouched — but pairs items two-per-row on tablets, so wide tablet
/// screens don't stretch a single card edge-to-edge (order history,
/// recent orders, menu item pickers, etc).
///
/// Each card keeps its own natural height: the two cards in a row are
/// simply top-aligned (not stretched to match each other), which matters
/// for cards like `OrderCard` that can expand/collapse individually.
class ResponsivePairedList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final double spacing;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  /// Extra full-width widget appended after all item rows (e.g. a
  /// trailing "load more" spinner during pagination). Always rendered as
  /// its own single, full-width row, on both phone and tablet.
  final Widget? trailing;

  const ResponsivePairedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.spacing = 10,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.controller,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final bool paired = Responsive.isTablet(context);
    final int rowCount = paired ? (items.length / 2).ceil() : items.length;
    final int itemCount = rowCount + (trailing != null ? 1 : 0);

    return ListView.separated(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(height: spacing.h),
      itemBuilder: (context, index) {
        if (index == rowCount) return trailing!;

        if (!paired) {
          return itemBuilder(context, items[index]);
        }

        final firstIndex = index * 2;
        final secondIndex = firstIndex + 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: itemBuilder(context, items[firstIndex])),
            SizedBox(width: spacing.w),
            Expanded(
              child: secondIndex < items.length ? itemBuilder(context, items[secondIndex]) : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
