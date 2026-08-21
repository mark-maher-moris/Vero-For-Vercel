// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:in_app_review_platform_interface/in_app_review_platform_interface.dart';
import 'package:vero/providers/app_state.dart';
import 'package:vero/screens/onboarding_screen.dart';

class MockWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return MockPlatformWebViewController(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return MockPlatformWebViewWidget(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return MockPlatformNavigationDelegate(params);
  }
}

class MockPlatformWebViewController extends PlatformWebViewController {
  MockPlatformWebViewController(super.params) : super.implementation();

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}
}

class MockPlatformWebViewWidget extends PlatformWebViewWidget {
  MockPlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: Key('mock_webview'));
  }
}

class MockPlatformNavigationDelegate extends PlatformNavigationDelegate {
  MockPlatformNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}
}

class MockInAppReviewPlatform extends InAppReviewPlatform {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> requestReview() async {}

  @override
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_completed_onboarding': false,
    });
    WebViewPlatform.instance = MockWebViewPlatform();
    InAppReviewPlatform.instance = MockInAppReviewPlatform();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  Widget createTestWidget({required AppState appState}) {
    return MaterialApp(
      home: ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const OnboardingScreen(),
      ),
    );
  }

  Future<void> advancePage(WidgetTester tester) async {
    await tester.tap(find.text('NEXT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> previousPage(WidgetTester tester) async {
    await tester.tap(find.text('BACK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets(
    'iOS onboarding omits rating slide and routes cleanly across 4 slides',
    (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final appState = AppState();

        await tester.pumpWidget(createTestWidget(appState: appState));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Slide 1: Privacy
        expect(find.text('PRIVACY FIRST'), findsOneWidget);
        expect(find.text('Your Data\nStays Yours'), findsOneWidget);
        expect(find.text('NEXT'), findsOneWidget);
        expect(find.text('BACK'), findsNothing);

        // Tap NEXT -> Slide 2: Open Source
        await advancePage(tester);
        expect(find.text('OPEN SOURCE'), findsOneWidget);
        expect(find.text('Fully Transparent'), findsOneWidget);
        expect(find.text('BACK'), findsOneWidget);

        // Tap NEXT -> Slide 3: Home Widgets
        await advancePage(tester);
        expect(find.text('HOME WIDGETS'), findsOneWidget);
        expect(find.text('Your Projects\nOn Your Home Screen'), findsOneWidget);

        // Tap NEXT -> Slide 4: Features (Rating slide MUST be omitted on iOS)
        await advancePage(tester);
        expect(find.text('Support\nThis Project'), findsNothing);
        expect(find.text('FEATURES'), findsOneWidget);
        expect(find.text('Everything You\'ll Get'), findsOneWidget);
        expect(find.text('GET STARTED'), findsOneWidget);
        expect(find.text('NEXT'), findsNothing);

        // Test back routing on iOS: Features -> Home Widgets -> Open Source -> Privacy
        await previousPage(tester);
        expect(find.text('HOME WIDGETS'), findsOneWidget);

        await previousPage(tester);
        expect(find.text('OPEN SOURCE'), findsOneWidget);

        await previousPage(tester);
        expect(find.text('PRIVACY FIRST'), findsOneWidget);
        expect(find.text('BACK'), findsNothing);

        // Navigate forward back to Features
        await advancePage(tester);
        await advancePage(tester);
        await advancePage(tester);
        expect(find.text('GET STARTED'), findsOneWidget);

        // Complete onboarding
        await tester.tap(find.text('GET STARTED'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(appState.hasCompletedOnboarding, isTrue);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'Android onboarding includes rating slide and routes across 5 slides',
    (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final appState = AppState();

        await tester.pumpWidget(createTestWidget(appState: appState));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Slide 1: Privacy
        expect(find.text('PRIVACY FIRST'), findsOneWidget);
        expect(find.text('NEXT'), findsOneWidget);

        // Slide 2: Open Source
        await advancePage(tester);
        expect(find.text('OPEN SOURCE'), findsOneWidget);

        // Slide 3: Home Widgets
        await advancePage(tester);
        expect(find.text('HOME WIDGETS'), findsOneWidget);

        // Slide 4: Rating / Support Project slide (Present on Android)
        await advancePage(tester);
        expect(find.text('Support\nThis Project'), findsOneWidget);
        expect(find.text('NEXT'), findsOneWidget);

        // Slide 5: Features
        await advancePage(tester);
        expect(find.text('FEATURES'), findsOneWidget);
        expect(find.text('GET STARTED'), findsOneWidget);

        // Complete onboarding
        await tester.tap(find.text('GET STARTED'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(appState.hasCompletedOnboarding, isTrue);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
