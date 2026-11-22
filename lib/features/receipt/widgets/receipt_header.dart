import 'package:flutter/material.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/circle_icon_button.dart';

/// Top bar: logo and title on the left; month switcher, print permission
/// and user avatar on the right.
class ReceiptHeader extends StatelessWidget {
  const ReceiptHeader({
    super.key,
    required this.month,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onPickMonth,
    required this.canPrint,
    required this.permissionFailed,
    required this.userName,
  });

  final DateTime month;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickMonth;
  final bool canPrint;

  /// True when the permission API could not be reached.
  final bool permissionFailed;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        const _AppTitle(),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            _MonthSwitcher(
              month: month,
              onPrevious: canGoPrevious ? onPrevious : null,
              onNext: canGoNext ? onNext : null,
              onPick: onPickMonth,
            ),
            _PermissionChip(canPrint: canPrint, failed: permissionFailed),
            _UserAvatar(name: userName),
          ],
        ),
      ],
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.receipt_long_rounded, color: AppColors.onPrimary),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ใบเสร็จรับเงิน', style: AppTextStyles.pageTitle),
            Text('พิมพ์ซ้ำ · ${AppConfig.version}', style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final DateTime month;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleIconButton(icon: Icons.chevron_left_rounded, tooltip: 'เดือนก่อนหน้า', onPressed: onPrevious),
          Tooltip(
            message: 'เลือกเดือน',
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(Formatters.thaiMonthYear(month), style: AppTextStyles.label),
                  ],
                ),
              ),
            ),
          ),
          CircleIconButton(icon: Icons.chevron_right_rounded, tooltip: 'เดือนถัดไป', onPressed: onNext),
        ],
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  const _PermissionChip({required this.canPrint, required this.failed});

  final bool canPrint;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final color = canPrint ? AppColors.success : (failed ? AppColors.danger : AppColors.muted);
    final label = canPrint ? 'มีสิทธิ์พิมพ์' : (failed ? 'ตรวจสอบสิทธิ์ไม่สำเร็จ' : 'ไม่มีสิทธิ์พิมพ์');
    final icon = canPrint ? Icons.check_rounded : (failed ? Icons.error_outline_rounded : Icons.lock_outline_rounded);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final hasName = name != null && name!.trim().isNotEmpty;

    return Tooltip(
      message: hasName ? name! : 'ผู้ใช้',
      child: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.onPrimary,
        child: hasName
            ? Text(Formatters.initial(name), style: AppTextStyles.label.copyWith(color: AppColors.onPrimary))
            : const Icon(Icons.person_rounded, size: 22),
      ),
    );
  }
}
