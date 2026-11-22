import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/status_message.dart';
import '../../../data/models/receipt.dart';

/// List of receipts for the selected date, with a search box.
class ReceiptListCard extends StatelessWidget {
  const ReceiptListCard({
    super.key,
    required this.group,
    required this.receipts,
    required this.selected,
    required this.isLoading,
    required this.searchController,
    required this.onSelected,
  });

  final ReceiptGroup? group;
  final List<Receipt> receipts;
  final Receipt? selected;
  final bool isLoading;
  final TextEditingController searchController;
  final ValueChanged<Receipt> onSelected;

  @override
  Widget build(BuildContext context) {
    final title = group == null ? 'ใบเสร็จ' : 'ใบเสร็จ ${Formatters.thaiDayShort(group!.date, fallback: group!.docDate)}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.cardTitle, overflow: TextOverflow.ellipsis)),
              if (group != null) _CountBadge(count: receipts.length),
            ],
          ),
          const SizedBox(height: 14),
          SearchField(controller: searchController, hintText: 'ค้นหาชื่อ หรือเลขที่ใบเสร็จ'),
          const SizedBox(height: 14),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (isLoading) return const LoadingIndicator();
    if (group == null) {
      return const StatusMessage(icon: Icons.touch_app_rounded, title: 'เลือกวันที่เพื่อดูใบเสร็จ');
    }
    if (receipts.isEmpty) {
      return const StatusMessage(
        icon: Icons.search_off_rounded,
        title: 'ไม่พบใบเสร็จ',
        message: 'ลองค้นหาด้วยชื่อหรือเลขที่อื่น',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(2),
      itemCount: receipts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final receipt = receipts[index];
        return _ReceiptTile(
          receipt: receipt,
          selected: identical(receipt, selected),
          onTap: () => onSelected(receipt),
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(999)),
      child: Text(
        '$count รายการ',
        style: AppTextStyles.caption.copyWith(color: AppColors.inkSoft, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({required this.receipt, required this.selected, required this.onTap});

  final Receipt receipt;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final method = receipt.paymentMethod;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: selected
          ? const BorderSide(color: AppColors.primary, width: 2)
          : const BorderSide(color: AppColors.border),
    );

    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? AppColors.selected : AppColors.surface,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: _avatarColors[method]!.$1,
                  child: Text(
                    Formatters.initial(receipt.agentName),
                    style: AppTextStyles.amount.copyWith(color: _avatarColors[method]!.$2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.agentName ?? '-',
                        style: AppTextStyles.bodyStrong,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text('${receipt.trRunNo ?? '-'} · ${method.label}', style: AppTextStyles.small),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(Formatters.baht(receipt.amountValue), style: AppTextStyles.amount),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// (background, foreground) of the avatar per payment method.
  static const Map<PaymentMethod, (Color, Color)> _avatarColors = {
    PaymentMethod.cash: (AppColors.peach, Color(0xFF8A3B0F)),
    PaymentMethod.card: (AppColors.lilac, Color(0xFF5B2A93)),
    PaymentMethod.transfer: (AppColors.rose, AppColors.primaryDark),
  };
}
