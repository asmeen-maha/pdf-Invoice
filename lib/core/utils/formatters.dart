import 'package:intl/intl.dart';

/// Number, date and name formatting helpers.
class Formatters {
  Formatters._();

  static final NumberFormat _money = NumberFormat('#,##0.00', 'en_US');
  static final DateFormat _dashed = DateFormat('dd-MM-yyyy');

  static const List<String> _thaiMonths = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];
  static const List<String> _thaiMonthsShort = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];
  // Index 0 = Monday, matching DateTime.weekday - 1.
  static const List<String> _thaiWeekdays = ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์', 'อาทิตย์'];
  static const List<String> _thaiWeekdaysShort = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];

  static const List<String> _namePrefixes = [
    'ห้างหุ้นส่วนจำกัด', 'บริษัท', 'หจก.', 'บจก.', 'นางสาว', 'นาย', 'นาง', 'น.ส.',
  ];
  static const String _leadingThaiVowels = 'เแโใไ';

  /// 1234.5 -> `1,234.50`
  static String money(double value) => _money.format(value);

  /// 1234.5 -> `฿1,234.50`
  static String baht(double value) => '฿${money(value)}';

  /// 2026-11-20 -> `20-11-2026`
  static String dashedDate(DateTime date) => _dashed.format(date);

  /// 2026-11-20 -> `พฤศจิกายน 2569`
  static String thaiMonthYear(DateTime date) => '${_thaiMonths[date.month - 1]} ${date.year + 543}';

  /// 2026-11-20 -> `ศุกร์ 20 พ.ย.`; [fallback] when the date is unknown.
  static String thaiDayShort(DateTime? date, {String fallback = '-'}) => date == null
      ? fallback
      : '${_thaiWeekdays[date.weekday - 1]} ${date.day} ${_thaiMonthsShort[date.month - 1]}';

  /// 2026-11-20 -> `ศ.`; empty when the date is unknown.
  static String thaiWeekdayShort(DateTime? date) => date == null ? '' : _thaiWeekdaysShort[date.weekday - 1];

  /// First meaningful letter of a Thai or English name, for avatars.
  /// `นางสาวกมลวรรณ` -> `ก`, `บริษัท สยาม จำกัด` -> `ส`, `เกศินี` -> `ก`.
  static String initial(String? name) {
    var text = (name ?? '').trim();
    for (final prefix in _namePrefixes) {
      if (text.startsWith(prefix)) {
        text = text.substring(prefix.length).trim();
        break;
      }
    }
    for (final char in text.split('')) {
      if (char.trim().isNotEmpty && !_leadingThaiVowels.contains(char)) return char.toUpperCase();
    }
    return '?';
  }
}
