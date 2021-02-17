import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class GetAlpha2Code {
  static Future<String> getCode(String country) async {
    var url = 'https://restcountries.eu/rest/v2/name/';

    var response = await http.get("$url$country");

    // print('Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body);

      return jsonResponse[0]["alpha2Code"];
    }

    return null;
  }
}
