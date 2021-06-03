import 'dart:async';
import '../tools/http.dart';

class Api {
  static const String key = 'SjXrn5m8_qaasxE5F';
  static const String baseUrl = 'https://api.seniverse.com/v3';
  
  static Future<Map> getNowWeather(String city, { String unit = 'c' }) {
    Completer completer = Completer<Map>();
    String uri = baseUrl + '/weather/now.json?key=$key&location=$city&language=zh-Hans&unit=$unit';
    getJson(uri, (Map value) {
      completer.complete(value);
    });
    return completer.future;
  }

  static Future<Map> getRecentWeather(String city, { int days = 3 }) {
    Completer completer = Completer<Map>();
    String uri = baseUrl + '/weather/daily.json?key=$key&location=$city&language=zh-Hans&unit=c&start=-1&days=$days';
    getJson(uri, (Map value) {
      completer.complete(value);
    });
    return completer.future;
  }

  static Future<Map> getSuggestion(String city) {
    Completer completer = Completer<Map>();
    String uri = baseUrl + '/life/suggestion.json?key=$key&location=wuxi&language=zh-Hans';
    getJson(uri, (Map value) {
      completer.complete(value);
    });
    return completer.future;
  }

  static Future<Map> getLocationByNetwork() {
    Completer completer = Completer<Map>();
    String uri = 'https://apis.map.qq.com/ws/location/v1/ip?key=3BFBZ-ZKD3X-LW54A-ZT76D-E7AHO-4RBD5&&output=json';
    getJson(uri, (Map value) {
      completer.complete(value);
    });
    return completer.future;
  }

}

