import 'dart:io';
import 'dart:convert';

void getJson(String url, void Function(Map) resultCallback) {
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
}
