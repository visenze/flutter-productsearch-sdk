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
    return _tracker.getSessionId();
  }

  /// Get the current user id
  String get userId {
    return _tracker.getUserId();
  }

  /// Set the current user id to the provided [uid]
  set userId(String uid) {
    return _tracker.setUserId(uid);
  }

  /// Send a request to ViSenze analytics server with event name [action] and provided [queryParams]
  ///
  /// Execute [onSuccess] on request success and [onError] on request error
  Future<void> sendEvent(String action, Map<String, dynamic> queryParams,
      {void Function()? onSuccess, void Function(String err)? onError}) async {
    _tracker.sendEvent(action, queryParams,
        onSuccess: onSuccess, onError: onError);
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
    _client = ProductSearchClient(_appKey, _placementId, _tracker,
        useStaging: useStaging, timeout: timeout);
  }
}
