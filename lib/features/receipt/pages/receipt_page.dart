import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/receipt_controller.dart';
import '../widgets/date_strip.dart';
import '../widgets/receipt_header.dart';
import '../widgets/receipt_list_card.dart';
import '../widgets/receipt_preview_card.dart';
import '../widgets/summary_tiles.dart';

/// Receipt reprint screen (Bento layout).
class ReceiptPage extends StatefulWidget {
  const ReceiptPage({super.key, this.controller});

  /// Injected in tests; created internally otherwise.
  final ReceiptController? controller;

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  late final ReceiptController _controller = widget.controller ?? ReceiptController();

  static const double _gap = 20;
  static const double _wideBreakpoint = 1100;

  /// Height of everything above the list/preview row (header, tiles, date strip, gaps, padding).
  static const double _topSectionHeight = 470;

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showMonthPicker(
      context: context,
      initialDate: _controller.month,
      firstDate: ReceiptController.firstMonth,
      lastDate: DateTime(now.year, now.month),
    );
    if (picked != null) _controller.changeMonth(picked);
  }

  /// Runs print / download and tells the user when it fails.
  Future<void> _runOutput(Future<void> Function() action, String failureMessage) async {
    try {
      await action();
    } catch (e) {
      debugPrint('$failureMessage: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failureMessage), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => LayoutBuilder(builder: _buildLayout),
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context, BoxConstraints constraints) {
    final c = _controller;
    final isWide = constraints.maxWidth >= _wideBreakpoint;
    final mainHeight = math.max(600.0, constraints.maxHeight - _topSectionHeight);

    final list = ReceiptListCard(
      group: c.selectedGroup,
      receipts: c.visibleReceipts,
      selected: c.selectedReceipt,
      isLoading: c.isLoading,
      searchController: c.searchController,
      onSelected: c.selectReceipt,
    );
    final preview = ReceiptPreviewCard(
      receipt: c.selectedReceipt,
      pdfBytes: c.pdfBytes,
      isGenerating: c.isGeneratingPdf,
      hasError: c.pdfFailed,
      position: c.selectedIndex + 1,
      total: c.visibleReceipts.length,
      canPrint: c.canPrint,
      isBusy: c.isOutputBusy,
      onPrevious: c.canSelectPrevious ? c.selectPrevious : null,
      onNext: c.canSelectNext ? c.selectNext : null,
      onPrint: () => _runOutput(c.printSelected, 'พิมพ์ไม่สำเร็จ กรุณาลองอีกครั้ง'),
      onDownload: () => _runOutput(c.downloadSelected, 'ดาวน์โหลดไม่สำเร็จ กรุณาลองอีกครั้ง'),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReceiptHeader(
                month: c.month,
                canGoPrevious: c.canGoPreviousMonth,
                canGoNext: c.canGoNextMonth,
                onPrevious: c.previousMonth,
                onNext: c.nextMonth,
                onPickMonth: _pickMonth,
                canPrint: c.canPrint,
                permissionFailed: c.userLoadFailed,
                userName: c.userName,
              ),
              const SizedBox(height: _gap),
              SummaryTiles(tiles: _summaryTiles(c)),
              const SizedBox(height: _gap),
              DateStrip(
                groups: c.groups,
                selected: c.selectedGroup,
                isLoading: c.isLoading,
                hasError: c.hasError,
                onSelected: c.selectGroup,
                onRetry: c.loadReceipts,
              ),
              const SizedBox(height: _gap),
              if (isWide)
                SizedBox(
                  height: mainHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 46, child: list),
                      const SizedBox(width: _gap),
                      Expanded(flex: 54, child: preview),
                    ],
                  ),
                )
              else ...[
                SizedBox(height: 560, child: list),
                const SizedBox(height: _gap),
                SizedBox(height: 640, child: preview),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<SummaryTileData> _summaryTiles(ReceiptController c) {
    // Show a dash instead of misleading zeros while loading or after a failed load.
    String value(String text) => (c.isLoading || c.hasError) ? '—' : text;
    final group = c.selectedGroup;

    return [
      SummaryTileData(
        label: 'ยอดรวมทั้งเดือน',
        value: value(Formatters.baht(c.monthTotal)),
        caption: '${c.monthCount} ใบเสร็จ',
        background: AppColors.primary,
        foreground: AppColors.onPrimary,
        secondary: AppColors.onPrimaryMuted,
      ),
      SummaryTileData(
        label: 'ยอดวันที่เลือก',
        value: value(Formatters.baht(group?.totalAmount ?? 0)),
        caption: group == null ? 'ยังไม่ได้เลือกวัน' : '${Formatters.thaiDayShort(group.date, fallback: group.docDate)} · ${group.count} ใบ',
        background: AppColors.rose,
      ),
      SummaryTileData(
        label: 'ภาษีมูลค่าเพิ่มทั้งเดือน',
        value: value(Formatters.baht(c.monthVat)),
        caption: 'VAT 7% รวมในยอดแล้ว',
        background: AppColors.peach,
      ),
      SummaryTileData(
        label: 'วันที่มีรายการ',
        value: value('${c.activeDays} วัน'),
        caption: 'เฉลี่ย ${c.averagePerDay.toStringAsFixed(1)} ใบต่อวัน',
        background: AppColors.lilac,
      ),
    ];
  }
}
