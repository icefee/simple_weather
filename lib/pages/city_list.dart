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
                  return Scrollbar(
                    child: ListView.builder(
                        itemCount: __cities.length,
                        itemBuilder: (context, index) {
                          String _title = __cities[index]['title'];
                          var _cityList = __cities[index]['lists'];
                          return Column(
                            children: [
                              ListTile(
                                title: Text(_title),
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
