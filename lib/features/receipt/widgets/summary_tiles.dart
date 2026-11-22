import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Data for one summary tile.
class SummaryTileData {
  const SummaryTileData({
    required this.label,
    required this.value,
    required this.caption,
    required this.background,
    this.foreground = AppColors.ink,
    this.secondary = AppColors.inkSoft,
  });

  final String label;
  final String value;
  final String caption;
  final Color background;
  final Color foreground;
  final Color secondary;
}

/// Row of summary tiles: 4 columns on wide screens, 2 on medium, 1 on phones.
class SummaryTiles extends StatelessWidget {
  const SummaryTiles({super.key, required this.tiles});

  final List<SummaryTileData> tiles;

  static const double _gap = 16;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1000 ? 4 : (width >= 520 ? 2 : 1);
        final tileWidth = (width - _gap * (columns - 1)) / columns;

        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final tile in tiles) SizedBox(width: tileWidth, child: _SummaryTile(tile)),
          ],
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile(this.data);

  final SummaryTileData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(color: data.background, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(data.label, style: AppTextStyles.body.copyWith(color: data.secondary)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(data.value, style: AppTextStyles.statValue.copyWith(color: data.foreground)),
          ),
          Text(
            data.caption,
            style: AppTextStyles.caption.copyWith(color: data.secondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
