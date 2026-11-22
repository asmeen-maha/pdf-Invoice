import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_message.dart';
import '../../../data/models/receipt.dart';

/// Horizontal strip of the dates that have receipts in the selected month.
class DateStrip extends StatefulWidget {
  const DateStrip({
    super.key,
    required this.groups,
    required this.selected,
    required this.isLoading,
    required this.hasError,
    required this.onSelected,
    required this.onRetry,
  });

  final List<ReceiptGroup> groups;
  final ReceiptGroup? selected;
  final bool isLoading;
  final bool hasError;
  final ValueChanged<ReceiptGroup> onSelected;
  final VoidCallback onRetry;

  @override
  State<DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<DateStrip> {
  static const double _chipHeight = 84;

  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant DateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new month was loaded and its latest date is selected: show the end.
    if (!identical(oldWidget.groups, widget.groups)) _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('เลือกวันที่', style: AppTextStyles.sectionTitle),
              Text('แสดงเฉพาะวันที่มีใบเสร็จ', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(height: _chipHeight + 12, child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) return const LoadingIndicator(size: 28);
    if (widget.hasError) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('โหลดข้อมูลไม่สำเร็จ', style: AppTextStyles.caption),
          TextButton(onPressed: widget.onRetry, child: const Text('ลองอีกครั้ง')),
        ],
      );
    }
    if (widget.groups.isEmpty) {
      return const StatusMessage(icon: Icons.event_busy_rounded, title: 'ไม่มีใบเสร็จในเดือนนี้');
    }

    return ScrollConfiguration(
      // Let mouse users drag the strip sideways on the web.
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
      ),
      child: Scrollbar(
        controller: _scroll,
        thumbVisibility: true,
        child: ListView.separated(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: widget.groups.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final group = widget.groups[index];
            return _DayChip(
              group: group,
              selected: identical(group, widget.selected),
              onTap: () => widget.onSelected(group),
            );
          },
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.group, required this.selected, required this.onTap});

  final ReceiptGroup group;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.onPrimary : AppColors.ink;
    final secondary = selected ? AppColors.onPrimaryMuted : AppColors.muted;
    final date = group.date;

    return Semantics(
      selected: selected,
      button: true,
      label: '${Formatters.thaiDayShort(date, fallback: group.docDate)} ${group.count} ใบ',
      child: Material(
        color: selected ? AppColors.primary : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 72,
            height: 84,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(Formatters.thaiWeekdayShort(date), style: AppTextStyles.small.copyWith(color: secondary)),
                Text(date == null ? '?' : '${date.day}', style: AppTextStyles.dayNumber.copyWith(color: foreground)),
                Text('${group.count} ใบ', style: AppTextStyles.small.copyWith(fontSize: 11, color: secondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
