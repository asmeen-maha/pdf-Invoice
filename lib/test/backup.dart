/* import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:pdf_invoice/api/DbConnect.dart';
import 'package:pdf_invoice/font/appColor.dart';
import 'package:pdf_invoice/font/appFonts.dart';
import 'package:pdf_invoice/report/invoice.dart';
import 'package:pdf_invoice/util/dateformat.dart';
import 'package:printing/printing.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import '../model/mdReceipt.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _monthController = TextEditingController(text: DateFormat('MMMM yyyy').format(DateTime.now()));
  late DateTime _selectedDate;
  Uint8List? _report;
  bool _reportload = false;

  List<int> _daysInMonth = [];
  int? dateSelected;
  int? reportSelected;
  String dateSeletedStr = '';

  List<Receipt> receipData = [];

  @override
  void initState() {
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectDate();
    });
    _dBReceipt();

    super.initState();
  }

  @override
  void dispose() {
    _monthController.dispose();

    super.dispose();
  }

  Future<void> _dBReceipt() async {
    await Dbconnect().getReceipt().then((onValue) {
      if(onValue != null) {
        receipData = onValue;
      }
      print('data >> $receipData');
    });
    
  }

  Future<void> selectDate() async {
    final picked = await showMonthPicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime(DateTime.now().year, DateTime.now().month),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        final now = DateTime.now();
        int daysCount;

        if (picked.year == now.year && picked.month == now.month) {
          daysCount = now.day;
        } else {
          daysCount = DateUtils.getDaysInMonth(picked.year, picked.month);
        }
        _daysInMonth = List.generate(daysCount, (i) => i + 1);
        _monthController.text = DateFormat('MMMM yyyy').format(picked);
        dateSelected = null;
        reportSelected = null;
        dateSeletedStr = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pay Advance', style: TextStyle(fontSize: width * .012, fontFamily: AppFonts.pgVim, color: Colors.white)),
            Text('V0.0.1', style: TextStyle(fontFamily: AppFonts.traJanPro, color: AppColors.white, fontSize: width * .008)),
          ],
        ),
        backgroundColor: AppColors.pinkcm
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: width * .11,
            // height: height * .9,
            padding: const EdgeInsets.all(5),
            /* decoration: BoxDecoration(
              border: Border.all(width: .5, color: Colors.black),
              borderRadius: BorderRadius.circular(5),
            ), */
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _selectDate(width, height),
                  ],
                ),
                SizedBox(height: height *.01),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('วันที่', style: TextStyle(fontSize: width * .01, fontFamily: AppFonts.pgVim, color: Colors.black))
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _daysInMonth.length,
                    itemBuilder: (context, index) {
                      final day = _daysInMonth[index];
                      Color bgColor = day != dateSelected ? const Color.fromARGB(255, 252,228,236) : AppColors.darkPink; //const Color.fromARGB(255, 244, 143, 177)
                      Color textColor = day != dateSelected ? Colors.black : Colors.white; //const Color.fromARGB(255, 85, 4, 31)
      
                      return InkWell(
                        onTap: (){
                          setState(() {
                            dateSelected = day;
                            dateSeletedStr = dateformat(date: DateTime(_selectedDate.year, _selectedDate.month, day), type: 'dp');
                          });
                        },
                        child: Card(
                          color: bgColor,
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Text(
                              dateformat(date: DateTime(_selectedDate.year, _selectedDate.month, day), type: 'dp'),
                              style: TextStyle(fontSize: width * .008, fontFamily: AppFonts.pgVim, color: textColor),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                ),
              ],
            ),
          ),
          Container(
            width: width * .5,
            // height: height * .9,
            padding: const EdgeInsets.all(5),
            /* decoration: BoxDecoration(
              border: Border.all(width: .5, color: Colors.black),
              borderRadius: BorderRadius.circular(5),
            ), */
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('รายการใบเสร็จรับเงิน $dateSeletedStr', style: TextStyle(fontSize: width * .01, fontFamily: AppFonts.pgVim, color: Colors.black))
                ),
                /* Container(
                  width: width * .05,
                  decoration: BoxDecoration(
                    border: Border.all(width: .5, color: Colors.black),
                  ),
                  child: Text('Items', style: TextStyle(fontSize: width * .009, fontFamily: AppFonts.pgVim, color: Colors.black)),
                ) */
                SizedBox(height: height * .01),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    header('Items', width, width * .03),
                    header('Docdate',width,  width * .055),
                    header('Docno',width,  width * .055),
                    header('Name',width,  width * .29),
                    header('Amount',width,  width * .055),
                  ],
                ),
                const Divider(color: Colors.grey),
                Expanded(
                  child: ListView.builder(
                    itemCount: _daysInMonth.length,
                    itemBuilder: (context, index) {
                      final day = _daysInMonth[index];
                      Color bgColor = day != reportSelected ? const Color.fromARGB(255, 252,228,236) : AppColors.darkPink; //const Color.fromARGB(255, 244, 143, 177)
                      Color textColor = day != reportSelected ? Colors.black : Colors.white; //const Color.fromARGB(255, 85, 4, 31)
      
                      return InkWell(
                        onTap: () {
                          Invoice().generateInvoice().then((onValue) {
                            setState(() {
                              reportSelected = day;
                              _report = onValue;
                              _reportload = true;
                            });
                          });
                        },
                        child: Card(
                          color: bgColor,
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    body('${index + 1}', width, width * .025, AppFonts.pgVim, textColor),
                                    body(dateformat(date: DateTime(_selectedDate.year, _selectedDate.month, day), type: 'dp'), width,  width * .055, AppFonts.pgVim, textColor),
                                    body('CP68011146',width,  width * .055, AppFonts.pgVim, textColor),
                                    Text('เงินสด', style: TextStyle(fontSize: width * .008, fontFamily:  AppFonts.pgVim, color: textColor)),

                                  ],
                                ),
                                body(formatter.format(76700), width,  width * .045, AppFonts.traJanProBold, textColor, alignment: Alignment.centerRight)
                              ],
                            )
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: width * .5,
              // height: height * .9,
              padding: const EdgeInsets.all(5),
              child: _reportload ? PdfPreview(
                // pdfFileName: 'Ticket Report ($_title) ${_codeChk ? '($_saleCode)' : ''} ${dateformat(date: _saleDate, type: 'dn')}',
                allowPrinting: true, 
                allowSharing: true,
                canDebug: false,
                canChangePageFormat: false, //true
                canChangeOrientation: false,
                actionBarTheme: PdfActionBarTheme(
                  backgroundColor: AppColors.darkPink,
                ),
                dynamicLayout: true,
                loadingWidget: LoadingAnimationWidget.hexagonDots(color: AppColors.pinkcm, size: width * .045),
                build: (format) => _report!,
                onError: (context, error) {
                  return Center(child: Text("เกิดข้อผิดพลาด", style: TextStyle(fontSize: width * .015, fontFamily: AppFonts.pgVim)));
                },
              ) : Center(child: Text("ไม่พบข้อมูล", style: TextStyle(fontSize: width * .02, fontFamily: AppFonts.pgVim, color: Colors.black))),
            )
          )
        ],
      )
    );
  }

  Widget header(String label, double width, double box) {
    return Container(
      width: box,
      alignment: label == 'Amount' ? Alignment.centerRight : Alignment.centerLeft,
      /* decoration: BoxDecoration(
        border: Border.all(width: .5, color: Colors.black),
      ), */
      child: Text(label, style: TextStyle(fontSize: width * .009, fontFamily: AppFonts.pgVim, color: Colors.black)),
    );
  }

  Widget body(String value, double width, double box, String fontFamily, Color textColor, {Alignment alignment = Alignment.centerLeft}) {
    return Container(
      width: box,
      alignment: alignment,
      /* decoration: BoxDecoration(
        border: Border.all(width: .5, color: Colors.black),
      ), */
      child: Text(value, style: TextStyle(fontSize: width * .008, fontFamily:  fontFamily, color: textColor)),
    );
  }

  Widget _selectDate(double width, double height) {
    return Container(
      width: width * .1,
      margin: EdgeInsets.only(top: height * .01, bottom: height * .01),
      child: TextFormField(
        controller: _monthController,
        readOnly: true,
        style: TextStyle(
          fontSize: width * .009,
          color: Colors.black,
          fontFamily: AppFonts.pgVim,
        ),
        decoration: InputDecoration(
          labelText: 'เลือกเดือน',
          labelStyle: TextStyle(
            fontSize: width * .01,
            color: Colors.pink.shade700,
            fontFamily: AppFonts.pgVim,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.calendar_month_rounded, color: Colors.pink.shade700),
            onPressed: selectDate,
          ),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.pink, width: 1.5),
          ),
        ),
        onTap: selectDate,
      ),
    );
  }
} */