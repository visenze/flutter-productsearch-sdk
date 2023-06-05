import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:visenze_tracking_sdk/visenze_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clock/clock.dart';

class ProductSearchClient {
  static const String _endpoint = 'search.visenze.com';
  static const String _stagingEndpoint = 'search-dev.visenze.com';
  static const String _pathRec = 'v1/product/recommendations';
  static const String _pathSearch = 'v1/product/search_by_image';

  static const String _sdk = 'flutter_sdk';
  static const String _version = '0.0.1';
  static const int _defaultTimeout = 15000;

  static const String _lastReqidKey = 'visenze_query_id_';

  final String _appKey;
  final String _placementId;
  final VisenzeTracker _tracker;
  late final int _timeoutInMs;
  late final bool _useStaging;
  late final SharedPreferences _prefs;
  late final http.Client _httpClient;

  static Future<ProductSearchClient> create(http.Client httpClient,
      String appKey, String placementId, VisenzeTracker tracker,
      {bool? useStaging, int? timeout}) async {
    final client = ProductSearchClient(httpClient, appKey, placementId, tracker,
        useStaging: useStaging, timeout: timeout);
    await client._init();
    return client;
  }

  ProductSearchClient(
      this._httpClient, this._appKey, this._placementId, this._tracker,
      {bool? useStaging, int? timeout}) {
    _timeoutInMs = timeout ?? _defaultTimeout;
    _useStaging = useStaging ?? false;
  }

  Future<http.Response> imageSearch(
      XFile? image, Map<String, dynamic> searchParams) async {
    Map<String, dynamic> params = {...searchParams};
    params.addAll(getCommonParams());
    params.addAll(_getAuthParams());

    http.Response response;

    if (image != null) {
      params = params.map((key, value) => MapEntry(key, value.toString()));
      Uri uri = Uri.https(_getEndpoint(), _pathSearch, params);
      response = await _uploadPost(uri, image);
    } else {
      params = params.map((key, value) => MapEntry(key, value.toString()));
      Uri uri = Uri.https(_getEndpoint(), _pathSearch, params);
      response = await _post(uri);
    }
    await _onSearchCompleted(response);
    return response;
  }

  Future<http.Response> idSearch(
      String pid, Map<String, dynamic>? requestParams) async {
    Map<String, dynamic> params =
        requestParams != null ? {...requestParams} : {};
    params.addAll(getCommonParams());
    params.addAll(_getAuthParams());
    params = params.map((key, value) => MapEntry(key, value.toString()));
    Uri uri = Uri.https(_getEndpoint(), '$_pathRec/$pid', params);
    var response = await _get(uri);
    await _onSearchCompleted(response, pid);
    return response;
  }

  Map<String, dynamic> getCommonParams() {
    return {
      'ts': clock.now().millisecondsSinceEpoch,
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
    return response.statusCode == 200 && resp['status'] == 'OK';
  }

  bool _isResponseHasResults(dynamic resp) {
    return (resp['result'] != null && resp['result'].length > 0) ||
        (resp['objects'] != null && resp['objects'].length > 0);
  }

  /// Send a result load
  Future<void> _onSearchCompleted(http.Response response, [String? pid]) async {
    if (_isResponseSuccess(response)) {
      final resp = jsonDecode(response.body);
      if (_isResponseHasResults(resp)) {
        await _sendResultLoadEvent(resp['reqid'], pid);
      }
      await _saveReqid(resp['reqid']);
    }
  }

  /// Send result load event for the last success request
  Future<void> _sendResultLoadEvent(String queryId, [String? pid]) async {
    final Map<String, dynamic> params = {'queryId': queryId};
    if (pid != null) {
      params['pid'] = pid;
    }
    params.addAll(getCommonParams());
    await _tracker.sendEvent('result_load', params);
  }

  /// Save the query id of the last success request
  Future<void> _saveReqid(String queryId) async {
    await _prefs.setString('$_lastReqidKey$_placementId', queryId);
  }

  Map<String, dynamic> _getAuthParams() {
    return {'app_key': _appKey, 'placement_id': _placementId};
  }

  String _getEndpoint() {
    return _useStaging ? _stagingEndpoint : _endpoint;
  }

  Future<http.Response> _get(Uri uri) async {
    final response = await _httpClient
        .get(uri)
        .timeout(Duration(milliseconds: _timeoutInMs));
    return response;
  }

  Future<http.Response> _post(Uri uri) async {
    final response = await _httpClient
        .post(uri)
        .timeout(Duration(milliseconds: _timeoutInMs));
    return response;
  }

  Future<http.Response> _uploadPost(Uri uri, XFile image) async {
    final request = http.MultipartRequest('POST', uri);
    final stream = http.ByteStream(image.openRead());
    stream.cast();
    final length = await image.length();
    final multipartFile =
        http.MultipartFile('image', stream, length, filename: image.name);

    request.files.add(multipartFile);

    final response =
        await request.send().timeout(Duration(milliseconds: _timeoutInMs));
    return http.Response.fromStream(response);
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }
}
