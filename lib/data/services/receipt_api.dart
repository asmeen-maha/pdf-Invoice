import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_config.dart';
import '../models/check_user.dart';
import '../models/receipt.dart';

/// Talks to the backend PHP endpoint.
class ReceiptApi {
  ReceiptApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
            ));

  final Dio _dio;

  /// Receipts for [year]/[month], grouped by date (oldest first) and sorted by doc number.
  /// Returns `null` when the request fails.
  Future<List<ReceiptGroup>?> getReceipts({required int year, required int month}) async {
    final rows = await _postList({
      'param': 'reprintreceipt',
      'years': '$year',
      'months': '$month',
    });
    if (rows == null) return null;

    final receipts = <Receipt>[];
    for (final row in rows) {
      if (row is Map) {
        receipts.add(Receipt.fromJson(Map<String, dynamic>.from(row)));
      } else {
        debugPrint('Skipped invalid receipt row: $row');
      }
    }
    return groupByDate(receipts);
  }

  /// Print permissions for the current user. Returns `null` when the request fails.
  Future<List<CheckUser>?> checkUser() async {
    final rows = await _postList({'param': 'checkprint'});
    if (rows == null) return null;

    return rows.whereType<Map>().map((row) => CheckUser.fromJson(Map<String, dynamic>.from(row))).toList();
  }

  /// Posts form data and returns the response as a JSON list, or null on any failure.
  Future<List<dynamic>?> _postList(Map<String, dynamic> params) async {
    try {
      final response = await _dio.post(AppConfig.apiUrl, data: FormData.fromMap(params));
      return decodeList(response.data);
    } catch (e) {
      debugPrint('API error (${params['param']}): $e');
      return null;
    }
  }

  /// Accepts a decoded list, or a JSON string (PHP often replies with
  /// `Content-Type: text/html`, so Dio leaves the body as text).
  @visibleForTesting
  static List<dynamic>? decodeList(Object? data) {
    if (data is List) return data;
    if (data is String) {
      final text = data.trim();
      if (text.isEmpty) return const [];
      final decoded = jsonDecode(text);
      if (decoded is List) return decoded;
    }
    throw FormatException('Expected a JSON list but got ${data.runtimeType}');
  }

  @visibleForTesting
  static List<ReceiptGroup> groupByDate(List<Receipt> receipts) {
    final grouped = <String, List<Receipt>>{};
    for (final receipt in receipts) {
      grouped.putIfAbsent(receipt.docDate ?? '', () => []).add(receipt);
    }

    final groups = grouped.entries.map((entry) {
      final sorted = entry.value..sort((a, b) => (a.docNo ?? '').compareTo(b.docNo ?? ''));
      return ReceiptGroup(docDate: entry.key, receipts: sorted);
    }).toList();
    return groups..sort((a, b) => a.docDate.compareTo(b.docDate));
  }
}
