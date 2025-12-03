import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:pdf_invoice/api/DbConnect.dart';
import 'package:pdf_invoice/font/appColor.dart';
import 'package:pdf_invoice/font/appFonts.dart';
import 'package:pdf_invoice/model/mdChkUser.dart';
import 'package:pdf_invoice/report/invoice.dart';
import 'package:pdf_invoice/util/dateformat.dart';
import 'package:printing/printing.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import '../model/mdReceipt.dart';
import 'dart:html' as html;
import 'dart:js' as js;

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

  String? dateSelected;
  String? reportSelected;
  String dateSeletedStr = '';

  List<Receipt> receipData = [];
  List<Detail>? receiptDetail;
  bool _loading = false;

  List<CheckUser> _user = [];

  @override
  void initState() {
    _selectedDate = DateTime.now();
    /* WidgetsBinding.instance.addPostFrameCallback((_) {
      selectDate();
    }); */
    _dBCheckUser();
    _dBReceipt(_selectedDate.month.toString(), _selectedDate.year.toString());
    
    super.initState();
  }

  @override
  void dispose() {
    _monthController.dispose();

    super.dispose();
  }

  void printDirectly(Uint8List pdfBytes) {
    final blob = html.Blob([pdfBytes], "application/pdf");
    final url = html.Url.createObjectUrlFromBlob(blob);

    js.context.callMethod("autoPrint", [url]);
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _dBReceipt(String month, String year) async {
    await Dbconnect().getReceipt(month: month, year: year).then((onValue) {
      if(onValue != null) {
        setState(() {
          receipData = onValue;
          _loading = true;
        });
      }
      // print('data >> $receipData');
    });
  }

  Future<void> _dBCheckUser() async {
    await Dbconnect().checkUser().then((onValue) {
      if(onValue != null) {
        _user = onValue;
      }
      // print('user >> $_user');
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
        _loading = false;
        _dBReceipt(picked.month.toString(), picked.year.toString());
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
            Text('ใบเสร็จรับเงิน', style: TextStyle(fontSize: width * .012, fontFamily: AppFonts.pgVim, color: Colors.white)),
            Text('V0.0.6', style: TextStyle(fontFamily: AppFonts.traJanPro, color: AppColors.white, fontSize: width * .008)),
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
                Center(
                  child: _selectDate(width, height)
                ),
                SizedBox(height: height *.01), 
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('วันที่', style: TextStyle(fontSize: width * .01, fontFamily: AppFonts.pgVim, color: Colors.black))
                ),
                _loading ? Expanded(
                  child: ListView.builder(
                    itemCount: receipData.length,
                    itemBuilder: (context, index) {
                      final day = receipData[index];
                      Color bgColor = day.docdate != dateSelected ? const Color.fromARGB(255, 252,228,236) : AppColors.darkPink; //const Color.fromARGB(255, 244, 143, 177)
                      Color textColor = day.docdate != dateSelected ? Colors.black : Colors.white; //const Color.fromARGB(255, 85, 4, 31)
      
                      return InkWell(
                        onTap: (){
                          setState(() {
                            dateSelected = day.docdate;
                            dateSeletedStr = dateformat(date: DateTime.parse(day.docdate!), type: 'dp');
                            receiptDetail = day.detail!..sort((a, b) => a.docno!.compareTo(b.docno!));
                            _reportload = false;
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
                              dateformat(date: DateTime.parse(day.docdate!), type: 'dp'),
                              style: TextStyle(fontSize: width * .0085, fontFamily: AppFonts.pgVim, color: textColor),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                ) : Center(child: LoadingAnimationWidget.staggeredDotsWave(color: AppColors.pinkcm, size: width * .02)),
              ],
            ),
          ),
          Container(
            width: width * .5, //.5
            // height: height * .9,
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('รายการใบเสร็จรับเงิน $dateSeletedStr', style: TextStyle(fontSize: width * .01, fontFamily: AppFonts.pgVim, color: Colors.black))
                ),
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
                if(receiptDetail != null) Expanded(
                  child: ListView.builder(
                    itemCount: receiptDetail!.length,
                    itemBuilder: (context, index) {
                      final day = receiptDetail![index];
                      Color bgColor = day.docno != reportSelected ? const Color.fromARGB(255, 252,228,236) : AppColors.darkPink; //const Color.fromARGB(255, 244, 143, 177)
                      Color textColor = day.docno != reportSelected ? Colors.black : Colors.white; //const Color.fromARGB(255, 85, 4, 31)
      
                      return InkWell(
                        onTap: () {
                          Invoice().generateInvoice(data: day).then((onValue) {
                            setState(() {
                              reportSelected = day.docno;
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    body('${index + 1}', width, width * .02, AppFonts.pgVim, textColor),
                                    body(dateformat(date: DateTime.parse(day.docdate!), type: 'dp'), width,  width * .057, AppFonts.pgVim, textColor),
                                    body(day.trrunno ?? '',width,  width * .058, AppFonts.pgVim, textColor),
                                    body(day.agentname ?? '', width,  width * .3, AppFonts.pgVim, textColor)
                                  ],
                                ),
                                Text(formatter.format(double.parse(day.amount ?? '0')), style: TextStyle(fontSize: width * .008, fontFamily:  AppFonts.traJanProBold, color: textColor)),
                                /* IconButton(
                                  onPressed: () async {
                                    await Invoice().generateInvoice(data: day).then((onValue) {
                                      printDirectly(onValue);
                                    });
                                  },
                                  icon: Icon(Icons.print_rounded, color: AppColors.darkPink)
                                ) */
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
                allowPrinting: (_user.isNotEmpty == true && _user[0].chk == 'Y') ? true : false,
                allowSharing: false,
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

  Widget body(String value, double width, double box, String fontFamily, Color textColor) {
    return SizedBox(
      width: box,
      child: Text(
        value, 
        style: TextStyle(fontSize: width * .008, fontFamily:  fontFamily, color: textColor),
      ),
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
}