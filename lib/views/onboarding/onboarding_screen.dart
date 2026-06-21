import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  static const routeName = '/onboarding';
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _current = 0;

  static const _pages = [
    _OnboardingData(
      icon:        Icons.waving_hand_rounded,
      iconColor:   Color(0xFF5B7EC9),
      title:       'Welcome to\nSmart Institute App',
      description: 'Manage your academic journey easily and access all institute services in one place.',
    ),
    _OnboardingData(
      icon:        Icons.laptop_rounded,
      iconColor:   Color(0xFF5B7EC9),
      title:       'Register Courses\nEasily',
      description: 'Browse available courses, select what you need, and register with just a few taps.',
    ),
    _OnboardingData(
      icon:        Icons.auto_awesome_rounded,
      iconColor:   Color(0xFF5B7EC9),
      title:       'Smart AI\nRecommendations',
      description: 'Get personalized course recommendations based on your academic history and goals.',
    ),
  ];

  void _next() {
    if (_current < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() =>
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Column(children: [
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _PageContent(data: _pages[i]),
          ),
        ),

        // Dots
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(
          _pages.length,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _current == i ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _current == i ? AppColors.primary : AppColors.accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        )),

        const SizedBox(height: 32),

        // Next button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ElevatedButton(
            onPressed: _next,
            child: Text(_current == _pages.length - 1 ? 'Get Started' : 'Next'),
          ),
        ),

        const SizedBox(height: 12),

        // Skip
        TextButton(
          onPressed: _goToLogin,
          child: const Text('Skip', style: TextStyle(
            fontSize: 15, color: AppColors.textGray, fontWeight: FontWeight.w500,
          )),
        ),
        const SizedBox(height: 16),
      ]),
    ),
  );
}

class _PageContent extends StatelessWidget {
  final _OnboardingData data;
  const _PageContent({required this.data});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      // Illustration placeholder with icon
      Container(
        width: 200, height: 200,
        decoration: BoxDecoration(
          color: AppColors.cardBlue.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(data.icon, size: 90, color: data.iconColor),
      ),
      const SizedBox(height: 48),
      Text(
        data.title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 26, fontWeight: FontWeight.w800,
          color: AppColors.textDark, height: 1.3,
          fontFamily: 'Poppins',
        ),
      ),
      const SizedBox(height: 16),
      Text(
        data.description,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15, color: AppColors.textGray,
          height: 1.6, fontFamily: 'Poppins',
        ),
      ),
    ]),
  );
}

class _OnboardingData {
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final String   description;
  const _OnboardingData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });
}
