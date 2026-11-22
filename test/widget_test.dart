import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_invoice/core/utils/formatters.dart';
import 'package:pdf_invoice/data/models/check_user.dart';
import 'package:pdf_invoice/data/models/receipt.dart';
import 'package:pdf_invoice/data/services/receipt_api.dart';

void main() {
  group('Formatters', () {
    final friday = DateTime(2026, 11, 20);

    test('money / baht', () {
      expect(Formatters.money(1234.5), '1,234.50');
      expect(Formatters.baht(1234.5), '฿1,234.50');
    });
    test('dashedDate', () => expect(Formatters.dashedDate(DateTime(2025, 1, 5)), '05-01-2025'));
    test('thaiMonthYear uses Buddhist year', () => expect(Formatters.thaiMonthYear(friday), 'พฤศจิกายน 2569'));
    test('thaiDayShort', () => expect(Formatters.thaiDayShort(friday), 'ศุกร์ 20 พ.ย.'));
    test('thaiWeekdayShort', () => expect(Formatters.thaiWeekdayShort(friday), 'ศ.'));

    test('initial skips titles and leading vowels', () {
      expect(Formatters.initial('นางสาวกมลวรรณ ศรีสุข'), 'ก');
      expect(Formatters.initial('นายธนพล วงศ์ใหญ่'), 'ธ');
      expect(Formatters.initial('บริษัท สยามเทรดดิ้ง จำกัด'), 'ส');
      expect(Formatters.initial('เกศินี ใจดี'), 'ก');
      expect(Formatters.initial('john'), 'J');
      expect(Formatters.initial(null), '?');
    });
  });

  group('Receipt', () {
    test('fromJson maps API keys', () {
      final r = Receipt.fromJson({
        'docno': 'R001',
        'docdate': '2025-01-05',
        'amount': '107.00',
        'AcReportName': 'Bank A',
        'bank_account': '123',
      });
      expect(r.docNo, 'R001');
      expect(r.amountValue, 107.0);
      expect(r.acReportName, 'Bank A');
      expect(r.bankAccount, '123');
    });

    test('amountValue falls back to 0', () => expect(const Receipt().amountValue, 0));

    test('VAT is extracted from the VAT-inclusive amount', () {
      const r = Receipt(amount: '107');
      expect(r.vatAmount, closeTo(7, 1e-9));
      expect(r.netAmount, closeTo(100, 1e-9));
    });

    test('paymentMethod from accode', () {
      expect(const Receipt(acCode: '111').paymentMethod, PaymentMethod.cash);
      expect(const Receipt(acCode: '114').paymentMethod, PaymentMethod.card);
      expect(const Receipt(acCode: '999').paymentMethod, PaymentMethod.transfer);
    });

    test('ReceiptGroup totals', () {
      final g = ReceiptGroup(docDate: '2025-01-05', receipts: const [Receipt(amount: '107'), Receipt(amount: '214')]);
      expect(g.count, 2);
      expect(g.totalAmount, 321);
      expect(g.totalVat, closeTo(21, 1e-9));
    });

    test('fromJson accepts numbers and formatted amounts', () {
      final r = Receipt.fromJson({'docno': 15, 'amount': 1070, 'accode': 111});
      expect(r.docNo, '15');
      expect(r.amountValue, 1070);
      expect(r.paymentMethod, PaymentMethod.cash);
      expect(const Receipt(amount: '1,070.50').amountValue, 1070.5);
    });

    test('invalid dates do not throw', () {
      expect(const Receipt(docDate: 'not a date').date, isNull);
      expect(ReceiptGroup(docDate: '', receipts: const []).date, isNull);
      expect(const Receipt(docDate: '2026-11-20 00:00:00').date, DateTime(2026, 11, 20));
    });
  });

  group('ReceiptApi.decodeList', () {
    test('accepts a list or a JSON string', () {
      expect(ReceiptApi.decodeList([1, 2]), [1, 2]);
      expect(ReceiptApi.decodeList(' [{"a":1}] '), [
        {'a': 1}
      ]);
      expect(ReceiptApi.decodeList(''), isEmpty);
    });

    test('rejects anything else', () {
      expect(() => ReceiptApi.decodeList({'error': 'x'}), throwsFormatException);
      expect(() => ReceiptApi.decodeList('<html>error</html>'), throwsFormatException);
    });
  });

  test('CheckUser.canPrint', () {
    expect(const CheckUser(chk: 'Y').canPrint, isTrue);
    expect(const CheckUser(chk: 'N').canPrint, isFalse);
  });

  test('groupByDate groups by docdate, sorts dates and doc numbers', () {
    final groups = ReceiptApi.groupByDate(const [
      Receipt(docNo: 'C', docDate: '2025-01-06'),
      Receipt(docNo: 'B', docDate: '2025-01-05'),
      Receipt(docNo: 'A', docDate: '2025-01-05'),
    ]);

    expect(groups.map((g) => g.docDate), ['2025-01-05', '2025-01-06']);
    expect(groups.first.receipts.map((r) => r.docNo), ['A', 'B']);
  });
}
