import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyva_app/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'iOS initialization does not prompt and permission denial is explicit',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_timezone'),
        (_) async => 'UTC',
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (call) async {
          calls.add(call);
          if (call.method == 'initialize') return true;
          if (call.method == 'checkPermissions') return {'isEnabled': false};
          if (call.method == 'requestPermissions') return false;
          return null;
        },
      );
      final service = NotificationService.forTesting();
      await service.init();
      final args =
          calls.singleWhere((c) => c.method == 'initialize').arguments as Map;
      expect(args['requestAlertPermission'], isFalse);
      expect(args['requestBadgePermission'], isFalse);
      expect(args['requestSoundPermission'], isFalse);
      expect(calls.where((c) => c.method == 'requestPermissions'), isEmpty);
      expect(await service.notificationsEnabled(), isFalse);
      expect(await service.requestPermissions(), isFalse);
      expect(calls.where((c) => c.method == 'requestPermissions').length, 1);
    },
  );
}
