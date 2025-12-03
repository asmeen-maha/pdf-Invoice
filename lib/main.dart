import 'package:flutter/material.dart';
import 'package:pdf_invoice/page/home.dart';

void main() {
  // String token = Uri.base.queryParameters["token"] ?? "";
  // print('token >> $token');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'PDF Invoice',
      home: Home(),
    );
  }
}