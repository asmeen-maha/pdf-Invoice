class CheckUser {
  String? code;
  String? name;
  String? chk;

  CheckUser({this.code, this.name, this.chk});

  CheckUser.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    name = json['name'];
    chk = json['chk'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['name'] = name;
    data['chk'] = chk;
    return data;
  }
  static List<CheckUser>? fromJsonList(List list) =>list.map((item) => CheckUser.fromJson(item)).toList();
}