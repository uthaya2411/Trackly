import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../providers/expense_provider.dart';
import '../widgets/glass_card.dart';
import 'auth_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentIndex < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Mark onboarding completed and push to AuthScreen
      ref.read(expenseProvider.notifier).completeOnboarding();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Background Glows
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.ambientGlow),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: AppColors.premiumGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.wallet_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'TRACKLY PRO',
                            style: textTheme.titleMedium?.copyWith(
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(expenseProvider.notifier)
                              .completeOnboarding();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const AuthScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Skip',
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main PageView Slides
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (idx) {
                      setState(() {
                        _currentIndex = idx;
                      });
                    },
                    children: [
                      _buildSlide(
                        title: 'Track Wealth\nWith Precision',
                        subtitle:
                            'Log your income and expenses instantly using our optimized neon input panels and smart tag classifiers.',
                        visualWidget: _buildSlide1Visual(),
                        textTheme: textTheme,
                      ),
                      _buildSlide(
                        title: 'Visualize Cash Flow\nIn Real-Time',
                        subtitle:
                            'Gain rich cognitive clarity with custom-curated pie, weekly trend bars, and spending velocity line graphs.',
                        visualWidget: _buildSlide2Visual(),
                        textTheme: textTheme,
                      ),
                      _buildSlide(
                        title: 'Sync Globally & Securely',
                        subtitle:
                            'Connect our production-ready Firebase authentication and database engine for seamless multi-device backups.',
                        visualWidget: _buildSlide3Visual(),
                        textTheme: textTheme,
                      ),
                    ],
                  ),
                ),

                // Bottom Page Control and Button Section
                Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    children: [
                      // Dots Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final isSelected = _currentIndex == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isSelected ? 24 : 6,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? AppColors.premiumGradient
                                  : null,
                              color: isSelected
                                  ? null
                                  : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),

                      // Elegant Action Button
                      GestureDetector(
                        onTap: _onNext,
                        child: Container(
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: AppColors.premiumGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 18,
                                spreadRadius: -2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _currentIndex == 2
                                  ? 'Begin Wealth Journey'
                                  : 'Continue',
                              style: textTheme.labelLarge?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide({
    required String title,
    required String subtitle,
    required Widget visualWidget,
    required TextTheme textTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Center(child: visualWidget)),
          const SizedBox(height: 20),
          Text(
            title,
            style: textTheme.displayMedium?.copyWith(
              height: 1.2,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 14.5,
              height: 1.5,
              color: Colors.white.withOpacity(0.55),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // Slide 1 Visual: Glassmorphic Transaction Cards Floating
  Widget _buildSlide1Visual() {
    return SizedBox(
      width: 320,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.roseGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Zodiak Gourmet Diner',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Food Category',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '-₹3,200.00',
                      style: TextStyle(
                        color: AppColors.expense,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Transform.scale(
                scale: 0.9,
                child: GlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.emeraldGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.wallet_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Monthly retainer payout',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Salary Inflow',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        '+₹1,25,000.00',
                        style: TextStyle(
                          color: AppColors.income,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
  }

  // Slide 2 Visual: Elegant Visual Chart Preview
  Widget _buildSlide2Visual() {
    return SizedBox(
      width: 320,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: SizedBox(
          width: 320,
          child: GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Weekly Inflow Velocity',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.income.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '+38.5%',
                        style: TextStyle(
                          color: AppColors.income,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Animated Bar Indicators mockup
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _mockBar(32.0, AppColors.roseGradient),
                    _mockBar(48.0, AppColors.cyanGradient),
                    _mockBar(76.0, AppColors.premiumGradient),
                    _mockBar(52.0, AppColors.emeraldGradient),
                    _mockBar(98.0, AppColors.roseGradient),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mockBar(double height, LinearGradient grad) {
    return Container(
      width: 14,
      height: height,
      decoration: BoxDecoration(
        gradient: grad,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // Slide 3 Visual: Interactive Database Cloud Sync nodes
  Widget _buildSlide3Visual() {
    return SizedBox(
      width: 320,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // AWS central node card
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Left Device Node
                  _mockNodeIcon(Icons.phone_iphone_rounded, 'iPhone'),
                  const SizedBox(width: 8),
                  // Pulsing center lock
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.sync_rounded,
                      color: AppColors.secondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Right Database Node
                  _mockNodeIcon(Icons.cloud_done_rounded, 'Firebase'),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'SECURED VIA SSL CLIENT HANDSHAKE',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 9,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mockNodeIcon(IconData icon, String name) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
