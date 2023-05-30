import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:visenze_productsearch_sdk/visenze_productsearch.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  String _recRequestResult = '<unknown>';
  String _searchRequestResult = '<unknown>';
  String _sid = '<unknown>';
  String _uid = '<unknown>';
  String _trackingRequestResult = '<unknown>';
  String? _lastQueryId = '<unknown>';

  final TextEditingController _pidController = TextEditingController();
  final TextEditingController _imgUrlController = TextEditingController();
  final TextEditingController _imgIdController = TextEditingController();
  final TextEditingController _queryParamController = TextEditingController();
  final TextEditingController _eventController =
      TextEditingController(text: 'transaction');
  final TextEditingController _paramsController = TextEditingController(
      text: '{"pid": "PID_1", "queryId": "1234", "value": 50}');
  final TextEditingController _paramsListController = TextEditingController(
      text:
          '[{"pid": "PID_1", "queryId": "1234", "value": 50}, {"pid": "PID_2", "queryId": "1234", "value": 100}]');

  late VisenzeProductSearch psSearchClient;
  late VisenzeProductSearch psRecClient;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    initPS();
  }

  // Factory is asynchronous, so we put it in an async method.
  void initPS() async {
    psSearchClient =
        await VisenzeProductSearch.create('c0a2bd241268ad2f43a8ddd26ca42989', '3347', useStaging: true);
    psRecClient = await VisenzeProductSearch.create('5e365922c2a316f9bb6ff0be665f06ce', '3350', useStaging: true);
    setState(() {
      _sid = psSearchClient.sessionId;
      _uid = psSearchClient.userId;

      // resize limit --------
      // psSearchClient.widthLimit = 2048;
      // psSearchClient.heightLimit = 2048;
    });
  }

  // ------------- common utils ---------- start --------------
  void _resetSession() async {
    psSearchClient.resetSession();
    setState(() {
      _sid = psSearchClient.sessionId;
    });
  }

  void _onRequestSuccess() {
    setState(() {
      _trackingRequestResult = 'Request success';
    });
  }

  void _onRequestError(dynamic err) {
    setState(() {
      _trackingRequestResult = 'Request fail: $err';
    });
  }

  void _resetMsg() {
    _searchRequestResult = "";
    _trackingRequestResult = "";
    _fileName = "";
    _recRequestResult = "";
  }

  Map<String, dynamic> _getSearchQueryParam() {
    Map<String, dynamic> params = {};
    if(_queryParamController.text.isNotEmpty) {
      params = jsonDecode(_queryParamController.text);
    }
    return params;
  }

  // ------------- recommendation ---------- start --------------
  void _searchById() async {
    _resetMsg();
    try {
      Map<String, dynamic> params = _getSearchQueryParam();
      var response = await psRecClient.productSearchById(_pidController.text, params=params);
      setState(() {
        _recRequestResult = response.body;
        _lastQueryId = psRecClient.lastSuccessQueryId;
      });
    } catch (err) {
      _onRequestError(err);
    }
  }

  // ------------- search ---------- start --------------
  void _searchByImgUrl() async {
    _resetMsg();
    try {
      Map<String, dynamic> params = {'im_url': _imgUrlController.text};
      params.addAll(_getSearchQueryParam());
      var response = await psSearchClient.productSearchByImage(null, params);
      setState(() {
        _searchRequestResult = response.body;
        _lastQueryId = psSearchClient.lastSuccessQueryId;
      });
    } catch(err) {
      _onRequestError(err);
    }

  }

  void _searchByImgId() async {
    _resetMsg();
    try {
      Map<String, dynamic> params = {'im_id': _imgIdController.text};
      params.addAll(_getSearchQueryParam());
      var response = await psSearchClient.productSearchByImage(null, params);
      setState(() {
        _searchRequestResult = response.body;
        _lastQueryId = psSearchClient.lastSuccessQueryId;
      });
    } catch(err) {
      _onRequestError(err);
    }
  }

  void _searchByCamera() async {
    _resetMsg();
    try {
      var file = await psSearchClient.captureImage();
      setState(() {
        _fileName = file?.name;
      });
      if (file != null) {
        _searchByImg(file);
      }
    } catch(err) {
      _onRequestError(err);
    }
  }

  void _searchByImageUpload() async {
    _resetMsg();
    var file;
    try {
      file = await psSearchClient.uploadImage();
    } catch(err) {
      _onRequestError(err);
      return;
    }
    setState(() {
      _fileName = file?.name;
    });
    if (file != null) {
      _searchByImg(file);
    }
  }

  void _searchByImg(file) async {
    _resetMsg();
    try {
      if (_fileName != null) {
        var response = await psSearchClient.productSearchByImage(file, _getSearchQueryParam());
        setState(() {
          _searchRequestResult = response.body;
          _lastQueryId = psSearchClient.lastSuccessQueryId;
        });
      }
    } catch(err) {
      _onRequestError(err);
    }
  }

  // ------------- tracking ---------- start --------------

  Future<void> _sendEvent() async {
    try {
      Map<String, dynamic> params = jsonDecode(_paramsController.text);
      params["queryId"] = _lastQueryId;
      await psSearchClient.sendEvent(
          _eventController.text, params);
      _onRequestSuccess();
    } catch (err) {
      _onRequestError(err);
    }
  }

  Future<void> _sendBatchEvent() async {
    try {
      List<Map<String, dynamic>> params = jsonDecode(_paramsListController.text)
          .map((element) => element as Map<String, dynamic>)
          .toList();
      await psSearchClient.sendEvents(_eventController.text, params);
      _onRequestSuccess();
    } catch (err) {
      _onRequestError(err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: DefaultTabController(
      length: 3,
      child: Scaffold(
          appBar: AppBar(
            title: const Text('ProductSearch SDK Demo'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Rec'),
                Tab(text: 'Search'),
                Tab(text: 'Tracking'),
              ],
            ),
          ),
          body: TabBarView(children: [
            SingleChildScrollView(
              child: Container(
                height: 600,
                padding: const EdgeInsets.all(15),
                child: ListView(
                  children: <Widget>[
                    Text(
                      'last query id: $_lastQueryId',
                    ),
                    const Padding(padding: EdgeInsets.all(20)),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Query params",
                      ),
                      controller: _queryParamController,
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Product id",
                      ),
                      controller: _pidController,
                    ),
                    const Padding(padding: EdgeInsets.all(4)),
                    ElevatedButton(
                        onPressed: _searchById,
                        child: const Text('Search by product id')),
                    const Divider(thickness: 2, color: Colors.grey, height: 30),
                    Text(
                      'Response: $_recRequestResult',
                    ),
                    const Padding(padding: EdgeInsets.all(4)),
                    Text("Error: $_trackingRequestResult"),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              child: Container(
                height: 900,
                padding: const EdgeInsets.all(15),
                child: ListView(
                  children: <Widget>[
                    Text(
                      'last query id: $_lastQueryId',
                    ),
                    const Padding(padding: EdgeInsets.all(20)),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Query params",
                      ),
                      controller: _queryParamController,
                    ),
                    const Padding(padding: EdgeInsets.all(20)),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Image url",
                      ),
                      controller: _imgUrlController,
                    ),
                    const Padding(padding: EdgeInsets.all(4)),
                    ElevatedButton(
                        onPressed: _searchByImgUrl,
                        child: const Text('Search by image url')),
                    const Divider(thickness: 2, color: Colors.grey, height: 30),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Image id",
                      ),
                      controller: _imgIdController,
                    ),
                    ElevatedButton(
                        onPressed: _searchByImgId,
                        child: const Text('Search by image id')),
                    const Divider(thickness: 2, color: Colors.grey, height: 30),
                    ElevatedButton(
                        onPressed: _searchByImageUpload,
                        child: const Text('Upload search')),
                    const Padding(padding: EdgeInsets.all(4)),
                    ElevatedButton(
                        onPressed: _searchByCamera,
                        child: const Text('Camera search')),
                    const Padding(padding: EdgeInsets.all(4)),
                    Text(
                      'Image name: $_fileName',
                    ),
                    const Divider(thickness: 2, color: Colors.grey, height: 30),
                    Text(
                      'Response: $_searchRequestResult',
                    ),
                    const Divider(thickness: 2, color: Colors.grey, height: 30),
                    const Padding(padding: EdgeInsets.all(4)),
                    Text("Error: $_trackingRequestResult"),
                  ],
                ),
              ),
            ),
            Container(
              height: 600,
              padding: const EdgeInsets.all(15),
              child: ListView(
                children: <Widget>[
                  Text(
                    'last query id: $_lastQueryId',
                  ),
                  const Padding(padding: EdgeInsets.all(4)),
                  Text(
                    'Session id: $_sid',
                  ),
                  Text(
                    'User id: $_uid',
                  ),
                  const Padding(padding: EdgeInsets.all(4)),
                  ElevatedButton(
                      onPressed: _resetSession,
                      child: const Text('Reset session')),
                  const Divider(thickness: 2, color: Colors.grey, height: 30),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Event name",
                    ),
                    controller: _eventController,
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Event params",
                    ),
                    controller: _paramsController,
                  ),
                  const Padding(padding: EdgeInsets.all(4)),
                  ElevatedButton(
                      onPressed: _sendEvent, child: const Text('Send event')),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Event list params",
                    ),
                    controller: _paramsListController,
                  ),
                  const Padding(padding: EdgeInsets.all(4)),
                  ElevatedButton(
                      onPressed: _sendBatchEvent,
                      child: const Text('Send batch event')),
                  const Padding(padding: EdgeInsets.all(4)),
                  Text(_trackingRequestResult),
                ],
              ),
            ),
          ])),
    ));
  }
}
