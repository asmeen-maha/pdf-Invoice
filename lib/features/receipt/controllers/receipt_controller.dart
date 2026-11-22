import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:printing/printing.dart';

import '../../../data/models/check_user.dart';
import '../../../data/models/receipt.dart';
import '../../../data/services/receipt_api.dart';
import '../reports/receipt_pdf.dart';

typedef PdfBuilder = Future<Uint8List> Function(Receipt receipt);

/// State and actions for the receipt reprint screen.
///
/// Flow: load a month → auto-select its latest date and first receipt →
/// the user picks another date / receipt → preview, print or download.
class ReceiptController extends ChangeNotifier {
  ReceiptController({ReceiptApi? api, PdfBuilder? pdfBuilder, DateTime Function()? clock})
      : _api = api ?? ReceiptApi(),
        _buildPdf = pdfBuilder ?? ReceiptPdf.generate,
        _usesDefaultPdf = pdfBuilder == null,
        _clock = clock ?? DateTime.now {
    _month = _currentMonth;
    searchController.addListener(_onSearchChanged);
  }

  static final DateTime firstMonth = DateTime(2020, 1);

  /// How many generated PDFs to keep in memory (each is ~50–100 KB).
  static const int _pdfCacheSize = 40;

  final ReceiptApi _api;
  final PdfBuilder _buildPdf;
  final bool _usesDefaultPdf;
  final DateTime Function() _clock;
  final TextEditingController searchController = TextEditingController();

  bool _disposed = false;
  late DateTime _month;
  int _loadToken = 0;

  List<ReceiptGroup> _groups = const [];
  bool _isLoading = true;
  bool _hasError = false;

  CheckUser? _user;
  bool _userLoadFailed = false;

  ReceiptGroup? _selectedGroup;
  List<Receipt> _visibleReceipts = const [];
  Receipt? _selectedReceipt;
  Uint8List? _pdfBytes;
  bool _isGeneratingPdf = false;
  bool _pdfFailed = false;
  bool _isOutputBusy = false;

  // Month summary, computed once per load.
  int _monthCount = 0;
  double _monthTotal = 0;
  double _monthVat = 0;

  /// Generated PDFs, most recently used last. Cleared when the month changes.
  final LinkedHashMap<Receipt, Uint8List> _pdfCache = LinkedHashMap.identity();
  final Map<Receipt, Future<Uint8List>> _pdfInFlight = Map.identity();

  // ---------------------------------------------------------------------------
  // Read-only state
  // ---------------------------------------------------------------------------

  DateTime get month => _month;
  List<ReceiptGroup> get groups => _groups;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  bool get canPrint => _user?.canPrint ?? false;
  bool get userLoadFailed => _userLoadFailed;
  String? get userName => _user?.name;

  ReceiptGroup? get selectedGroup => _selectedGroup;
  Receipt? get selectedReceipt => _selectedReceipt;
  Uint8List? get pdfBytes => _pdfBytes;
  bool get isGeneratingPdf => _isGeneratingPdf;
  bool get pdfFailed => _pdfFailed;
  bool get isOutputBusy => _isOutputBusy;

  bool get canGoPreviousMonth => _month.isAfter(firstMonth);
  bool get canGoNextMonth => _month.isBefore(_currentMonth);

  int get monthCount => _monthCount;
  double get monthTotal => _monthTotal;
  double get monthVat => _monthVat;
  int get activeDays => _groups.length;
  double get averagePerDay => activeDays == 0 ? 0 : _monthCount / activeDays;

  /// Receipts of the selected date, filtered by the search box.
  List<Receipt> get visibleReceipts => _visibleReceipts;

  /// Position of the selected receipt in [visibleReceipts], or -1.
  int get selectedIndex {
    final selected = _selectedReceipt;
    return selected == null ? -1 : _visibleReceipts.indexOf(selected);
  }

  bool get canSelectPrevious => selectedIndex > 0;
  bool get canSelectNext {
    final index = selectedIndex;
    return index >= 0 && index < _visibleReceipts.length - 1;
  }

  bool get canPrintSelected => canPrint && _pdfBytes != null && !_isOutputBusy;

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Future<void> init() {
    if (_usesDefaultPdf) ReceiptPdf.preload().ignore(); // warm up PDF fonts while the API loads
    return Future.wait([_loadUser(), loadReceipts()]);
  }

  Future<void> _loadUser() async {
    final users = await _api.checkUser();
    if (_disposed) return;
    _userLoadFailed = users == null;
    _user = (users == null || users.isEmpty) ? null : users.first;
    _notify();
  }

  Future<void> loadReceipts() async {
    final token = ++_loadToken;
    final month = _month;
    _isLoading = true;
    _hasError = false;
    _notify();

    final groups = await _api.getReceipts(year: month.year, month: month.month);
    if (_disposed || token != _loadToken) return; // a newer request replaced this one

    _setGroups(groups ?? const []);
    _hasError = groups == null;
    _isLoading = false;

    if (_groups.isEmpty) {
      _clearSelection();
      _notify();
    } else {
      selectGroup(_groups.last);
    }
  }

  void _setGroups(List<ReceiptGroup> groups) {
    _groups = groups;
    _monthCount = groups.fold(0, (sum, g) => sum + g.count);
    _monthTotal = groups.fold(0, (sum, g) => sum + g.totalAmount);
    _monthVat = groups.fold(0, (sum, g) => sum + g.totalVat);
    _pdfCache.clear();
    _pdfInFlight.clear();
  }

