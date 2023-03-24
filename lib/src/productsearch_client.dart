import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:visenze_tracking_sdk/visenze_tracker.dart';

class ProductSearchClient {
  static const String _endpoint = 'search.visenze.com';
  static const String _stagingEndpoint = 'search-dev.visenze.com';
  static const String _pathRec = 'v1/product/recommendations';
  static const String _pathSearch = 'v1/product/search_by_image';

  static const String _sdk = 'flutter_sdk';
  static const String _version = '0.0.1-dev.1';
  static const int _defaultTimeout = 15000;

  final String _appKey;
  final String _placementId;
  final VisenzeTracker _tracker;
  late final int _timeoutInMs;
  late final bool _useStaging;

  ProductSearchClient(this._appKey, this._placementId, this._tracker,
      {bool? useStaging, int? timeout}) {
    _timeoutInMs = timeout ?? _defaultTimeout;
    _useStaging = useStaging ?? false;
  }

  Future<http.Response> imageSearch(Map<String, dynamic> searchParams) async {
    Map<String, dynamic> params = _getCommonParams();
    params.addAll(_getAuthParams());
    params.addAll(searchParams);
    params = params.map((key, value) => MapEntry(key, value.toString()));

    Map<String, dynamic> body = {};
    if (params['image'] != null) {
      body['image'] = params['image'];
    }

    params = params.map((key, value) => MapEntry(key, value.toString()));
    Uri uri = Uri.https(_getEndpoint(), _pathSearch, params);
    var response = await _post(uri, body);
    _sendResultLoadEvent(response);
    return response;
  }

  Future<http.Response> idSearch(
      String pid, Map<String, dynamic>? requestParams) async {
    Map<String, dynamic> params = _getCommonParams();
    params.addAll(_getAuthParams());
    params.addAll(requestParams ?? {});
    params = params.map((key, value) => MapEntry(key, value.toString()));
    Uri uri = Uri.https(_getEndpoint(), '$_pathRec/$pid', params);
    var response = await _get(uri);
    _sendResultLoadEvent(response, pid);
    return response;
  }

  void _sendResultLoadEvent(http.Response response, [String? pid]) {
    var resp = jsonDecode(response.body);

    if (response.statusCode == 200 &&
        resp['result'] != null &&
        resp['result'].length > 0) {
      var params = {'queryId': resp['reqid']};
      if (pid != null) {
        params['pid'] = pid;
      }
      _tracker.sendEvent('result_load', params);
    }
  }

  Map<String, dynamic> _getAuthParams() {
    return {'app_key': _appKey, 'placement_id': _placementId};
  }

  Map<String, dynamic> _getCommonParams() {
    return {
      'ts': DateTime.now().millisecondsSinceEpoch,
      'va_sdk': _sdk,
      'va_sdk_version': _version,
      'va_uid': _tracker.getUserId(),
      'va_sid': _tracker.getSessionId()
    };
  }

  String _getEndpoint() {
    return _useStaging ? _stagingEndpoint : _endpoint;
  }

  Future<http.Response> _get(Uri uri) async {
    var response =
        await http.get(uri).timeout(Duration(milliseconds: _timeoutInMs));
    return response;
  }

  Future<http.Response> _post(Uri uri, Map<String, dynamic> body) async {
    var response = await http
        .post(uri, body: body)
        .timeout(Duration(milliseconds: _timeoutInMs));
    return response;
  }
}
