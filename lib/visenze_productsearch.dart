library visenze_productsearch_sdk;

import 'package:http/http.dart';
import 'package:visenze_productsearch_sdk/src/productsearch_client.dart';
import 'package:visenze_tracking_sdk/visenze_tracker.dart';

class VisenzeProductSearch {
  final String _appKey;
  final String _placementId;
  late final ProductSearchClient _client;
  late final VisenzeTracker _tracker;

  /// Factory for creating [VisenzeProductSearch]
  ///
  /// Require authentication params [appKey] and [placementId]
  ///
  /// If [uid] is provided, set tracker user id to [uid]
  ///
  /// If [timeout] is provided, request timeout is set to [timeout] in ms
  static Future<VisenzeProductSearch> create(String appKey, String placementId,
      {String? uid, bool? useStaging, int? timeout}) async {
    var ps = VisenzeProductSearch._create(appKey, placementId);
    await ps._init(uid: uid, useStaging: useStaging, timeout: timeout);
    return ps;
  }

  /// Get the current session id
  String get sessionId {
    return _tracker.sessionId;
  }

  /// Get the current user id
  String get userId {
    return _tracker.userId;
  }

  /// Set the current user id to the provided [uid]
  set userId(String uid) {
    _tracker.userId = uid;
  }

  /// Reset the current session and return the new session id
  String resetSession() {
    return _tracker.resetSession();
  }

  String? get lastSuccessQueryId {
    return _client.lastSuccessQueryId;
  }

  /// Send a request to ViSenze analytics server with event name [action] and provided [queryParams]
  Future<void> sendEvent(
      String action, Map<String, dynamic> queryParams) async {
    final params = {...queryParams}..addAll(_client.getCommonParams());
    await _tracker.sendEvent(action, params);
  }

  /// Send a request to ViSenze analytics server with event name [action] and provided params list [queryParamsList]
  Future<void> sendEvents(
      String action, List<Map<String, dynamic>> queryParamsList) async {
    final List<Map<String, dynamic>> paramsList = [];
    for (final queryParams in queryParamsList) {
      paramsList.add({...queryParams}..addAll(_client.getCommonParams()));
    }
    await _tracker.sendEvents(action, paramsList);
  }

  /// Do an image search with params [searchParams]
  Future<Response> productSearchByImage(
      Map<String, dynamic> searchParams) async {
    return await _client.imageSearch(searchParams);
  }

  /// Do a recommendation search with product id [pid] and optional params [recParams]
  Future<Response> productSearchById(String pid,
      [Map<String, dynamic>? recParams]) async {
    return await _client.idSearch(pid, recParams);
  }

  VisenzeProductSearch._create(this._appKey, this._placementId);

  Future<void> _init({String? uid, bool? useStaging, int? timeout}) async {
    _tracker = await VisenzeTracker.create('$_appKey:$_placementId', uid: uid);
    _client = await ProductSearchClient.create(_appKey, _placementId, _tracker,
        useStaging: useStaging, timeout: timeout);
  }
}
