import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';

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

  final int _totalPages = 3;

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
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    await context.read<AppState>().markOnboardingComplete();
  }

  void _showPaywallThenLogin() async {
    try {
      await RevenueCatUI.presentPaywallIfNeeded("pro");
    } catch (e) {
      debugPrint('Paywall error: $e');
    }
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
                physics: const ClampingScrollPhysics(),
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
                        onNext: _showPaywallThenLogin,
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
          'https://github.com/mark-maher-moris/Vero-For-Vercel/blob/main/lib/main.dart'));
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
                  const SizedBox(height: 40),
                  Text(
                    'Fully\nTransparent',
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
                            'View Full Source on GitHub',
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
  final VoidCallback onNext;

  const _GitHubSlide({
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.onNext,
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
                children: [
                  const SizedBox(height: 60),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Icon(
                      Icons.rocket_launch,
                      color: AppTheme.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Ready to\nDeploy?',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Join thousands of developers managing their Vercel deployments with confidence.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                          height: 1.6,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildStatItem('10K+', 'Downloads'),
                            const SizedBox(width: 24),
                            _buildStatItem('4.8★', 'Rating'),
                            const SizedBox(width: 24),
                            _buildStatItem('100%', 'Open'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(
                          color: AppTheme.outlineVariant,
                          height: 1,
                          indent: 0,
                          endIndent: 0,
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () async {
                            final uri = Uri.parse(
                                'https://github.com/mark-maher-moris/Vero-For-Vercel');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.code,
                                color: AppTheme.onSurfaceVariant,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Review the app code',
                                style: TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: onNext,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
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
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'GET STARTED',
                            style: TextStyle(
                              color: AppTheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(
                            Icons.arrow_forward,
                            color: AppTheme.onPrimary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
