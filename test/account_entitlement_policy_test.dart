import 'package:flutter_test/flutter_test.dart';
import 'package:vero/services/account_entitlement_policy.dart';

void main() {
  test('requires both Pro and the additional-account entitlement', () {
    expect(
      AccountEntitlementPolicy.canUseAdditionalAccount(
        accountCount: 1,
        hasProEntitlement: true,
        hasAdditionalAccountEntitlement: true,
      ),
      isTrue,
    );
    expect(
      AccountEntitlementPolicy.canUseAdditionalAccount(
        accountCount: 1,
        hasProEntitlement: true,
        hasAdditionalAccountEntitlement: false,
      ),
      isFalse,
    );
    expect(
      AccountEntitlementPolicy.canUseAdditionalAccount(
        accountCount: 1,
        hasProEntitlement: false,
        hasAdditionalAccountEntitlement: true,
      ),
      isFalse,
    );
  });

  test('rejects a third account even when both entitlements are active', () {
    expect(
      AccountEntitlementPolicy.canUseAdditionalAccount(
        accountCount: AccountEntitlementPolicy.maxConnectedAccounts,
        hasProEntitlement: true,
        hasAdditionalAccountEntitlement: true,
      ),
      isFalse,
    );
    expect(
      AccountEntitlementPolicy.canStartAdditionalAccount(accountCount: 0),
      isFalse,
    );
  });
}
