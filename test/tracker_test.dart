import 'package:flutter_test/flutter_test.dart';
import 'package:visenze_productsearch_sdk/visenze_productsearch.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_async/fake_async.dart';

void main() {
  const appKey = 'abc';
  const placementId = '123';
  const mockUID = 'uid';

  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  tearDown(() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
  });

  group('SID', () {
    test('is not empty', () async {
      var psClient = await VisenzeProductSearch.create(appKey, placementId);
      expect(psClient.sessionId, isNotEmpty);
    });

    test('persists across trackers', () async {
      var psClient1 = await VisenzeProductSearch.create(appKey, placementId);
      String savedSid = psClient1.sessionId;

      final tracker2 = await VisenzeProductSearch.create(appKey, placementId);
      expect(tracker2.sessionId, equals(savedSid));
    });

    test('resets after timeout', () async {
      var psClient = await VisenzeProductSearch.create(appKey, placementId);
      var savedSid = psClient.sessionId;
      fakeAsync((fakeTime) async {
        fakeTime.elapse(const Duration(milliseconds: 1800000));
        expect(psClient.sessionId, isNot(savedSid));
      });
    });

    test('resets after user reset', () async {
      var psClient = await VisenzeProductSearch.create(appKey, placementId);
      String savedSid = psClient.sessionId;
      psClient.resetSession();
      expect(psClient.sessionId, isNot(savedSid));
    });
  });

  group('UID', () {
    test('is not empty', () async {
      var psClient = await VisenzeProductSearch.create(appKey, placementId);
      expect(psClient.userId, isNotEmpty);
    });

    test('is same as init UID', () async {
      var psClient =
          await VisenzeProductSearch.create(appKey, placementId, uid: mockUID);
      expect(psClient.userId, equals(mockUID));
    });

    test('is set correctly', () async {
      var psClient =
          await VisenzeProductSearch.create(appKey, placementId, uid: mockUID);
      String oldUid = psClient.userId;
      expect(oldUid, isNotEmpty);

      psClient.userId = 'new uid';
      expect(psClient.userId, isNot(oldUid));
    });

    test('persists across trackers', () async {
      var psClient1 = await VisenzeProductSearch.create(appKey, placementId);
      String savedUid = psClient1.userId;

      final psClient2 = await VisenzeProductSearch.create(appKey, placementId);
      expect(psClient2.userId, equals(savedUid));
    });
  });
}
