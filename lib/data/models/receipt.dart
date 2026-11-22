import 'json_utils.dart';

/// How a receipt was paid, derived from its `accode`.
enum PaymentMethod {
  cash('เงินสด'),
  card('บัตรเครดิต'),
  transfer('โอนเงิน');

  const PaymentMethod(this.label);

  final String label;

  static PaymentMethod fromAcCode(String? acCode) => switch (acCode) {
        '111' => PaymentMethod.cash,
        '114' => PaymentMethod.card,
        _ => PaymentMethod.transfer,
      };
}

/// Receipts that share the same document date. Totals are computed once.
class ReceiptGroup {
  ReceiptGroup({required this.docDate, required List<Receipt> receipts})
      : receipts = List.unmodifiable(receipts),
        date = DateTime.tryParse(docDate),
        totalAmount = receipts.fold(0, (sum, r) => sum + r.amountValue),
        totalVat = receipts.fold(0, (sum, r) => sum + r.vatAmount);

  final String docDate;
  final List<Receipt> receipts;

  /// Null when the API sent a date that cannot be parsed.
  final DateTime? date;
  final double totalAmount;
  final double totalVat;

  int get count => receipts.length;
}

/// A single receipt row returned by the `reprintreceipt` API.
class Receipt {
  final String? docNo;
  final String? docDate;
  final String? extCode;
  final String? agentName;
  final String? address;
  final String? trDate;
  final String? issue;
  final String? receiveType;
  final String? trRunNo;
  final String? acCode;
  final String? referNo;
  final String? amount;
  final String? acReportName;
  final String? bankAccount;

  const Receipt({
    this.docNo,
    this.docDate,
    this.extCode,
    this.agentName,
    this.address,
    this.trDate,
    this.issue,
    this.receiveType,
    this.trRunNo,
    this.acCode,
    this.referNo,
    this.amount,
    this.acReportName,
    this.bankAccount,
  });

  /// VAT rate in percent. Amounts from the API already include VAT.
  static const double vatRate = 7;

  /// Amount as a number. Accepts `1070`, `"1070.00"` and `"1,070.00"`; 0 when invalid.
  double get amountValue => double.tryParse((amount ?? '').replaceAll(',', '')) ?? 0;

  double get vatAmount => amountValue * vatRate / (100 + vatRate);

  double get netAmount => amountValue - vatAmount;

  PaymentMethod get paymentMethod => PaymentMethod.fromAcCode(acCode);

  /// Null when [docDate] is missing or cannot be parsed.
  DateTime? get date => docDate == null ? null : DateTime.tryParse(docDate!);

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
        docNo: jsonString(json['docno']),
        docDate: jsonString(json['docdate']),
        extCode: jsonString(json['extcode']),
        agentName: jsonString(json['agentname']),
        address: jsonString(json['address']),
        trDate: jsonString(json['trdate']),
        issue: jsonString(json['issue']),
        receiveType: jsonString(json['recivetype']),
        trRunNo: jsonString(json['trrunno']),
        acCode: jsonString(json['accode']),
        referNo: jsonString(json['referno']),
        amount: jsonString(json['amount']),
        acReportName: jsonString(json['AcReportName']),
        bankAccount: jsonString(json['bank_account']),
      );

  Map<String, dynamic> toJson() => {
        'docno': docNo,
        'docdate': docDate,
        'extcode': extCode,
        'agentname': agentName,
        'address': address,
        'trdate': trDate,
        'issue': issue,
        'recivetype': receiveType,
        'trrunno': trRunNo,
        'accode': acCode,
        'referno': referNo,
        'amount': amount,
        'AcReportName': acReportName,
        'bank_account': bankAccount,
      };
}
