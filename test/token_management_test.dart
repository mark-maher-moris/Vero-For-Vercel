import 'package:flutter_test/flutter_test.dart';
import 'package:vero/models/vercel_account.dart';
import 'package:vero/services/api_service.dart';
import 'package:vero/services/auth_service.dart';

void main() {
  group('AuthErrorEvent tests', () {
    test('Correctly identifies 401 as unauthorized', () {
      final event = AuthErrorEvent(statusCode: 401, message: 'Invalid token');
      expect(event.isUnauthorized, isTrue);
      expect(event.isForbidden, isFalse);
    });

    test('Correctly identifies 403 as forbidden', () {
      final event = AuthErrorEvent(statusCode: 403, message: 'Forbidden');
      expect(event.isUnauthorized, isFalse);
      expect(event.isForbidden, isTrue);
    });
  });

  group('VercelAccount model tests', () {
    test('Updates token while preserving metadata', () {
      final account = VercelAccount(
        id: 'acc_123',
        token: 'old_token_xyz',
        name: 'Developer',
        username: 'dev123',
        email: 'dev@example.com',
        createdAt: DateTime.now(),
      );

      final updated = account.copyWith(token: 'new_token_abc');
      expect(updated.id, 'acc_123');
      expect(updated.token, 'new_token_abc');
      expect(updated.username, 'dev123');
      expect(updated.email, 'dev@example.com');
    });
  });

  group('Token validation status enum tests', () {
    test('Values exist', () {
      expect(
        TokenValidationStatus.values,
        contains(TokenValidationStatus.valid),
      );
      expect(
        TokenValidationStatus.values,
        contains(TokenValidationStatus.invalid),
      );
      expect(
        TokenValidationStatus.values,
        contains(TokenValidationStatus.teamScoped),
      );
    });
  });

  group('Scoped account tests', () {
    test('Correctly stores team scope and isTeamScopedOnly flag', () {
      final scopedAccount = VercelAccount(
        id: 'team_123',
        token: 'vcp_scoped_token',
        teamScope: 'team_123',
        name: 'Team Project',
        username: 'team_123',
        isTeamScopedOnly: true,
        createdAt: DateTime.now(),
      );

      expect(scopedAccount.isTeamScopedOnly, isTrue);
      expect(scopedAccount.teamScope, 'team_123');
      expect(scopedAccount.token, 'vcp_scoped_token');
    });
  });
}