  // ---------------------------------------------------------------------------
  // Month
  // ---------------------------------------------------------------------------

  void changeMonth(DateTime month) {
    final target = DateTime(month.year, month.month);
    if (target == _month || target.isBefore(firstMonth) || target.isAfter(_currentMonth)) return;

    _month = target;
    _setGroups(const []);
    _clearSelection();
    loadReceipts();
  }

  void previousMonth() => changeMonth(DateTime(_month.year, _month.month - 1));

  void nextMonth() => changeMonth(DateTime(_month.year, _month.month + 1));

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  void selectGroup(ReceiptGroup group) {
    _selectedGroup = group;
    _clearSearch();
    _updateVisible();

    final first = group.receipts.firstOrNull;
    if (first == null) {
      _selectedReceipt = null;
      _pdfBytes = null;
      _notify();
    } else {
      selectReceipt(first);
    }
  }

  Future<void> selectReceipt(Receipt receipt) async {
    if (identical(receipt, _selectedReceipt) && (_pdfBytes != null || _isGeneratingPdf)) return;

    _selectedReceipt = receipt;
    _pdfFailed = false;

    final cached = _pdfCache.remove(receipt);
    if (cached != null) {
      _pdfCache[receipt] = cached; // mark as most recently used
      _pdfBytes = cached;
      _isGeneratingPdf = false;
      _notify();
      _prefetchNext();
      return;
    }

    _pdfBytes = null;
    _isGeneratingPdf = true;
    _notify();

    try {
      final bytes = await _pdfFor(receipt);
      if (_disposed || !identical(receipt, _selectedReceipt)) return;
      _pdfBytes = bytes;
    } catch (e) {
      debugPrint('PDF error: $e');
      if (_disposed || !identical(receipt, _selectedReceipt)) return;
      _pdfFailed = true;
    }
    _isGeneratingPdf = false;
    _notify();
    _prefetchNext();
  }

  void selectPrevious() {
    if (canSelectPrevious) selectReceipt(_visibleReceipts[selectedIndex - 1]);
  }

  void selectNext() {
    if (canSelectNext) selectReceipt(_visibleReceipts[selectedIndex + 1]);
  }

  // ---------------------------------------------------------------------------
  // Output
  // ---------------------------------------------------------------------------

  /// Opens the browser print dialog. Throws if printing fails.
  Future<void> printSelected() => _output(
        (bytes, name) => Printing.layoutPdf(onLayout: (_) async => bytes, name: name),
      );

  /// Downloads the PDF. Throws if the download fails.
  Future<void> downloadSelected() => _output(
        (bytes, name) => Printing.sharePdf(bytes: bytes, filename: '$name.pdf'),
      );

  Future<void> _output(Future<void> Function(Uint8List bytes, String name) action) async {
    final bytes = _pdfBytes;
    if (!canPrint || bytes == null || _isOutputBusy) return;

    _isOutputBusy = true; // blocks double clicks while the dialog opens
    _notify();
    try {
      await action(bytes, _fileName);
    } finally {
      _isOutputBusy = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // PDF cache
  // ---------------------------------------------------------------------------

  /// Returns the PDF for [receipt], sharing one build when called repeatedly.
  Future<Uint8List> _pdfFor(Receipt receipt) {
    final cached = _pdfCache[receipt];
    if (cached != null) return Future.value(cached);

    return _pdfInFlight.putIfAbsent(receipt, () async {
      try {
        final bytes = await _buildPdf(receipt);
        _pdfCache[receipt] = bytes;
        while (_pdfCache.length > _pdfCacheSize) {
          _pdfCache.remove(_pdfCache.keys.first);
        }
        return bytes;
      } finally {
        _pdfInFlight.remove(receipt);
      }
    });
  }

  /// Builds the next receipt's PDF in the background so "next" is instant.
  void _prefetchNext() {
    if (!canSelectNext) return;
    _pdfFor(_visibleReceipts[selectedIndex + 1]).ignore();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  DateTime get _currentMonth {
    final now = _clock();
    return DateTime(now.year, now.month);
  }

  String get _fileName {
    final r = _selectedReceipt;
    final id = (r?.trRunNo ?? r?.docNo ?? 'document').replaceAll(RegExp(r'[^\w\-]'), '_');
    return 'receipt_$id';
  }

  void _updateVisible() {
    final receipts = _selectedGroup?.receipts ?? const <Receipt>[];
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _visibleReceipts = receipts;
      return;
    }

    bool matches(String? value) => (value ?? '').toLowerCase().contains(query);
    _visibleReceipts = receipts.where((r) => matches(r.agentName) || matches(r.trRunNo) || matches(r.docNo)).toList();
  }

  void _onSearchChanged() {
    _updateVisible();
    _notify();
  }

  void _clearSearch() {
    searchController.removeListener(_onSearchChanged);
    searchController.clear();
    searchController.addListener(_onSearchChanged);
  }

  void _clearSelection() {
    _selectedGroup = null;
    _visibleReceipts = const [];
    _selectedReceipt = null;
    _pdfBytes = null;
    _isGeneratingPdf = false;
    _pdfFailed = false;
    _clearSearch();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    searchController.dispose();
    super.dispose();
  }
}
