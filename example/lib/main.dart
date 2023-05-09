import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:visenze_productsearch_sdk/visenze_productsearch.dart';
import 'package:file_picker/file_picker.dart';

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
      TextEditingController(text: 'product_click');
  final TextEditingController _paramsController =
      TextEditingController(text: '{"pid": "Test PID", "queryId": "1234"}');

  late VisenzeProductSearch psSearchClient;
  late VisenzeProductSearch psRecClient;
  FilePickerResult? _fileResult;
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
    var response = await psSearchClient.productSearchByImage(params);
    setState(() {
      _searchRequestResult = response.body;
    });
  }

  void _searchByImgId() async {
    Map<String, dynamic> params = {'im_id': _imgIdController.text};
    var response = await psSearchClient.productSearchByImage(params);
    setState(() {
      _searchRequestResult = response.body;
    });
  }

  void _searchByImg() async {
    if (_fileResult != null) {
      Map<String, dynamic> params = {'image': _fileResult!.files.single};
      var response = await psSearchClient.productSearchByImage(params);
      setState(() {
        _searchRequestResult = response.body;
      });
    }
  }

  void _uploadImage() async {
    _resetState();
    PlatformFile? file;
    _fileResult = await FilePicker.platform
        .pickFiles(type: FileType.image, withReadStream: true);
    file = _fileResult?.files[0];
    setState(() {
      _fileName = file != null ? file.name.toString() : '...';
    });
    if (!mounted) return;
  }

  void _resetState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _fileName = null;
    });
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
                        onPressed: _uploadImage,
                        child: const Text('Upload image')),
                    Text(
                      'Image name: $_fileName',
                    ),
                    const Padding(padding: EdgeInsets.all(4)),
                    ElevatedButton(
                        onPressed: _searchByImg,
                        child: const Text('Search by image')),
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
                  Text(_trackingRequestResult),
                ],
              ),
            ),
          ])),
    ));
  }
}
