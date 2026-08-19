import 'package:flutter_test/flutter_test.dart';
import 'package:vero/models/log.dart';

void main() {
  group('Log parsing', () {
    test('normalizes a flat runtime log line', () {
      final log = Log.fromJson({
        'id': 'line_1',
        'timestamp': 1714041600,
        'method': 'post',
        'path': '/api/orders',
        'host': 'example.vercel.app',
        'statusCode': '201',
        'level': 'warning',
        'message': 'Order accepted',
        'executionRegion': 'iad1',
      });

      expect(log.requestId, 'line_1');
      expect(log.requestMethod, 'POST');
      expect(log.requestPath, '/api/orders');
      expect(log.domain, 'example.vercel.app');
      expect(log.statusCode, 201);
      expect(log.clientRegion, 'iad1');
      expect(log.logs, hasLength(1));
      expect(log.logs.single.level, 'warning');
      expect(log.logs.single.message, 'Order accepted');
      expect(log.timestamp.millisecondsSinceEpoch, 1714041600000);
    });

    test('tolerates malformed optional collections', () {
      final log = Log.fromJson({
        'timestamp': 'not-a-date',
        'events': ['unexpected'],
        'logs': ['unexpected'],
        'requestSearchParams': 'unexpected',
      });

      expect(log.events, isEmpty);
      expect(log.logs, isEmpty);
      expect(log.requestSearchParams, isEmpty);
      expect(log.requestMethod, 'GET');
    });
  });
}
