import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../services/superwall_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final List<AnimationController> _animationControllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<double>> _slideAnimations;

  final int _totalPages = 5;

  @override
  void initState() {
    super.initState();

    _animationControllers = List.generate(
      _totalPages,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      ),
    );

    _fadeAnimations = _animationControllers
        .map((controller) => Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: controller,
                curve: const Interval(0, 0.6, curve: Curves.easeOut),
              ),
            ))
        .toList();

    _slideAnimations = _animationControllers
        .map((controller) => Tween<double>(begin: 40, end: 0).animate(
              CurvedAnimation(
                parent: controller,
                curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
              ),
            ))
        .toList();

    _animationControllers[0].forward();
    
    // Track onboarding start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SuperwallService().trackScreenView('onboarding', additionalProps: {
        'total_pages': _totalPages,
        'current_page': 0,
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _animationControllers[page].forward(from: 0);
    
    // Track onboarding page view
    final pageNames = ['privacy', 'opensource', 'github_support', 'home_widgets', 'features'];
    SuperwallService().trackUserAction('onboarding_page_view', context: 'onboarding', properties: {
      'page_index': page,
      'page_name': pageNames[page],
      'total_pages': _totalPages,
    });
  }

  void _nextPage() async {
    if (_currentPage == 2) {
      // On Support slide, request review then go to Features
      await _requestReviewThenContinue();
    } else if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // On last page, complete onboarding
      await _showPaywallThenLogin();
    }
  }

  Future<void> _requestReviewThenContinue() async {
    try {
      final inAppReview = InAppReview.instance;
      final isAvailable = await inAppReview.isAvailable();
      debugPrint('InAppReview isAvailable: $isAvailable');
      if (isAvailable) {
        debugPrint('Requesting review...');
        await inAppReview.requestReview();
        debugPrint('Review requested');
      } else {
        debugPrint('InAppReview not available, opening store listing');
        await inAppReview.openStoreListing(appStoreId: '6761316027');
      }
    } catch (e) {
      debugPrint('Review request error: $e');
    }
    // Continue to Features slide after review
    if (mounted) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _showPaywallThenLogin() async {
    // Track onboarding completion
    SuperwallService().trackUserAction('onboarding_complete', context: 'onboarding', properties: {
      'total_pages_viewed': _currentPage + 1,
    });
    
    // Mark onboarding complete first so navigation state updates
    if (mounted) {
      await context.read<AppState>().markOnboardingComplete();
    }
    
    // Register Superwall placement for non-subscribed users
    // This will show the paywall "on top" of the next screen (DemoEntryScreen)
    final isSubscribed = await SuperwallService().getCurrentSubscriptionStatus();
    if (!isSubscribed) {
      await SuperwallService().registerPlacement('after_onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return _PrivacySlide(
                        fadeAnimation: _fadeAnimations[0],
                        slideAnimation: _slideAnimations[0],
                      );
                    case 1:
                      return _OpenSourceSlide(
                        fadeAnimation: _fadeAnimations[1],
                        slideAnimation: _slideAnimations[1],
                      );
                    case 2:
                      return _GitHubSlide(
                        fadeAnimation: _fadeAnimations[2],
                        slideAnimation: _slideAnimations[2],
                      );
                    case 3:
                      return _HomeWidgetsSlide(
                        fadeAnimation: _fadeAnimations[3],
                        slideAnimation: _slideAnimations[3],
                      );
                    case 4:
                      return _FeaturesSlide(
                        fadeAnimation: _fadeAnimations[4],
                        slideAnimation: _slideAnimations[4],
                      );
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: AppTheme.outlineVariant.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              _totalPages,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                width: _currentPage == index ? 24 : 8,
                height: 4,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppTheme.primary
                      : AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Row(
            children: [
              if (_currentPage > 0)
                TextButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('BACK'),
                ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _nextPage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primary,
                        AppTheme.secondaryFixedDim,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentPage == _totalPages - 1 ? 'GET STARTED' : 'NEXT',
                        style: const TextStyle(
                          color: AppTheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (_currentPage == _totalPages - 1) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          color: AppTheme.onPrimary,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrivacySlide extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> slideAnimation;

  const _PrivacySlide({
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, slideAnimation.value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: AppTheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'PRIVACY FIRST',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 40),
                  Text(
                    'Your Data\nStays Yours',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'We built Vero with a single principle: your data belongs to you. Period.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 48),
                  _buildFeatureCard(
                    icon: Icons.cloud_off_outlined,
                    title: 'No Backend',
                    description:
                        'This app connects directly to Vercel\'s official API. No servers, no middlemen.',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.storage_outlined,
                    title: 'No Data Collection',
                    description:
                        'We don\'t store your tokens, deployments, or any personal information.',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.block_outlined,
                    title: 'No Data Sharing',
                    description:
                        'Your data never leaves your device except when communicating with Vercel.',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.verified_outlined,
                    title: 'Official Vercel API',
                    description:
                        'We use Vercel\'s authenticated API endpoints. Your token, your control.',
                  ),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(
              icon,
              color: AppTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenSourceSlide extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> slideAnimation;

  const _OpenSourceSlide({
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  State<_OpenSourceSlide> createState() => _OpenSourceSlideState();
}

class _OpenSourceSlideState extends State<_OpenSourceSlide> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.surfaceContainerLowest)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() => _isLoading = true),
          onPageFinished: (url) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(
          'https://github.com/mark-maher-moris/Vero-For-Vercel'));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: widget.fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, widget.slideAnimation.value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Icon(
                          Icons.code,
                          color: AppTheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'OPEN SOURCE',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Fully Transparent',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Every line of code is open for review. No hidden logic, no secret tracking.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: AppTheme.outlineVariant.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Stack(
                          children: [
                            WebViewWidget(controller: _controller),
                            if (_isLoading)
                              Container(
                                color: AppTheme.surfaceContainerLowest,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(
                          'https://github.com/mark-maher-moris/Vero-For-Vercel');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.open_in_new,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'View Full Code on GitHub',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GitHubSlide extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> slideAnimation;

  const _GitHubSlide({
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, slideAnimation.value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Icon(
                      Icons.star,
                      color: AppTheme.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Support\nThis Project',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Please consider rating Vero to support this open source project and help others discover it.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                          height: 1.6,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeWidgetsSlide extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> slideAnimation;

  const _HomeWidgetsSlide({
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, slideAnimation.value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Icon(
                            Icons.widgets_outlined,
                            color: AppTheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'HOME WIDGETS',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Your Projects\nOn Your Home Screen',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: AppTheme.onSurface,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Add Vero widgets to your home screen for instant access to live stats — no need to open the app.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                    ),
                    const SizedBox(height: 32),
                    _buildWidgetCard(
                      icon: Icons.people_outline,
                      title: 'Users Widget',
                      size: 'Small (2×2)',
                      description:
                          '24h visitors and last-hour online count at a glance.',
                    ),
                    const SizedBox(height: 12),
                    _buildWidgetCard(
                      icon: Icons.terminal_outlined,
                      title: 'Logs Widget',
                      size: 'Medium & Large',
                      description:
                          'Live build and runtime log entries from your latest deployment.',
                    ),
                    const SizedBox(height: 12),
                    _buildWidgetCard(
                      icon: Icons.analytics_outlined,
                      title: 'Analytics Widget',
                      size: 'Large (4×4)',
                      description:
                          'Visitors, bounce rate, and top traffic sources. Requires Vercel Analytics.',
                    ),
                    const SizedBox(height: 12),
                    _buildWidgetCard(
                      icon: Icons.public_outlined,
                      title: 'Geo Traffic Widget',
                      size: 'Medium (4×2)',
                      description:
                          'Top countries driving traffic to your project. Requires Vercel Analytics.',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Widgets require a Pro subscription and show a blur + lock overlay if inactive.',
                              style: const TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWidgetCard({
    required IconData icon,
    required String title,
    required String size,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        size,
                        style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesSlide extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> slideAnimation;

  const _FeaturesSlide({
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, slideAnimation.value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Icon(
                            Icons.apps,
                            color: AppTheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'FEATURES',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Everything You\'ll Get',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: AppTheme.onSurface,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Powerful tools to manage your Vercel infrastructure right from your mobile device.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                    ),
                    const SizedBox(height: 32),
                    _buildFeatureCard(
                      icon: Icons.analytics_outlined,
                      title: 'Analysis',
                      description:
                          'Deep dive into project performance with comprehensive analytics and insights.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.folder_outlined,
                      title: 'Project Management',
                      description:
                          'View, search, and manage all your Vercel projects with real-time status updates.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.rocket_launch_outlined,
                      title: 'One-Touch Deploy',
                      description:
                          'Deploy new projects instantly from templates or import directly from GitHub.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.terminal_outlined,
                      title: 'Live Logs',
                      description:
                          'Monitor deployment logs in real-time with filtering and search capabilities.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.language_outlined,
                      title: 'Domains & DNS',
                      description:
                          'Manage custom domains, configure DNS records, and check SSL certificate status.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.key_outlined,
                      title: 'Environment Variables',
                      description:
                          'Securely add, edit, and sync environment variables across all your projects.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.people_outline,
                      title: 'Team Collaboration',
                      description:
                          'Switch between personal and team accounts with full access control management.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.bar_chart_outlined,
                      title: 'Usage & Billing',
                      description:
                          'Track bandwidth, requests, and billing with detailed analytics dashboards.',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.notifications_outlined,
                      title: 'Activity Feed',
                      description:
                          'Stay updated with real-time notifications for deployments and team activity.',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(
              icon,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
