import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tools/locate.dart';
import '../sdk/api.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import '../pages/city_list.dart';

enum ColorTheme {
  light,
  dark
}

class Weather {
  bool isLocate;
  String city;
  String code;
  String text;
  String temperature;
  String update;
  List<Daily> recent;
  Suggestion suggestion;
  Weather(this.isLocate, this.city, this.code, this.text, this.temperature, this.update, this.recent, this.suggestion);
}

class Daily {
  String date;
  String textDay;
  String codeDay;
  String textNight;
  String codeNight;
  String high;
  String low;
  String rainfall;
  String precip;
  String windDirection;
  String windDirectionDegree;
  String windSpeed;
  String windScale;
  String humidity;
  Daily(
      this.date,
      this.textDay,
      this.codeDay,
      this.textNight,
      this.codeNight,
      this.high,
      this.low,
      this.rainfall,
      this.precip,
      this.windDirection,
      this.windDirectionDegree,
      this.windSpeed,
      this.windScale,
      this.humidity,
      );

  static Daily fromMap(Map map) {
    return Daily(
      map['date'],
      map['text_day'],
      map['code_day'],
      map['text_night'],
      map['code_night'],
      map['high'],
      map['low'],
      map['rainfall'],
      map['precip'],
      map['wind_direction'],
      map['wind_direction_degree'],
      map['wind_speed'],
      map['wind_scale'],
      map['humidity']
    );
  }
}

class Suggestion {
  SuggestionInfo carWashing;
  SuggestionInfo dressing;
  SuggestionInfo flu;
  SuggestionInfo sport;
  SuggestionInfo travel;
  SuggestionInfo uv;
  Suggestion(this.carWashing, this.dressing, this.flu, this.sport, this.travel, this.uv);
}

class SuggestionInfo {
  String brief;
  String details;
  SuggestionInfo();
}

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HomeState();
}

class HomeState extends State<Home> {
  Map<String, Object> _locationResult;
  Locate _locate;
  StreamSubscription<Map<String, Object>> _listener;
  String _city = '';
  ColorTheme _colorTheme = ColorTheme.light;
  List<Weather> cities = [];
  PageController _pageController;
  bool padding = false;
  int page = -1;
  final Duration pageControllerDuration = Duration(milliseconds: 400);
  final Curve pageControllerCurve = Curves.bounceInOut;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    if (kIsWeb) {
      return;
    }

