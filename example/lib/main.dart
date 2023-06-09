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

  final TextEditingController _pidController = TextEditingController();
  final TextEditingController _imgUrlController = TextEditingController();
  final TextEditingController _imgIdController = TextEditingController();
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
        await VisenzeProductSearch.create('APP_KEY', 'PLACEMENT_ID');
    psRecClient = await VisenzeProductSearch.create('APP_KEY', 'PLACEMENT_ID');
    setState(() {
      _sid = psSearchClient.sessionId;
      _uid = psSearchClient.userId;
    });
  }

  void _searchById() async {
    var response = await psRecClient.productSearchById(_pidController.text);
    setState(() {
      _recRequestResult = response.body;
    });
  }

  void _searchByImgUrl() async {
    Map<String, dynamic> params = {'im_url': _imgUrlController.text};
    var response = await psSearchClient.productSearchByImage(null, params);
    setState(() {
      _searchRequestResult = response.body;
    });
  }

  void _searchByImgId() async {
    Map<String, dynamic> params = {'im_id': _imgIdController.text};
    var response = await psSearchClient.productSearchByImage(null, params);
    setState(() {
      _searchRequestResult = response.body;
    });
  }

  void _searchByCamera() async {
    var file = await psSearchClient.captureImage();
    setState(() {
      _fileName = file?.name;
    });
    if (file != null) {
      _searchByImg(file);
    }
  }

  void _searchByImageUpload() async {
    var file = await psSearchClient.uploadImage();
    setState(() {
      _fileName = file?.name;
    });
    if (file != null) {
      _searchByImg(file);
    }
  }

  void _searchByImg(file) async {
    if (_fileName != null) {
      var response = await psSearchClient.productSearchByImage(file, {});
      setState(() {
        _searchRequestResult = response.body;
      });
    }
  }

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

  Future<void> _sendEvent() async {
    try {
      await psSearchClient.sendEvent(
          _eventController.text, jsonDecode(_paramsController.text));
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
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              child: Container(
                height: 600,
                padding: const EdgeInsets.all(15),
                child: ListView(
                  children: <Widget>[
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
