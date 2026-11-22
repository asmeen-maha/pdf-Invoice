import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_message.dart';
import '../../../data/models/receipt.dart';

/// PDF preview of the selected receipt with print / download actions.
class ReceiptPreviewCard extends StatelessWidget {
  const ReceiptPreviewCard({
    super.key,
    required this.receipt,
    required this.pdfBytes,
    required this.isGenerating,
    required this.hasError,
    required this.position,
    required this.total,
    required this.canPrint,
    required this.isBusy,
    required this.onPrevious,
    required this.onNext,
    required this.onPrint,
    required this.onDownload,
  });

  final Receipt? receipt;
  final Uint8List? pdfBytes;
  final bool isGenerating;
  final bool hasError;

  /// 1-based position of [receipt] in the visible list, or 0 when hidden by search.
  final int position;
  final int total;

  final bool canPrint;

  /// True while a print / download is in progress.
  final bool isBusy;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPrint;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final ready = pdfBytes != null;
    final subtitle = receipt == null
        ? 'ยังไม่ได้เลือกใบเสร็จ'
        : '${receipt!.trRunNo ?? '-'} · ${position > 0 ? '$position จาก $total' : 'ไม่อยู่ในผลการค้นหา'}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ตัวอย่างใบเสร็จ', style: AppTextStyles.cardTitle),
                    Text(subtitle, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              CircleIconButton(icon: Icons.chevron_left_rounded, tooltip: 'ใบก่อนหน้า', onPressed: onPrevious),
              const SizedBox(width: 8),
              CircleIconButton(icon: Icons.chevron_right_rounded, tooltip: 'ใบถัดไป', onPressed: onNext),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ColoredBox(color: AppColors.surfaceMuted, child: _buildPreview()),
            ),
          ),
          const SizedBox(height: 14),
          _Actions(
            enabled: canPrint && ready && !isBusy,
            canPrint: canPrint,
            amount: receipt?.amountValue,
            onPrint: onPrint,
            onDownload: onDownload,
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (pdfBytes != null) return _PdfView(bytes: pdfBytes!);
    if (isGenerating) return const LoadingIndicator();
    if (hasError) {
      return const StatusMessage(icon: Icons.error_outline_rounded, title: 'สร้างใบเสร็จไม่สำเร็จ');
    }
    return const StatusMessage(icon: Icons.description_outlined, title: 'เลือกใบเสร็จเพื่อดูตัวอย่าง');
  }
}

/// Wraps [PdfPreview] and keeps its `build` callback stable, so the PDF is
/// only re-rendered when the bytes change, not on every parent rebuild.
class _PdfView extends StatefulWidget {
  const _PdfView({required this.bytes});

  final Uint8List bytes;

  @override
  State<_PdfView> createState() => _PdfViewState();
}

class _PdfViewState extends State<_PdfView> {
  late LayoutCallback _build = _createBuild();

  LayoutCallback _createBuild() {
    final bytes = widget.bytes;
    return (_) => bytes;
  }

  @override
  void didUpdateWidget(covariant _PdfView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes)) _build = _createBuild();
  }

  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      build: _build,
      useActions: false,
      allowPrinting: false,
      allowSharing: false,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      previewPageMargin: const EdgeInsets.all(20),
      scrollViewDecoration: const BoxDecoration(color: AppColors.surfaceMuted),
      pdfPreviewPageDecoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Color(0x0F2A1420), blurRadius: 4, offset: Offset(0, 2)),
          BoxShadow(color: Color(0x1A2A1420), blurRadius: 34, offset: Offset(0, 14)),
        ],
      ),
      loadingWidget: const LoadingIndicator(),
      onError: (context, error) =>
          const StatusMessage(icon: Icons.error_outline_rounded, title: 'แสดงตัวอย่างไม่สำเร็จ'),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.enabled,
    required this.canPrint,
    required this.amount,
    required this.onPrint,
    required this.onDownload,
  });

  final bool enabled;
  final bool canPrint;
  final double? amount;
  final VoidCallback onPrint;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    const size = Size.fromHeight(56);
    final printLabel = amount == null ? 'พิมพ์ใบเสร็จ' : 'พิมพ์ใบเสร็จ · ${Formatters.baht(amount!)}';

    final buttons = Row(
      children: [
        Expanded(
          flex: 2,
          child: FilledButton.tonalIcon(
            onPressed: enabled ? onDownload : null,
            icon: const Icon(Icons.download_rounded),
            label: const Text('ดาวน์โหลด'),
            style: FilledButton.styleFrom(
              minimumSize: size,
              shape: shape,
              backgroundColor: AppColors.surfaceMuted,
              foregroundColor: AppColors.ink,
              textStyle: AppTextStyles.label,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: FilledButton.icon(
            onPressed: enabled ? onPrint : null,
            icon: const Icon(Icons.print_rounded),
            label: Text(printLabel, overflow: TextOverflow.ellipsis),
            style: FilledButton.styleFrom(
              minimumSize: size,
              shape: shape,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              textStyle: AppTextStyles.button,
            ),
          ),
        ),
      ],
    );

    if (canPrint) return buttons;
    return Tooltip(message: 'บัญชีนี้ไม่มีสิทธิ์พิมพ์หรือดาวน์โหลดใบเสร็จ', child: buttons);
  }
}
