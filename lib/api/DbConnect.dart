import 'package:dio/dio.dart';
import '../model/mdChkUser.dart';
import '../model/mdReceipt.dart';

class Dbconnect {
  String domain = 'http://172.2.100.14/clientele_cm/marketing.php';

  Future<List<Receipt>?> getReceipt({required String year, required String month}) async {
    List<dynamic> groupByDocDate(List<dynamic> data) {
      Map<String, List<dynamic>> grouped = {};

      for (var item in data) {
        String docdate = item['docdate'];

        if (!grouped.containsKey(docdate)) {
          grouped[docdate] = [];
        }

        var detail = Map<String, dynamic>.from(item);
        // detail.remove('docdate');

        grouped[docdate]!.add(detail);
      }

      return grouped.entries.map((entry) {
        return {
          "docdate": entry.key,
          "detail": entry.value,
        };
      }).toList();
    }


    FormData formData = FormData.fromMap({
      "param": "reprintreceipt",
      "years": year,
      "months": month
    });
    try {
      Response response = await Dio().post(domain, data: formData);
      if (response.statusCode == 200) {
        var rewData = groupByDocDate(response.data);
        var receipt = Receipt.fromJsonList(rewData);
        // print(response.data);
        // print('receipt oK! >>$rewData');
        return receipt;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<List<CheckUser>?> checkUser() async {
    FormData formData = FormData.fromMap({
      "param": "checkprint",
    });
    try {
      Response response = await Dio().post(domain, data: formData);
      if (response.statusCode == 200) {
        var user = CheckUser.fromJsonList(response.data);
        // print(response.data);
        // print('user oK! >>$rewData');
        return user;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }
}