import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:visenze_productsearch_sdk/src/productsearch_client.dart';
import 'package:visenze_tracking_sdk/visenze_tracker.dart';
import 'productsearch_client_test.mocks.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateNiceMocks([MockSpec<http.Client>(), MockSpec<VisenzeTracker>()])
void main() {
  const mockAppKey = 'abc';
  const mockPlacementId = '123';
  const mockSessionId = '1234.5678';
  const mockUserId = 'uid';
  const mockPid = 'pid';
  const mockPid2 = 'pid2';
  const mockTime = 123456789;

  late MockClient httpClient;
  late MockVisenzeTracker va;
  late ProductSearchClient psClient;
  late String version;

  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUp(() async {
    va = MockVisenzeTracker();
    httpClient = MockClient();
    psClient = await ProductSearchClient.create(
        httpClient, mockAppKey, mockPlacementId, va);
    version = psClient.getCommonParams()['va_sdk_version'];

    when(va.sessionId).thenAnswer((_) => mockSessionId);
    when(va.userId).thenAnswer((_) => mockUserId);
    when(va.sendEvent(any, any))
        .thenAnswer((_) async => http.Response('', 200));
  });

  tearDown(() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
  });

  group('search', () {
    test('success with no result', () {
      final searchParams = {'limit': 1};
      final uri = Uri.parse(
          'https://search.visenze.com/v1/product/recommendations/pid?limit=1&ts=123456789&va_sdk=flutter_sdk&va_sdk_version=$version&va_uid=uid&va_sid=1234.5678&app_key=abc&placement_id=123');
      when(httpClient.get(any)).thenAnswer((_) async => http.Response(
          '{"reqid": "1234", "status": "OK", "result": []}', 200));
      withClock(
        Clock.fixed(DateTime.fromMillisecondsSinceEpoch(mockTime)),
        () async {
          final resp = await psClient.idSearch(mockPid, searchParams);
          final respBody = jsonDecode(resp.body);

          verify(httpClient.get(uri)).called(1);
          expect(respBody['reqid'], equals('1234'));
          expect(respBody['result'].length, equals(0));
          verifyNever(va.sendEvent('result_load', any));
          expect(psClient.lastSuccessQueryId, equals('1234'));
        },
      );
    });

    test('success with result', () {
      final searchParams = {'limit': 1};
      final uri = Uri.parse(
          'https://search.visenze.com/v1/product/recommendations/pid2?limit=1&ts=123456789&va_sdk=flutter_sdk&va_sdk_version=$version&va_uid=uid&va_sid=1234.5678&app_key=abc&placement_id=123');
      when(httpClient.get(uri)).thenAnswer((_) async => http.Response(
          '{"reqid": "12345", "status": "OK", "result": [{"pid": "12345"}]}',
          200));

      withClock(
        Clock.fixed(DateTime.fromMillisecondsSinceEpoch(mockTime)),
        () async {
          final resp = await psClient.idSearch(mockPid2, searchParams);
          final respBody = jsonDecode(resp.body);

          verify(httpClient.get(uri)).called(1);
          expect(respBody['reqid'], equals('12345'));
          expect(respBody['result'].length, equals(1));
          verify(va.sendEvent('result_load', any)).called(1);
          expect(psClient.lastSuccessQueryId, equals('12345'));
        },
      );
    });

    test('error', () {
      final searchParams = {'limit': 1};
      final uri = Uri.parse(
          'https://search.visenze.com/v1/product/recommendations/pid?limit=1&ts=123456789&va_sdk=flutter_sdk&va_sdk_version=$version&va_uid=uid&va_sid=1234.5678&app_key=abc&placement_id=123');
      when(httpClient.get(uri)).thenAnswer((_) async => http.Response(
          '{"reqid": "1234", "status": "fail", "result": []}', 401));

      withClock(
        Clock.fixed(DateTime.fromMillisecondsSinceEpoch(mockTime)),
        () async {
          final resp = await psClient.idSearch(mockPid, searchParams);
          final respBody = jsonDecode(resp.body);

          expect(respBody['status'], equals('fail'));
          verify(httpClient.get(uri)).called(1);
          verifyNever(va.sendEvent(any, any));
          expect(psClient.lastSuccessQueryId, isNull);
        },
      );
    });
  });
}
