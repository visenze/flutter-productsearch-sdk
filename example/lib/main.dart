import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final TextEditingController _pidController = TextEditingController();
  final TextEditingController _imgUrlController = TextEditingController();
  final TextEditingController _imgIdController = TextEditingController();

  late VisenzeProductSearch psClient;
  FilePickerResult? _fileResult;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    initPS();
  }

  // Factory is asynchronous, so we put it in an async method.
  void initPS() async {
    psClient = await VisenzeProductSearch.create('APP_KEY', 'PLACEMENT_ID');
  }

  void _fetchData() {
    setState(() {
      _sid = psClient.sessionId;
      _uid = psClient.userId;
    });
  }

  void _searchById() async {
    var response = await psClient.productSearchById(_pidController.text);
    setState(() {
      _recRequestResult = response.body;
    });
  }

  void _searchByImgUrl() async {
    Map<String, dynamic> params = {'im_url': _imgUrlController.text};
    var response = await psClient.productSearchByImage(params);
    setState(() {
      _searchRequestResult = response.body;
    });
  }

  void _searchByImgId() async {
    Map<String, dynamic> params = {'im_id': _imgIdController.text};
    var response = await psClient.productSearchByImage(params);
    setState(() {
      _searchRequestResult = response.body;
    });
  }

  void _searchByImg() async {
    if (_fileResult != null) {
      Map<String, dynamic> params = {'image': _fileResult!.files.single};
      var response = await psClient.productSearchByImage(params);
      setState(() {
        _searchRequestResult = response.body;
      });
    }
  }

  void _uploadImage() async {
    _resetState();
    PlatformFile? file;
    try {
      _fileResult = await FilePicker.platform
          .pickFiles(type: FileType.image, withReadStream: true);
      file = _fileResult?.files[0];
    } on PlatformException catch (e) {
      // handle exception
    } catch (e) {
      // handle exception
    }
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
                Tab(text: 'Recommendations'),
                Tab(text: 'Search'),
                Tab(text: 'Tracking data'),
              ],
            ),
          ),
          body: TabBarView(children: [
            SingleChildScrollView(
              child: Container(
                height: 600,
                padding: const EdgeInsets.all(10),
                child: ListView(
                  children: <Widget>[
                    TextField(
                      decoration: const InputDecoration(
                        hintText: "Enter product pid",
                      ),
                      controller: _pidController,
                    ),
                    const Padding(padding: EdgeInsets.all(4)),
                    ElevatedButton(
                        onPressed: _searchById,
                        child: const Text('Search by product id')),
                    const Divider(
                      thickness: 2,
                      color: Colors.black,
                    ),
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
                padding: const EdgeInsets.all(10),
                child: ListView(
                  children: <Widget>[
                    TextField(
                      decoration: const InputDecoration(
                        hintText: "Enter image url",
                      ),
                      controller: _imgUrlController,
                    ),
                    ElevatedButton(
                        onPressed: _searchByImgUrl,
                        child: const Text('Search by image url')),
                    const Divider(
                      thickness: 2,
                      color: Colors.black,
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: "Enter image id",
                      ),
                      controller: _imgIdController,
                    ),
                    ElevatedButton(
                        onPressed: _searchByImgId,
                        child: const Text('Search by image id')),
                    const Divider(
                      thickness: 2,
                      color: Colors.black,
                    ),
                    ElevatedButton(
                        onPressed: _uploadImage,
                        child: const Text('Upload image')),
                    Text(
                      'Image name: $_fileName',
                    ),
                    ElevatedButton(
                        onPressed: _searchByImg,
                        child: const Text('Search by image')),
                    const Divider(
                      thickness: 2,
                      color: Colors.black,
                    ),
                    Text(
                      'Response: $_searchRequestResult',
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 600,
              padding: const EdgeInsets.all(10),
              child: ListView(
                children: <Widget>[
                  ElevatedButton(
                      onPressed: _fetchData, child: const Text('Fetch data')),
                  Text(
                    'Session id: $_sid',
                  ),
                  Text(
                    'User id: $_uid',
                  ),
                ],
              ),
            ),
          ])),
    ));
  }
}
