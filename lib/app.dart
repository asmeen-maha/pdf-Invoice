import 'package:flutter/material.dart';

import 'core/constants/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/receipt/pages/receipt_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ReceiptPage(),
    );
  }
}
