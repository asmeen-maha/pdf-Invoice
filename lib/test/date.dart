import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthDayListScreen extends StatefulWidget {
  const MonthDayListScreen({Key? key}) : super(key: key);

  @override
  State<MonthDayListScreen> createState() => _MonthDayListScreenState();
}

class _MonthDayListScreenState extends State<MonthDayListScreen> {
  int _selectedMonth = DateTime.now().month; // เดือนที่เลือกเริ่มต้น (ปัจจุบัน)
  int _selectedYear = DateTime.now().year;   // ปีที่เลือก (ใช้คำนวณ leap year)
  List<int> _daysInMonth = [];

  @override
  void initState() {
    super.initState();
    _updateDays();
  }

  void _updateDays() {
    // หาจำนวนวันในเดือนที่เลือก
    final daysCount = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    setState(() {
      _daysInMonth = List.generate(daysCount, (i) => i + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final months = List.generate(12, (i) => i + 1);

    return Scaffold(
      appBar: AppBar(title: const Text('เลือกเดือนเพื่อแสดงวันที่')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // เลือกเดือน
            DropdownButton<int>(
              value: _selectedMonth,
              items: months.map((month) {
                return DropdownMenuItem(
                  value: month,
                  child: Text(DateFormat.MMMM('th_TH').format(DateTime(_selectedYear, month))),
                );
              }).toList(),
              onChanged: (month) {
                if (month != null) {
                  setState(() {
                    _selectedMonth = month;
                  });
                  _updateDays();
                }
              },
            ),

            const SizedBox(height: 16),

            // แสดง List วันที่
            Expanded(
              child: ListView.builder(
                itemCount: _daysInMonth.length,
                itemBuilder: (context, index) {
                  final day = _daysInMonth[index];
                  return ListTile(
                    title: Text('วันที่ $day ${DateFormat.MMMM('th_TH').format(DateTime(_selectedYear, _selectedMonth))}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
