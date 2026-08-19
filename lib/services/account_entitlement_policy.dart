/// Product access rules shared by the UI and the account state layer.
///
/// The entitlement IDs must match the IDs configured in Superwall exactly.
class AccountEntitlementPolicy {
  static const String proEntitlementId = 'pro';
  static const String additionalAccountEntitlementId = 'additional_account';
  static const int maxConnectedAccounts = 2;

  const AccountEntitlementPolicy._();

  static bool canStartAdditionalAccount({required int accountCount}) {
    return accountCount >= 1 && accountCount < maxConnectedAccounts;
  }

  static bool canUseAdditionalAccount({
    required int accountCount,
    required bool hasProEntitlement,
    required bool hasAdditionalAccountEntitlement,
  }) {
    return canStartAdditionalAccount(accountCount: accountCount) &&
        hasProEntitlement &&
        hasAdditionalAccountEntitlement;
  }
}
