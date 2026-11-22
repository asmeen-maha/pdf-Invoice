import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_invoice/data/models/check_user.dart';
import 'package:pdf_invoice/data/models/receipt.dart';
import 'package:pdf_invoice/data/services/receipt_api.dart';
import 'package:pdf_invoice/features/receipt/controllers/receipt_controller.dart';

class _FakeApi extends ReceiptApi {
  _FakeApi({this.groups, this.users = const [CheckUser(chk: 'Y', name: 'สมหญิง')]});

  final List<ReceiptGroup>? groups;
  final List<CheckUser>? users;
  final List<(int, int)> requests = [];

  @override
  Future<List<ReceiptGroup>?> getReceipts({required int year, required int month}) async {
    requests.add((year, month));
    return groups;
  }

  @override
  Future<List<CheckUser>?> checkUser() async => users;
}

Receipt _receipt(String no, String date, String name, String amount) =>
    Receipt(docNo: no, trRunNo: no, docDate: date, agentName: name, amount: amount);

final _groups = ReceiptApi.groupByDate([
  _receipt('A1', '2026-11-19', 'กมลวรรณ', '107'),
  _receipt('B1', '2026-11-20', 'ธนพล', '214'),
  _receipt('B2', '2026-11-20', 'พรทิพย์', '321'),
  _receipt('B3', '2026-11-20', 'ธนวัฒน์', '428'),
]);

ReceiptController _controller({List<ReceiptGroup>? groups, List<CheckUser>? users = const [CheckUser(chk: 'Y')]}) {
  return ReceiptController(
    api: _FakeApi(groups: groups, users: users),
    pdfBuilder: (_) async => Uint8List.fromList([1, 2, 3]),
    clock: () => DateTime(2026, 11, 22),
  );
}

void main() {
  test('init selects the latest date and its first receipt', () async {
    final c = _controller(groups: _groups);
    await c.init();
    await pumpEventQueue();

    expect(c.isLoading, isFalse);
    expect(c.selectedGroup?.docDate, '2026-11-20');
    expect(c.selectedReceipt?.docNo, 'B1');
    expect(c.pdfBytes, isNotNull);
    expect(c.canPrint, isTrue);
  });

  test('month totals', () async {
    final c = _controller(groups: _groups);
    await c.init();

    expect(c.monthCount, 4);
    expect(c.monthTotal, 1070);
    expect(c.monthVat, closeTo(70, 1e-9));
    expect(c.activeDays, 2);
    expect(c.averagePerDay, 2);
  });

  test('search filters by name or number', () async {
    final c = _controller(groups: _groups);
    await c.init();

    c.searchController.text = 'ธน';
    expect(c.visibleReceipts.map((r) => r.docNo), ['B1', 'B3']);

    c.searchController.text = 'b2';
    expect(c.visibleReceipts.map((r) => r.docNo), ['B2']);
  });

  test('previous / next move within the visible list', () async {
    final c = _controller(groups: _groups);
    await c.init();
    await pumpEventQueue();

    expect(c.canSelectPrevious, isFalse);
    c.selectNext();
    expect(c.selectedReceipt?.docNo, 'B2');
    c.selectNext();
    expect(c.selectedReceipt?.docNo, 'B3');
    expect(c.canSelectNext, isFalse);
    c.selectPrevious();
    expect(c.selectedReceipt?.docNo, 'B2');
  });

  test('selecting a date clears the search', () async {
    final c = _controller(groups: _groups);
    await c.init();

    c.searchController.text = 'xyz';
    c.selectGroup(c.groups.first);
    expect(c.searchController.text, isEmpty);
    expect(c.selectedReceipt?.docNo, 'A1');
  });

  test('cannot go past the current month', () async {
    final c = _controller(groups: _groups);
    await c.init();

    expect(c.canGoNextMonth, isFalse);
    c.nextMonth();
    expect(c.month, DateTime(2026, 11));

    c.previousMonth();
    expect(c.month, DateTime(2026, 10));
    expect(c.canGoNextMonth, isTrue);
  });

  test('API failure is reported as an error', () async {
    final c = _controller(groups: null);
    await c.init();

    expect(c.hasError, isTrue);
    expect(c.groups, isEmpty);
    expect(c.selectedGroup, isNull);
  });

  test('PDFs are cached and the next one is prefetched', () async {
    final built = <String?>[];
    final c = ReceiptController(
      api: _FakeApi(groups: _groups),
      pdfBuilder: (r) async {
        built.add(r.docNo);
        return Uint8List.fromList([1]);
      },
      clock: () => DateTime(2026, 11, 22),
    );
    await c.init();
    await pumpEventQueue();
    expect(built, ['B1', 'B2']); // B2 prefetched

    c.selectNext();
    await pumpEventQueue();
    expect(c.pdfBytes, isNotNull);
    c.selectPrevious();
    await pumpEventQueue();
    expect(built, ['B1', 'B2', 'B3']); // B1 came from the cache, B3 prefetched
  });

  test('a stale month response does not overwrite a newer one', () async {
    final c = _controller(groups: _groups);
    await c.init();
    c.previousMonth();
    c.nextMonth();
    await pumpEventQueue();
    expect(c.month, DateTime(2026, 11));
    expect(c.isLoading, isFalse);
  });

  test('permission API failure is reported', () async {
    final c = _controller(groups: _groups, users: null);
    await c.init();
    expect(c.userLoadFailed, isTrue);
    expect(c.canPrint, isFalse);
  });

  test('users without permission cannot print', () async {
    final c = _controller(groups: _groups, users: const [CheckUser(chk: 'N')]);
    await c.init();
    await pumpEventQueue();

    expect(c.canPrint, isFalse);
    expect(c.canPrintSelected, isFalse);
  });
}
