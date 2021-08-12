import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class CityList extends StatefulWidget {
  final ValueChanged<String> onSetCity;
  CityList({ this.onSetCity });
  @override
  State<StatefulWidget> createState() => _CityList();
}

class _CityList extends State<CityList> {

  List<dynamic> _citys = [];
  String _keyword = '';
  String activeChar = '';
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    resolveCityData();
  }
  
  void resolveCityData() async {
    ByteData byteData = await rootBundle.load('assets/json/city.json');
    String json = utf8.decode(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    _citys = jsonDecode(json)['city'];
    setState(() {});
  }

  List<dynamic> filtered(List<dynamic> cities) {
    return cities.map((group) {
      List<dynamic> children = [];
      for (final item in group['lists']) {
        if (item.contains(_keyword.trim())) {
          children.add(item);
        }
      }
      return {
        'title': group['title'],
        'lists': children
      };
    }).toList()..removeWhere((item) => (item['lists'] as List).length == 0);
  }

  void onPanUpdate(detail, height) {
    double ratio = (detail.globalPosition.dy - (MediaQuery.of(context).size.height - height)) / height;
    int charIndex = (_citys.length * ratio).ceil();
    if (charIndex > _citys.length - 1 || charIndex < 0) {
      activeChar = '';
    }
    else {
      activeChar = _citys[charIndex]['title'];
      _scrollController.jumpTo(computeOffset(charIndex));
    }
    setState(() {});
  }

  double computeOffset(int index) {
    double offset = 0.0;
    for (int i = 0; i < index; i ++) {
      offset += 56 + (_citys[i]['lists'] as List).length * 72;
    }
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('添加城市'),
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10.0),
              color: Colors.grey[300],
              child: TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: '查找城市',
                  hintStyle: TextStyle(color: Colors.grey)
                ),
                // focusNode: _focusNode,
                autocorrect: false,
                autofocus: true,
                onChanged: (String value) {
                  _keyword = value;
                  setState(() {});
                },
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  List<dynamic> __cities = filtered(_citys);
                  if (__cities.isEmpty) {
                    return Center(
                      child: Text('暂无满足条件的城市.'),
                    );
                  }
                  return Stack(
                    children: [
                      Scrollbar(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: __cities.length,
                          itemBuilder: (context, index) {
                            String _title = __cities[index]['title'];
                            var _cityList = __cities[index]['lists'];
                            return Column(
                              children: [
                                Container(
                                  child: ListTile(
                                    title: Text(_title),
                                  ),
                                  color: Colors.grey[300],
                                ),
                                Column(
                                  children: List<Widget>.generate((_cityList as List).length, (index) => TextButton(
                                      onPressed: () {
                                        widget.onSetCity?.call(_cityList[index]);
                                      },
                                      child: ListTile(
                                        title: Text(_cityList[index]),
                                      )
                                    )),
                                  )
                                ],
                              );
                            }
                        ),
                      ),
                      LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          double _height = constraints.maxHeight;
                          if (_height > 480.0) {
                            _height = 480.0;
                          }
                          return Offstage(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                child: LayoutBuilder(
                                  builder: (BuildContext context, BoxConstraints constraints) {
                                    if (__cities.isEmpty) {
                                      return Container();
                                    }
                                    return FittedBox(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          for (final Map city in __cities) GestureDetector(
                                            child: Container(
                                              child: Text(city['title'], style: TextStyle(color: Colors.black45)),
                                              // color: city['title'] == activeChar ? Theme.of(context).primaryColor : null,
                                            ),
                                            onPanUpdate: (DragUpdateDetails detail) => onPanUpdate(detail, constraints.maxHeight),
                                            onPanEnd: (DragEndDetails detail) {
                                              setState(() {
                                                activeChar = '';
                                              });
                                            },
                                            onPanStart: (DragStartDetails detail) => onPanUpdate(detail, constraints.maxHeight),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                width: 25.0,
                                height: _height,
                                margin: EdgeInsets.only(right: 5.0),
                              ),
                            ),
                            offstage: _keyword.isNotEmpty,
                          );
                        }
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Offstage(
                          child: Container(
                            width: 60.0,
                            height: 60.0,
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 2.0,
                                color: Colors.indigo
                              )
                            ),
                            child: Center(
                              child: Text(activeChar, style: TextStyle(fontSize: 40.0, color: Colors.indigo)),
                            ),
                          ),
                          offstage: activeChar == '',
                        ),
                      )
                    ],
                  );
                },
              ),
            )
          ],
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