    if (Platform.isIOS || Platform.isAndroid) {

      _locate = Locate();

      /// 动态申请定位权限
      requestPermission();

      ///iOS 获取native精度类型
      if (Platform.isIOS) {
        _locate.requestAccuracyAuthorization();
      }

      ///注册定位结果监听
      _listener = _locate.addListener(onLocate);
    }
  }

  void onLocate(value) {
    if (_locationResult != null && _locationResult['city'] != '') {
      // _province = _locationResult['province'];
      _city = _locationResult['city'];
      _getNowWeather(true);
      _locate.stopLocation();
      _listener.cancel();
    }
    _locationResult = value;
    setState(() {});
  }

  int findCity(String city) {
    return cities.indexWhere((Weather w) => w.city == city);
  }

  void showErr(String err) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Colors.red,
        )
    );
  }

  void _getNowWeather(bool isLocate) async {
    int index = findCity(_city);
    if (index == -1) {
      setState(() {
        padding = true;
      });
      Map nowWeather = await Api.getNowWeather(_city);
      if (nowWeather == null) {
        showErr('数据获取失败');
        return;
      }
      Map now = nowWeather['results'][0]['now'];

      Map recentWeather = await Api.getRecentWeather(_city);
      List<Daily> recent = [];
      for (final Map item in recentWeather['results'][0]['daily']) {
        recent.add(
          Daily.fromMap(item)
        );
      }

      Map lifeSuggestion = await Api.getSuggestion(_city);
      Map suggestionMap = lifeSuggestion['results'][0]['suggestion'];
      Suggestion suggestion = Suggestion(
        SuggestionInfo()..brief = suggestionMap['car_washing']['brief']..details = suggestionMap['car_washing']['details'],
        SuggestionInfo()..brief = suggestionMap['dressing']['brief']..details = suggestionMap['dressing']['details'],
        SuggestionInfo()..brief = suggestionMap['flu']['brief']..details = suggestionMap['flu']['details'],
        SuggestionInfo()..brief = suggestionMap['sport']['brief']..details = suggestionMap['sport']['details'],
        SuggestionInfo()..brief = suggestionMap['travel']['brief']..details = suggestionMap['travel']['details'],
        SuggestionInfo()..brief = suggestionMap['travel']['brief']..details = suggestionMap['travel']['details'],
      );
      cities.add(
          Weather(isLocate, _city, now['code'], now['text'], now['temperature'], nowWeather['results'][0]['last_update'], recent, suggestion)
      );
      padding = false;
      if (isLocate) {
        page = 0;
      }
      toCity(cities.length - 1);
    }
    else {
      toCity(index);
    }
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();

    _listener.cancel(); // 取消订阅的流
    ///销毁定位实例
    _locate.dispose();
  }

  void _showCityList() {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext builder) => CityList(
      onSetCity: (String _) {
        Navigator.pop(context);
        _city = _;
        _getNowWeather(false);
      },
    )));
    // showModalBottomSheet(
    //     context: context,
    //     builder: (BuildContext builder) => CityList()
    // );
  }

  void toCity(int page) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _pageController?.animateToPage(page, duration: pageControllerDuration, curve: pageControllerCurve);
    });
  }

  void removeCity(int index) {
    page = index - 1;
    _pageController.previousPage(duration: pageControllerDuration, curve: pageControllerCurve);
    Future.delayed(pageControllerDuration, () {
      cities.removeAt(index);
      setState(() {});
    });
  }

  Widget infoCell(String title, String value, TextTheme textTheme, { double width = 80.0, double height = 60.0 }) {
    return Container(
      padding: EdgeInsets.all(5.0),
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(
          width: .3,
          color: Colors.grey
        )
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: textTheme.subtitle1),
          Text(value, style: textTheme.bodyText2.copyWith(color: Theme.of(context).primaryColor))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color _textColor = _colorTheme == ColorTheme.dark ? Colors.white : Colors.black;
    SystemChrome.setSystemUIOverlayStyle(_colorTheme == ColorTheme.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);
    return Scaffold(
      extendBody: true,
      body: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        constraints: BoxConstraints.expand(),
        color: _colorTheme == ColorTheme.dark ? Colors.black : Colors.white,
        child: Theme(
          data: Theme.of(context).copyWith(
              textTheme: TextTheme(
                headline1: TextStyle(color: _textColor, fontSize: 60.0),
                bodyText1: TextStyle(color: _textColor, fontSize: 20.0),
                bodyText2: TextStyle(color: _textColor, fontSize: 16.0),
                subtitle1: TextStyle(color: Colors.grey, fontSize: 12.0)
              )
          ),
          child: Builder(
            builder: (BuildContext context) {
              return SafeArea(
                child: Stack(
                  children: [
                    cities.length > 0 ? PageView.builder(
                      itemCount: cities.length,
                      controller: _pageController,
                      onPageChanged: (int _) {
                        page = _;
                        setState(() {});
                      },
                      itemBuilder: (BuildContext context, int index) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Offstage(
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.location_on,
                                            ),
                                            color: Theme.of(context).primaryColor,
                                            onPressed: () {},
                                          ),
                                          offstage: !cities[index].isLocate,
                                        ),
                                        Text(cities[index].city, style: Theme.of(context).textTheme.bodyText1),
                                        Offstage(
                                          child: IconButton(
                                              icon: Icon(Icons.delete_forever_rounded),
                                              color: Colors.red,
                                              onPressed: () => removeCity(index)
                                          ),
                                          offstage: cities[index].isLocate,
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                margin: EdgeInsets.all(10.0),
                              ),
                            ),
                            Container(
                              child: Column(
                                children: [
                                  Container(
                                    width: math.min(MediaQuery.of(context).size.width, 300.0),
                                    margin: EdgeInsets.symmetric(vertical: 40.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/icons/${_colorTheme == ColorTheme.dark ? 'white' : 'black'}/${cities[index].code}@2x.png',
                                              width: 80.0,
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(left: 5.0),
                                              child: Text(cities[index].text, style: Theme.of(context).textTheme.headline1.copyWith(fontSize: 40.0)),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(cities[index].temperature, style: Theme.of(context).textTheme.headline1),
                                            Text('℃', style: Theme.of(context).textTheme.bodyText1)
                                          ],
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.ideographic,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Scrollbar(
                                      child: ListView(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(10.0),
                                            child: Text('近日天气', style: Theme.of(context).textTheme.subtitle1),
                                          ),
                                          Container(
                                            child: Scrollbar(
                                              child: SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: Column(
                                                  children: [
                                                    for (final Daily daily in cities[index].recent) Container(
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          infoCell('日期', daily.date, Theme.of(context).textTheme, width: 120.0),
                                                          Container(
                                                            padding: EdgeInsets.all(5.0),
                                                            width: 90.0,
                                                            height: 60.0,
                                                            decoration: BoxDecoration(
                                                                border: Border.all(
                                                                    width: .3,
                                                                    color: Colors.grey
                                                                )
                                                            ),
                                                            child: Column(
                                                              children: [
                                                                Text('白天', style: Theme.of(context).textTheme.subtitle1),
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  children: [
                                                                    Image.asset(
                                                                      'assets/icons/${_colorTheme == ColorTheme.dark ? 'white' : 'black'}/${daily.codeDay}@2x.png',
                                                                      width: 25.0,
                                                                    ),
                                                                    Text(daily.textDay, style: Theme.of(context).textTheme.bodyText2.copyWith(color: Theme.of(context).primaryColor)),
                                                                  ],
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: EdgeInsets.all(5.0),
                                                            width: 90.0,
                                                            height: 60.0,
                                                            decoration: BoxDecoration(
                                                                border: Border.all(
                                                                    width: .3,
                                                                    color: Colors.grey
                                                                )
                                                            ),
                                                            child: Column(
                                                              children: [
                                                                Text('夜间', style: Theme.of(context).textTheme.subtitle1),
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  children: [
                                                                    Image.asset(
                                                                      'assets/icons/${_colorTheme == ColorTheme.dark ? 'white' : 'black'}/${daily.codeNight}@2x.png',
                                                                      width: 25.0,
                                                                    ),
                                                                    Text(daily.textNight, style: Theme.of(context).textTheme.bodyText2.copyWith(color: Theme.of(context).primaryColor)),
                                                                  ],
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                          infoCell('最高', daily.high + '℃', Theme.of(context).textTheme),
                                                          infoCell('最低', daily.low + '℃', Theme.of(context).textTheme),
                                                          infoCell('降雨量', daily.rainfall + '毫米', Theme.of(context).textTheme),
                                                          infoCell('降雨概率', ((double.parse(daily.precip) * 100).round()).toString() + '%', Theme.of(context).textTheme),
                                                          infoCell('风向', daily.windDirection, Theme.of(context).textTheme, width: 120.0),
                                                          infoCell('风向角度', daily.windDirectionDegree + '°', Theme.of(context).textTheme),
                                                          infoCell('风速', daily.windSpeed + 'km/h', Theme.of(context).textTheme, width: 100.0),
                                                          infoCell('风力等级', daily.windScale + '级', Theme.of(context).textTheme),
                                                          infoCell('相对湿度', daily.humidity + '%', Theme.of(context).textTheme),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            width: double.maxFinite,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10.0
                                            ),
                                          ),
                                          Container(
                                              padding: EdgeInsets.all(10.0),
                                              child: Text('生活指数', style: Theme.of(context).textTheme.subtitle1)
                                          ),
                                          Container(
                                            child: LayoutBuilder(
                                              builder: (BuildContext context, BoxConstraints constraints) {
                                                return Wrap(
                                                  children: [
                                                    infoCell('洗车', cities[index].suggestion.carWashing.brief, Theme.of(context).textTheme, width: constraints.maxWidth / 3),
                                                    infoCell('穿衣', cities[index].suggestion.dressing.brief, Theme.of(context).textTheme, width: constraints.maxWidth / 3),
                                                    infoCell('流感', cities[index].suggestion.flu.brief, Theme.of(context).textTheme, width: constraints.maxWidth / 3),
                                                    infoCell('运动', cities[index].suggestion.sport.brief, Theme.of(context).textTheme, width: constraints.maxWidth / 3),
                                                    infoCell('旅行', cities[index].suggestion.travel.brief, Theme.of(context).textTheme, width: constraints.maxWidth / 3),
                                                    infoCell('紫外线', cities[index].suggestion.uv.brief, Theme.of(context).textTheme, width: constraints.maxWidth / 3),
                                                  ],
                                                );
                                              },
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10.0
                                            ),
                                          )
                                        ],
                                      ),
                                    )
                                  )
                                ],
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 50.0
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                margin: EdgeInsets.all(10.0),
                                child: Text('更新于 ${cities[index].update.substring(11, 19)}', style: Theme.of(context).textTheme.subtitle1),
                              ),
                            )
                          ],
                        );
                      },
                    ) : Center(
                      child: Text('暂无城市, 请先添加', style: Theme.of(context).textTheme.bodyText1),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                          icon: Icon(
                            _colorTheme == ColorTheme.dark ? Icons.wb_sunny : Icons.nights_stay,
                            color: _textColor,
                          ),
                          onPressed: () {
                            _colorTheme = _colorTheme == ColorTheme.dark ? ColorTheme.light : ColorTheme.dark;
                            setState(() {});
                          }
                      ),
                    ),
                    Offstage(
                      offstage: cities.length < 2,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: EdgeInsets.all(10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                                cities.length,
                                    (index) => Container(
                                  child: Dot(isActive: page == index, isDarkMode: _colorTheme == ColorTheme.dark),
                                  margin: EdgeInsets.symmetric(horizontal: 2.0),
                                )
                            ),
                          ),
                        ),
                      ),
                    ),
                    Offstage(
                      offstage: !padding,
                      child: Container(
                        constraints: BoxConstraints.expand(),
                        color: Colors.white.withOpacity(.75),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // color: Theme.of(context).primaryColor,
        child: Icon(Icons.add),
        onPressed: _showCityList,
      ),
    );
  }

  /// 动态申请定位权限
  void requestPermission() async {
    // 申请权限
    bool hasLocationPermission = await _locate.requestLocationPermission();
    if (hasLocationPermission) {
      _locate.startLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('定位失败, 请确保打开了定位权限.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3)
          )
      );
    }
  }
}

class Dot extends StatelessWidget {
  final bool isActive;
  final bool isDarkMode;
  Dot({ this.isActive = false, this.isDarkMode = true });
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    double size = 8.0;
    return AnimatedContainer(
      width: size,
      height: size,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOutQuad,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(isActive ? 1.0 : .4),
        borderRadius: BorderRadius.circular(size)
      )
    );
  }
}
