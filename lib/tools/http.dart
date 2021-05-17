// import 'dart:io';
// import 'dart:convert';
import 'dart:convert';

import 'package:http/http.dart' as http;

void getJson(String url, void Function(Map) resultCallback) {
  http.get(Uri.parse(url)).then((response) => resultCallback(jsonDecode(response.body)));
  /*
  HttpClient client = new HttpClient();
  client.getUrl(
      Uri.parse(url)
  ).then((HttpClientRequest request) => request.close())
      .then((HttpClientResponse response) {
    response.transform(utf8.decoder).listen((data) {
      if (null != resultCallback) {
        resultCallback(jsonDecode(data));
      }
    });
  });
   */
}
