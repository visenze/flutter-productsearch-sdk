import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:visenze_tracking_sdk/visenze_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductSearchClient {
  static const String _endpoint = 'search.visenze.com';
  static const String _stagingEndpoint = 'search-dev.visenze.com';
  static const String _pathRec = 'v1/product/recommendations';
  static const String _pathSearch = 'v1/product/search_by_image';

  static const String _sdk = 'flutter_sdk';
  static const String _version = '0.0.1-dev.1';
  static const int _defaultTimeout = 15000;

  static const String _lastReqidKey = 'visenze_query_id_';

  final String _appKey;
  final String _placementId;
  final VisenzeTracker _tracker;
  late final int _timeoutInMs;
  late final bool _useStaging;
  late final SharedPreferences _prefs;

  static Future<ProductSearchClient> create(
      String appKey, String placementId, VisenzeTracker tracker,
      {bool? useStaging, int? timeout}) async {
    var client = ProductSearchClient(appKey, placementId, tracker,
        useStaging: useStaging, timeout: timeout);
    await client._init();
    return client;
  }

  ProductSearchClient(this._appKey, this._placementId, this._tracker,
      {bool? useStaging, int? timeout}) {
    _timeoutInMs = timeout ?? _defaultTimeout;
    _useStaging = useStaging ?? false;
  }

  Future<http.Response> imageSearch(Map<String, dynamic> searchParams) async {
    Map<String, dynamic> params = getCommonParams();
    params.addAll(_getAuthParams());
    params.addAll(searchParams);

    http.Response response;

    if (params['image'] != null) {
      dynamic file = params['image'];
      params.remove('image');
      params = params.map((key, value) => MapEntry(key, value.toString()));
      Uri uri = Uri.https(_getEndpoint(), _pathSearch, params);
      response = await _uploadPost(uri, file);
    } else {
      params = params.map((key, value) => MapEntry(key, value.toString()));
      Uri uri = Uri.https(_getEndpoint(), _pathSearch, params);
      response = await _post(uri);
    }
    _onSearchCompleted(response);
    return response;
  }

  Future<http.Response> idSearch(
      String pid, Map<String, dynamic>? requestParams) async {
    Map<String, dynamic> params = getCommonParams();
    params.addAll(_getAuthParams());
    params.addAll(requestParams ?? {});
    params = params.map((key, value) => MapEntry(key, value.toString()));
    Uri uri = Uri.https(_getEndpoint(), '$_pathRec/$pid', params);
    var response = await _get(uri);
    _onSearchCompleted(response, pid);
    return response;
  }

  Map<String, dynamic> getCommonParams() {
    return {
      'ts': DateTime.now().millisecondsSinceEpoch,
      'va_sdk': _sdk,
      'va_sdk_version': _version,
      'va_uid': _tracker.userId,
      'va_sid': _tracker.sessionId
    };
  }

  String? get lastSuccessQueryId {
    return _prefs.getString('$_lastReqidKey$_placementId');
  }

  bool _isResponseSuccess(http.Response response) {
    final resp = jsonDecode(response.body);
    return response.statusCode == 200 &&
        ((resp['result'] != null && resp['result'].length > 0) ||
            (resp['objects'] != null && resp['objects'].length > 0));
  }

  /// Send a result load
  void _onSearchCompleted(http.Response response, [String? pid]) {
    if (_isResponseSuccess(response)) {
      final resp = jsonDecode(response.body);
      _sendResultLoadEvent(resp['reqid'], pid);
      _saveReqid(resp['reqid']);
    }
  }

  /// Send result load event for the last success request
  void _sendResultLoadEvent(String queryId, [String? pid]) {
    final Map<String, dynamic> params = {'queryId': queryId};
    if (pid != null) {
      params['pid'] = pid;
    }
    params.addAll(getCommonParams());
    _tracker.sendEvent('result_load', params);
  }

  /// Save the query id of the last success request
  void _saveReqid(String queryId) {
    _prefs.setString('${_lastReqidKey}_$_placementId', queryId);
  }

  Map<String, dynamic> _getAuthParams() {
    return {'app_key': _appKey, 'placement_id': _placementId};
  }

  String _getEndpoint() {
    return _useStaging ? _stagingEndpoint : _endpoint;
  }

  Future<http.Response> _get(Uri uri) async {
    var response =
        await http.get(uri).timeout(Duration(milliseconds: _timeoutInMs));
    return response;
  }

  Future<http.Response> _post(Uri uri) async {
    var response =
        await http.post(uri).timeout(Duration(milliseconds: _timeoutInMs));
    return response;
  }

  Future<http.Response> _uploadPost(Uri uri, dynamic objFile) async {
    final request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile(
        'image', objFile.readStream, objFile.size,
        filename: objFile.name));

    var response =
        await request.send().timeout(Duration(milliseconds: _timeoutInMs));
    return http.Response.fromStream(response);
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }
}
