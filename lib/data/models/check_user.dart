import 'json_utils.dart';

/// User permission returned by the `checkprint` API.
class CheckUser {
  final String? code;
  final String? name;
  final String? chk;

  const CheckUser({this.code, this.name, this.chk});

  /// The user may print when `chk` is `Y`.
  bool get canPrint => chk?.toUpperCase() == 'Y';

  factory CheckUser.fromJson(Map<String, dynamic> json) => CheckUser(
        code: jsonString(json['code']),
        name: jsonString(json['name']),
        chk: jsonString(json['chk']),
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'chk': chk,
      };
}
