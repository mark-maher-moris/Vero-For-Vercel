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

  final int _totalPages = 8;

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
      if (mounted) {
        SuperwallService().trackScreenView('onboarding', additionalProps: {
          'total_pages': _totalPages,
          'current_page': 0,
        });
      }
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
    if (mounted) {
      _animationControllers[page].forward(from: 0);
    }
    
    // Track onboarding page view
    final pageNames = [
      'hero',
      'features',
      'interactive_logs',
      'home_widgets',
      'personalization',
      'trust',
      'open_source',
      'github'
    ];
    SuperwallService().trackUserAction('onboarding_page_view', context: 'onboarding', properties: {
      'page_index': page,
      'page_name': pageNames[page],
      'total_pages': _totalPages,
    });
  }

  void _nextPage() async {
    if (_currentPage == 6) {
      // On OpenSource slide, request review then go to last page
      await _requestReviewThenContinue();
    } else if (_currentPage < _totalPages - 1) {
      if (mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    } else {
      // On last page (GitHub slide, index 7), complete onboarding
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
    // 1. Track onboarding completion
    try {
      await SuperwallService().trackUserAction('onboarding_complete', context: 'onboarding', properties: {
        'total_pages_viewed': _currentPage + 1,
      });
    } catch (e) {
      debugPrint('Error tracking onboarding completion: $e');
    }
    
    // 2. Register Superwall placement for non-subscribed users
    // This will show the paywall "on top" of the current screen
    try {
      final isSubscribed = await SuperwallService().getCurrentSubscriptionStatus();
      if (!isSubscribed) {
        await SuperwallService().registerPlacement('after_onboarding');
      }
    } catch (e) {
      debugPrint('Error registering Superwall placement: $e');
    }

    // 3. Mark onboarding complete so navigation state updates in main.dart
    // This will happen in the background, so when the paywall is dismissed, 
    // the user will see the LoginScreen.
    if (mounted) {
      await context.read<AppState>().markOnboardingComplete();
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
                      return _HeroSlide(
                        fadeAnimation: _fadeAnimations[0],
                        slideAnimation: _slideAnimations[0],
                      );
                    case 1:
                      return _FeaturesSlide(
                        fadeAnimation: _fadeAnimations[1],
                        slideAnimation: _slideAnimations[1],
                      );
                    case 2:
                      return _InteractiveLogsSlide(
                        fadeAnimation: _fadeAnimations[2],
                        slideAnimation: _slideAnimations[2],
                      );
                    case 3:
                      return _HomeWidgetsSlide(
                        fadeAnimation: _fadeAnimations[3],
                        slideAnimation: _slideAnimations[3],
                      );
                    case 4:
                      return _PersonalizationSlide(
                        fadeAnimation: _fadeAnimations[4],
                        slideAnimation: _slideAnimations[4],
                      );
                    case 5:
                      return _TrustSlide(
                        fadeAnimation: _fadeAnimations[5],
                        slideAnimation: _slideAnimations[5],
                      );
                    case 6:
                      return _OpenSourceSlide(
                        fadeAnimation: _fadeAnimations[6],
                        slideAnimation: _slideAnimations[6],
                      );
                    case 7:
                      return _GitHubSlide(
                        fadeAnimation: _fadeAnimations[7],
                        slideAnimation: _slideAnimations[7],
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
          Expanded(
            child: Row(
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
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: () {
                      if (mounted) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('BACK', style: TextStyle(fontSize: 13)),
                  ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _nextPage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
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
                          _currentPage == _totalPages - 1 ? 'START' : 'NEXT',
                          style: const TextStyle(
                            color: AppTheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                        if (_currentPage == _totalPages - 1) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward,
                            color: AppTheme.onPrimary,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
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

class _HeroSlide extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> slideAnimation;

  const _HeroSlide({
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  State<_HeroSlide> createState() => _HeroSlideState();
}

class _HeroSlideState extends State<_HeroSlide> with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _badgeFade;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
      ),
    );

    _badgeFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.2),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/logo.png',
                              width: 64,
                              height: 64,
                              color: AppTheme.onPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 60),
                  FadeTransition(
                    opacity: _titleFade,
                    child: Text(
                      'Vero',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: AppTheme.primary,
                            fontSize: 64,
                            letterSpacing: -2,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Text(
                      'Your Vercel Infrastructure\nIn Your Pocket',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  FadeTransition(
                    opacity: _badgeFade,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.outlineVariant.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, color: AppTheme.primary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Powered by Vercel API',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 12,
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

class WidgetOption {
  final IconData icon;
  final String title;
  final String subtitle;

  WidgetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _PersonalizationSlide extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> slideAnimation;

  const _PersonalizationSlide({
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  State<_PersonalizationSlide> createState() => _PersonalizationSlideState();
}

class _PersonalizationSlideState extends State<_PersonalizationSlide>
    with SingleTickerProviderStateMixin {
  bool _realtimeLogs = true;
  bool _favicons = true;
  bool _usersWidget = true;
  bool _logsWidget = true;
  bool _analyticsWidget = false;
  bool _geoWidget = false;

  late AnimationController _staggerController;
  late List<Animation<double>> _cardAnimations;
  late List<Animation<double>> _widgetAnimations;

  final List<WidgetOption> _widgetOptions = [
    WidgetOption(
      icon: Icons.people_outline,
      title: 'Users Widget',
      subtitle: '24h visitors & online count',
    ),
    WidgetOption(
      icon: Icons.terminal_outlined,
      title: 'Logs Widget',
      subtitle: 'Live build & runtime logs',
    ),
    WidgetOption(
      icon: Icons.analytics_outlined,
      title: 'Analytics Widget',
      subtitle: 'Visitors & traffic insights',
    ),
    WidgetOption(
      icon: Icons.public_outlined,
      title: 'Geo Traffic Widget',
      subtitle: 'Top countries by traffic',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardAnimations = List.generate(
      2,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            0.2 + (index * 0.15),
            0.5 + (index * 0.15),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _widgetAnimations = List.generate(
      _widgetOptions.length,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            0.5 + (index * 0.08),
            0.75 + (index * 0.08),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  bool _getWidgetValue(int index) {
    switch (index) {
      case 0:
        return _usersWidget;
      case 1:
        return _logsWidget;
      case 2:
        return _analyticsWidget;
      case 3:
        return _geoWidget;
      default:
        return false;
    }
  }

  void _toggleWidget(int index) {
    setState(() {
      switch (index) {
        case 0:
          _usersWidget = !_usersWidget;
          break;
        case 1:
          _logsWidget = !_logsWidget;
          break;
        case 2:
          _analyticsWidget = !_analyticsWidget;
          break;
        case 3:
          _geoWidget = !_geoWidget;
          break;
      }
    });
  }

  Widget _buildWidgetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceContainerHigh : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.outlineVariant.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(
                      icon: Icons.tune,
                      label: 'PERSONALIZE',
                      title: 'Make It Yours',
                      subtitle: 'Customize your experience before we begin.',
                    ),
                    const SizedBox(height: 40),
                    FadeTransition(
                      opacity: _cardAnimations[0],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.3, 0),
                          end: Offset.zero,
                        ).animate(_cardAnimations[0]),
                        child: _buildSettingCard(
                          title: 'Real-time Console',
                          subtitle: 'Stream logs directly to your device',
                          icon: Icons.terminal,
                          value: _realtimeLogs,
                          onChanged: (val) => setState(() => _realtimeLogs = val),
                        ),
                      ),
                    ),
                  
                    const SizedBox(height: 32),
                    const Text(
                      'HOME SCREEN WIDGETS',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_widgetOptions.length, (index) {
                      final option = _widgetOptions[index];
                      final isSelected = _getWidgetValue(index);
                      return FadeTransition(
                        opacity: _widgetAnimations[index],
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.2, 0),
                            end: Offset.zero,
                          ).animate(_widgetAnimations[index]),
                          child: Padding(
                            padding: EdgeInsets.only(bottom: index < _widgetOptions.length - 1 ? 12 : 0),
                            child: _buildWidgetOption(
                              icon: option.icon,
                              title: option.title,
                              subtitle: option.subtitle,
                              isSelected: isSelected,
                              onTap: () => _toggleWidget(index),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required IconData icon,
    required String label,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                label,
                style: const TextStyle(
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
          title,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
                height: 1.6,
              ),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: AppTheme.outlineVariant.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
            activeTrackColor: AppTheme.primary.withOpacity(0.2),
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

class _OpenSourceSlideState extends State<_OpenSourceSlide>
    with SingleTickerProviderStateMixin {
  late final WebViewController _controller;
  bool _isLoading = true;

  late AnimationController _webViewAnimation;
  late Animation<double> _webViewFade;

  @override
  void initState() {
    super.initState();
    _webViewAnimation = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _webViewFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _webViewAnimation,
        curve: Curves.easeOut,
      ),
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.surfaceContainerLowest)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
              _webViewAnimation.forward();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(
          'https://github.com/mark-maher-moris/Vero-For-Vercel'));
  }

  @override
  void dispose() {
    _webViewAnimation.dispose();
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
                          fontSize: 32,
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
                    child: FadeTransition(
                      opacity: _webViewFade,
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

class _GitHubSlide extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> slideAnimation;

  const _GitHubSlide({
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  State<_GitHubSlide> createState() => _GitHubSlideState();
}

class _GitHubSlideState extends State<_GitHubSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(_pulseAnimation.value * 0.3),
                              blurRadius: 30 * _pulseAnimation.value,
                              spreadRadius: 10 * _pulseAnimation.value,
                            ),
                          ],
                        ),
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
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
                        ),
                      );
                    },
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

class _InteractiveLogsSlide extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> slideAnimation;

  const _InteractiveLogsSlide({
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  State<_InteractiveLogsSlide> createState() => _InteractiveLogsSlideState();
}

class _InteractiveLogsSlideState extends State<_InteractiveLogsSlide>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _isPaused = false;
  int _logIndex = 0;

  late AnimationController _containerAnimation;
  late Animation<double> _containerFade;
  late Animation<Offset> _containerSlide;

  final List<Map<String, dynamic>> _mockLogs = [
    {'method': 'GET', 'path': '/api/health', 'status': 200, 'time': '10:42:01'},
    {'method': 'GET', 'path': '/api/v1/user', 'status': 200, 'time': '10:42:03'},
    {'method': 'POST', 'path': '/api/v1/auth/login', 'status': 200, 'time': '10:42:05'},
    {'method': 'GET', 'path': '/api/v1/projects', 'status': 200, 'time': '10:42:08'},
    {'method': 'GET', 'path': '/api/v1/deployments', 'status': 200, 'time': '10:42:15'},
    {'method': 'POST', 'path': '/api/v1/deploy', 'status': 201, 'time': '10:42:22'},
    {'method': 'GET', 'path': '/api/v1/analytics', 'status': 200, 'time': '10:42:25'},
    {'method': 'PUT', 'path': '/api/v1/env-vars', 'status': 200, 'time': '10:42:28'},
    {'method': 'GET', 'path': '/api/v1/domains', 'status': 200, 'time': '10:42:35'},
    {'method': 'DELETE', 'path': '/api/v1/cache', 'status': 200, 'time': '10:42:38'},
    {'method': 'GET', 'path': '/api/v1/logs', 'status': 200, 'time': '10:42:42'},
    {'method': 'POST', 'path': '/api/v1/webhook', 'status': 200, 'time': '10:42:45'},
    {'method': 'GET', 'path': '/api/v1/metrics', 'status': 200, 'time': '10:43:01'},
    {'method': 'PATCH', 'path': '/api/v1/config', 'status': 200, 'time': '10:43:01'},
    {'method': 'GET', 'path': '/api/v1/status', 'status': 200, 'time': '10:43:02'},
    {'method': 'GET', 'path': '/api/v1/timeout', 'status': 504, 'time': '10:43:15'},
  ];

  @override
  void initState() {
    super.initState();
    _containerAnimation = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _containerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _containerAnimation,
        curve: Curves.easeOut,
      ),
    );

    _containerSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _containerAnimation,
        curve: Curves.easeOutCubic,
      ),
    );

    _containerAnimation.forward();
    _startLogStream();
  }

  void _startLogStream() async {
    while (mounted) {
      if (!_isPaused) {
        if (mounted) {
          setState(() {
            _logs.add(_mockLogs[_logIndex]);
            _logIndex = (_logIndex + 1) % _mockLogs.length;
            if (_logs.length > 50) _logs.removeAt(0);
          });
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
      await Future.delayed(Duration(milliseconds: _isPaused ? 500 : 1200));
    }
  }

  @override
  void dispose() {
    _containerAnimation.dispose();
    _scrollController.dispose();
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
                  _buildHeader(),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _containerFade,
                    child: SlideTransition(
                      position: _containerSlide,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.outlineVariant.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.45,
                            child: Column(
                              children: [
                                // Header row
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceContainerLow,
                                    border: Border(
                                      bottom: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.3)),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          'Time',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Request',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Log list
                                Expanded(
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _logs.length,
                                    itemBuilder: (context, index) {
                                      final log = _logs[index];
                                      return _buildLogEntry(log, index % 2 == 0);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'TAP A LOG ITEM TO SEE DETAILS',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.terminal, size: 16, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'RUNTIME LOGS',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
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
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Real-time Logs',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.bold,
                height: 1.1,
                fontSize: 32,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Monitor your infrastructure with zero latency. Every request, every error, in real-time.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
                height: 1.4,
              ),
        ),
      ],
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> log, bool isEven) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-20 * (1 - value), 0),
            child: InkWell(
              onTap: () => _showLogDetail(log),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isEven ? AppTheme.surfaceContainerLow.withOpacity(0.3) : AppTheme.surface,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timestamp
                    SizedBox(
                      width: 70,
                      child: Text(
                        log['time'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: AppTheme.onSurfaceVariant,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Method badge + Path + Status
                    Expanded(
                      child: Row(
                        children: [
                          // Method badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getMethodColor(log['method']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log['method'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getMethodColor(log['method']),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Path
                          Expanded(
                            child: Text(
                              log['path'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status code
                          Text(
                            log['status'].toString(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(log['status']),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Color(0xFF22C55E);
      case 'POST':
        return const Color(0xFF3B82F6);
      case 'PUT':
        return const Color(0xFFF59E0B);
      case 'DELETE':
        return const Color(0xFFEF4444);
      case 'PATCH':
        return const Color(0xFF8B5CF6);
      default:
        return AppTheme.onSurfaceVariant;
    }
  }

  Color _getStatusColor(int status) {
    if (status >= 200 && status < 300) return const Color(0xFF22C55E);
    if (status >= 300 && status < 400) return const Color(0xFFF59E0B);
    if (status >= 400 && status < 500) return const Color(0xFFEF4444);
    if (status >= 500) return const Color(0xFF7C3AED);
    return AppTheme.onSurfaceVariant;
  }

  void _showLogDetail(Map<String, dynamic> log) {
    if (!mounted) return;
    setState(() => _isPaused = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'LOG DETAIL',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.primary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildDetailRow('METHOD', log['method']),
            const SizedBox(height: 16),
            _buildDetailRow('PATH', log['path']),
            const SizedBox(height: 16),
            _buildDetailRow('STATUS', log['status'].toString()),
            const SizedBox(height: 16),
            _buildDetailRow('TIMESTAMP', '2026-05-20 ${log['time']}'),
            const SizedBox(height: 16),
            _buildDetailRow('DURATION', '${(100 + (log['status'] % 500))}ms'),
            const SizedBox(height: 16),
            _buildDetailRow('USER AGENT', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'),
            const SizedBox(height: 16),
            _buildDetailRow('IP ADDRESS', '192.168.1.${100 + (log['status'] % 155)}'),
            const SizedBox(height: 16),
            _buildDetailRow('REGION', 'us-east-1'),
            const SizedBox(height: 16),
            _buildDetailRow('CACHE STATUS', log['status'] == 200 ? 'HIT' : 'MISS'),
            const SizedBox(height: 16),
            _buildDetailRow('SOURCE', 'Edge Function (lhr1)'),
            const SizedBox(height: 16),
            _buildDetailRow('REQUEST ID', 'req_${log['status']}f2s9dk3l40sm1'),
            const SizedBox(height: 32),
            const Text(
              'REQUEST HEADERS',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow('host', 'api.example.com'),
                  _buildHeaderRow('user-agent', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'),
                  _buildHeaderRow('accept', 'application/json'),
                  _buildHeaderRow('content-type', 'application/json'),
                  _buildHeaderRow('authorization', 'Bearer eyJhbGciOiJIUzI1NiIs...'),
                  _buildHeaderRow('x-vercel-id', 'lhr1_abc123'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'RESPONSE HEADERS',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow('content-type', 'application/json'),
                  _buildHeaderRow('cache-control', 'public, max-age=3600'),
                  _buildHeaderRow('x-vercel-cache', 'HIT'),
                  _buildHeaderRow('server', 'Vercel'),
                  _buildHeaderRow('x-response-time', '${(100 + (log['status'] % 500))}ms'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('DISMISS'),
              ),
            ),
          ],
        ),
        ),
      ),
    ).then((_) => setState(() => _isPaused = false));
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 16,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$key:',
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.onSurface,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustSlide extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> slideAnimation;

  const _TrustSlide({
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  State<_TrustSlide> createState() => _TrustSlideState();
}

class _TrustSlideState extends State<_TrustSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  late List<Animation<double>> _cardAnimations;
  late Animation<double> _ctaAnimation;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardAnimations = List.generate(
      3,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            0.2 + (index * 0.15),
            0.5 + (index * 0.15),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _ctaAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(
                      icon: Icons.verified_user,
                      label: 'TRUST & SECURITY',
                      title: 'Built on Trust',
                      subtitle: 'We respect your privacy and the community.',
                    ),
                    const SizedBox(height: 48),
                    FadeTransition(
                      opacity: _cardAnimations[0],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0),
                          end: Offset.zero,
                        ).animate(_cardAnimations[0]),
                        child: _buildTrustCard(
                          icon: Icons.shield_outlined,
                          title: 'No Data Collection',
                          description: 'We don\'t store your tokens, deployments, or any personal information. Period.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _cardAnimations[1],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0),
                          end: Offset.zero,
                        ).animate(_cardAnimations[1]),
                        child: _buildTrustCard(
                          icon: Icons.code,
                          title: 'Open Source',
                          description: 'Every line of code is open for review on GitHub. Transparent and secure.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _cardAnimations[2],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0),
                          end: Offset.zero,
                        ).animate(_cardAnimations[2]),
                        child: _buildTrustCard(
                          icon: Icons.cloud_off,
                          title: 'No Backend',
                          description: 'Direct Vercel API connection. No middlemen, no tracking.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Center(
                      child: FadeTransition(
                        opacity: _ctaAnimation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1.0).animate(_ctaAnimation),
                          child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHigh.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.star, color: AppTheme.primary, size: 32),
                              const SizedBox(height: 16),
                              const Text(
                                'Support the Project',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                             
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required IconData icon,
    required String label,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                label,
                style: const TextStyle(
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
          title,
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontSize: 44,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildTrustCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
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
    );
  }
}

class _HomeWidgetsSlide extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> slideAnimation;

  const _HomeWidgetsSlide({
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  State<_HomeWidgetsSlide> createState() => _HomeWidgetsSlideState();
}

class _HomeWidgetsSlideState extends State<_HomeWidgetsSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  late List<Animation<double>> _imageAnimations;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _imageAnimations = List.generate(
      3,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            0.2 + (index * 0.1),
            0.5 + (index * 0.1),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _cardAnimations = List.generate(
      4,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            0.5 + (index * 0.125),
            0.75 + (index * 0.0625),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
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
                    Column(
                      children: [
                        FadeTransition(
                          opacity: _imageAnimations[0],
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.9, end: 1.0).animate(_imageAnimations[0]),
                            child: _buildWidgetImage('assets/small-visitors-widgets.png'),
                          ),
                        ),
                        const SizedBox(height: 6),
                        FadeTransition(
                          opacity: _imageAnimations[1],
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.9, end: 1.0).animate(_imageAnimations[1]),
                            child: _buildWidgetImage('assets/countries-widget.png'),
                          ),
                        ),
                        const SizedBox(height: 6),
                        FadeTransition(
                          opacity: _imageAnimations[2],
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.9, end: 1.0).animate(_imageAnimations[2]),
                            child: _buildWidgetImage('assets/large-analysis-widget.png', height: 280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    FadeTransition(
                      opacity: _cardAnimations[0],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.3, 0),
                          end: Offset.zero,
                        ).animate(_cardAnimations[0]),
                        child: _buildWidgetCard(
                          icon: Icons.people_outline,
                          title: 'Users Widget',
                          size: 'Small (2×2)',
                          description:
                              '24h visitors and last-hour online count at a glance.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _cardAnimations[1],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.3, 0),
                          end: Offset.zero,
                        ).animate(_cardAnimations[1]),
                        child: _buildWidgetCard(
                          icon: Icons.terminal_outlined,
                          title: 'Logs Widget',
                          size: 'Medium & Large',
                          description:
                              'Live build and runtime log entries from your latest deployment.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _cardAnimations[2],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.3, 0),
                          end: Offset.zero,
                        ).animate(_cardAnimations[2]),
                        child: _buildWidgetCard(
                          icon: Icons.analytics_outlined,
                          title: 'Analytics Widget',
                          size: 'Large (4×4)',
                          description:
                              'Visitors, bounce rate, and top traffic sources. Requires Vercel Analytics.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _cardAnimations[3],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.3, 0),
                          end: Offset.zero,
                        ).animate(_cardAnimations[3]),
                        child: _buildWidgetCard(
                          icon: Icons.public_outlined,
                          title: 'Geo Traffic Widget',
                          size: 'Medium (4×2)',
                          description:
                              'Top countries driving traffic to your project. Requires Vercel Analytics.',
                        ),
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

  Widget _buildWidgetImage(String assetPath, {double height = 220}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: AppTheme.outlineVariant.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Transform.rotate(
          angle: 10 * 3.14159 / 180,
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  Icons.broken_image,
                  color: AppTheme.onSurfaceVariant.withOpacity(0.3),
                  size: 32,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FeaturesSlide extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> slideAnimation;

  const _FeaturesSlide({
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  State<_FeaturesSlide> createState() => _FeaturesSlideState();
}

class _FeaturesSlideState extends State<_FeaturesSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _cardAnimations = List.generate(
      9,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            0.3 + (index * 0.05),
            0.6 + (index * 0.05),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
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
                    FadeTransition(
                      opacity: _cardAnimations[0],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0),
                          end: Offset.zero,
                        ).animate(_cardAnimations[0]),
                        child: _buildFeatureCard(
                          icon: Icons.analytics_outlined,
                          title: 'Analysis',
                          description:
                              'Deep dive into project performance with comprehensive analytics and insights.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _cardAnimations[1],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0),
                          end: Offset.zero,
                        ).animate(_cardAnimations[1]),
                        child: _buildFeatureCard(
                          icon: Icons.folder_outlined,
                          title: 'Project Management',
                          description:
                              'View, search, and manage all your Vercel projects with real-time status updates.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _cardAnimations[2],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0),
                          end: Offset.zero,
                        ).animate(_cardAnimations[2]),
                        child: _buildFeatureCard(
                          icon: Icons.rocket_launch_outlined,
                          title: 'One-Touch Deploy',
                          description:
                              'Deploy new projects instantly from templates or import directly from GitHub.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _cardAnimations[3],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0),
                          end: Offset.zero,
                        ).animate(_cardAnimations[3]),
                        child: _buildFeatureCard(
                          icon: Icons.terminal_outlined,
                          title: 'Live Logs',
                          description:
                              'Monitor deployment logs in real-time with filtering and search capabilities.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _cardAnimations[4],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0),
                          end: Offset.zero,
                        ).animate(_cardAnimations[4]),
                        child: _buildFeatureCard(
                          icon: Icons.language_outlined,
                          title: 'Domains & DNS',
                          description:
                              'Manage custom domains, configure DNS records, and check SSL certificate status.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _cardAnimations[5],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0),
                          end: Offset.zero,
                        ).animate(_cardAnimations[5]),
                        child: _buildFeatureCard(
                          icon: Icons.key_outlined,
                          title: 'Environment Variables',
                          description:
                              'Securely add, edit, and sync environment variables across all your projects.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _cardAnimations[6],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0),
                          end: Offset.zero,
                        ).animate(_cardAnimations[6]),
                        child: _buildFeatureCard(
                          icon: Icons.people_outline,
                          title: 'Team Collaboration',
                          description:
                              'Switch between personal and team accounts with full access control management.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _cardAnimations[7],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0),
                          end: Offset.zero,
                        ).animate(_cardAnimations[7]),
                        child: _buildFeatureCard(
                          icon: Icons.bar_chart_outlined,
                          title: 'Usage & Billing',
                          description:
                              'Track bandwidth, requests, and billing with detailed analytics dashboards.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _cardAnimations[8],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0),
                          end: Offset.zero,
                        ).animate(_cardAnimations[8]),
                        child: _buildFeatureCard(
                          icon: Icons.notifications_outlined,
                          title: 'Activity Feed',
                          description:
                              'Stay updated with real-time notifications for deployments and team activity.',
                        ),
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
