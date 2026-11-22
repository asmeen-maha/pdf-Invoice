import 'package:flutter/services.dart';
import 'package:number_to_thai_words/number_to_thai_words.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/formatters.dart';
import '../../../data/models/receipt.dart';

/// Builds the receipt PDF. Text is printed at fixed positions so it lines
/// up with a pre-printed A4 landscape receipt form.
class ReceiptPdf {
  ReceiptPdf._();

  // TODO: placeholder values still hard-coded in the layout.
  static const String _unitPrice = '8504.67';
  static const String _paymentAmount = '5,000.00';

  static const PdfPageFormat _pageFormat = PdfPageFormat(
    29.7 * PdfPageFormat.cm,
    21.0 * PdfPageFormat.cm,
    marginAll: 0,
  );

  static late pw.Font _thaiFont;
  static late pw.Font _numberFont;
  static Future<void>? _fontsLoaded;

  /// Loads the PDF fonts in the background so the first receipt opens faster.
  static Future<void> preload() => _fontsLoaded ??= _loadFonts();

  static Future<Uint8List> generate(Receipt receipt) async {
    await preload();

    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    pdf.addPage(
      pw.Page(
        pageFormat: _pageFormat,
        build: (_) => pw.Stack(
          children: [
            pw.SizedBox(width: _pageFormat.width, height: _pageFormat.height),
            ..._header(receipt),
            ..._items(receipt),
            ..._payment(receipt),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  static Future<void> _loadFonts() async {
    try {
      final fonts = await Future.wait([
        rootBundle.load('assets/fonts/pgvim.ttf'),
        rootBundle.load('assets/fonts/trajanpro-bold.ttf'),
      ]);
      _thaiFont = pw.Font.ttf(fonts[0]);
      _numberFont = pw.Font.ttf(fonts[1]);
    } catch (_) {
      _fontsLoaded = null; // allow a retry on the next receipt
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  static List<pw.Widget> _header(Receipt r) => [
        _thai(r.agentName, top: 156, left: 119.5),
        _number(r.trRunNo, top: 154, right: 42, size: 16),
        _thai(r.address, top: 191, left: 119.5, width: 550),
        _number(r.date == null ? r.docDate : Formatters.dashedDate(r.date!), top: 191, right: 42, size: 15),
      ];

  static List<pw.Widget> _items(Receipt r) {
    final amount = r.amountValue;
    final net = Formatters.money(r.netAmount);
    final vatText = Formatters.money(r.vatAmount);
    final total = Formatters.money(amount);

    const itemRow = 257.0;
    const totalRow = 362.0;

    return [
      // Line item
      _number('1', top: itemRow, left: 73),
      _thai('ค่าบัตร', top: itemRow, left: 115, size: 13),
      _number('1', top: itemRow, left: 400),
      _number(_unitPrice, top: itemRow, left: 440),
      _number(net, top: itemRow, right: 253),
      _number(vatText, top: itemRow, right: 150),
      _number(total, top: itemRow, right: 45),

      // Totals
      _thai(NumberToThaiWords.convert(amount), top: totalRow, left: 196, size: 13),
      _number(net, top: totalRow, right: 253),
      _number(vatText, top: totalRow, right: 150),
      _number(total, top: totalRow, right: 45),
    ];
  }

  /// Payment method box. Cash and card are ticked on the upper row;
  /// a transfer also prints its bank details on the row below.
  static List<pw.Widget> _payment(Receipt r) => switch (r.paymentMethod) {
        PaymentMethod.cash => [
            _number('X', top: 400, left: 160, size: 13),
            _number(_paymentAmount, top: 400, left: 320),
          ],
        PaymentMethod.card => [
            _number('X', top: 400, left: 460, size: 13),
            _number(_paymentAmount, top: 400, right: 90),
          ],
        PaymentMethod.transfer => [
            _number('X', top: 412, left: 460, size: 13),
            _number(_paymentAmount, top: 412, right: 90),
            _thai(r.acReportName, top: 434.5, left: 180),
            _number(r.bankAccount, top: 434.5, left: 420),
            _number(r.referNo, top: 434.5, right: 100),
          ],
      };

  // ---------------------------------------------------------------------------
  // Text helpers
  // ---------------------------------------------------------------------------

  static pw.Widget _thai(String? text, {required double top, double? left, double? right, double size = 13.5, double? width}) =>
      _text(text, _thaiFont, top: top, left: left, right: right, size: size, width: width);

  static pw.Widget _number(String? text, {required double top, double? left, double? right, double size = 13.5}) =>
      _text(text, _numberFont, top: top, left: left, right: right, size: size);

  static pw.Widget _text(
    String? text,
    pw.Font font, {
    required double top,
    double? left,
    double? right,
    required double size,
    double? width,
  }) {
    final child = pw.Text(
      text ?? '',
      style: pw.TextStyle(font: font, fontSize: size, color: PdfColors.black),
    );
    return pw.Positioned(
      top: top,
      left: left,
      right: right,
      child: width == null ? child : pw.SizedBox(width: width, child: child),
    );
  }
}
