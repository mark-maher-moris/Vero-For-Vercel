import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vero/providers/app_state.dart';
import 'package:vero/providers/subscription_provider.dart';
import 'package:vero/widgets/account_switcher_bottom_sheet.dart';

class MockSubscriptionProvider extends ChangeNotifier
    implements SubscriptionProvider {
  bool paywallResult = true;

  @override
  bool get hasActiveSubscription => false;

  @override
  bool get isPro => false;

  @override
  bool get hasProEntitlement => false;

  @override
  bool get hasAdditionalAccountEntitlement => false;

  @override
  bool get isLoading => false;

  @override
  bool get hasError => false;

  @override
  String? get errorMessage => null;

  @override
  Future<bool> authorizeAdditionalAccount({
    int currentAccountCount = 1,
  }) async => paywallResult;

  @override
  Future<bool> showConnectAccountPaywall({int currentAccountCount = 0}) async =>
      paywallResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'is_demo_mode': true,
      'has_completed_onboarding': true,
    });
  });

  testWidgets(
    'AccountSwitcherBottomSheet renders title, sections, and Add Account action',
    (WidgetTester tester) async {
      final appState = AppState();
      final mockSubscription = MockSubscriptionProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<SubscriptionProvider>.value(
              value: mockSubscription,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AccountSwitcherBottomSheet()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Switch Account'), findsOneWidget);
      expect(find.text('Add Vercel Account'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    },
  );

  testWidgets('Tapping close button closes bottom sheet', (
    WidgetTester tester,
  ) async {
    final appState = AppState();
    final mockSubscription = MockSubscriptionProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          ChangeNotifierProvider<SubscriptionProvider>.value(
            value: mockSubscription,
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AccountSwitcherBottomSheet.show(context),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Switch Account'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Switch Account'), findsNothing);
  });

  testWidgets('The first account uses the normal login flow', (
    WidgetTester tester,
  ) async {
    final appState = AppState();
    final mockSubscription = MockSubscriptionProvider();
    mockSubscription.paywallResult = false;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          ChangeNotifierProvider<SubscriptionProvider>.value(
            value: mockSubscription,
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AccountSwitcherBottomSheet.show(context),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Add Vercel Account'), findsOneWidget);

    // Tap Add Vercel Account
    await tester.tap(find.text('Add Vercel Account'));
    await tester.pumpAndSettle();

    expect(find.text('Connect Your Vercel Account'), findsOneWidget);
    expect(find.text('Connect Another Vercel Account'), findsNothing);
  });

  testWidgets('The first account does not require the add-on flow', (
    WidgetTester tester,
  ) async {
    final appState = AppState();
    final mockSubscription = MockSubscriptionProvider();
    mockSubscription.paywallResult = true;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          ChangeNotifierProvider<SubscriptionProvider>.value(
            value: mockSubscription,
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AccountSwitcherBottomSheet.show(context),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Add Vercel Account'), findsOneWidget);

    // Tap Add Vercel Account
    await tester.tap(find.text('Add Vercel Account'));
    await tester.pumpAndSettle();

    // The first account is not an additional-account purchase.
    expect(find.text('Switch Account'), findsNothing);
    expect(find.text('Connect Your Vercel Account'), findsOneWidget);
  });
}
