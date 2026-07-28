import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/storage_service.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _page = PageController();
  int _index = 0;

  static const _pages = [
    _PageData(
      imageAsset: 'assets/onboarding/privacy.jpg',
      title: 'Private by default',
      body:
          'Your files stay on this device. No account required — and no ads watching what you do.',
      accent: AppColors.seed,
    ),
    _PageData(
      imageAsset: 'assets/onboarding/offline.jpg',
      title: 'Built for offline',
      body:
          'Merge PDFs, scan codes, compress images, and run everyday utilities without uploading to the cloud.',
      accent: AppColors.qr,
    ),
    _PageData(
      imageAsset: 'assets/onboarding/favorites.jpg',
      title: 'Pin what you use',
      body:
          'Favorite tools for quick access, and optionally add a OneToolkit widget to your home screen.',
      accent: AppColors.text,
    ),
  ];

  Future<void> _finish() async {
    await Get.find<StorageService>().write(AppConstants.keyOnboardingDone, true);
    Get.offAllNamed(AppRoutes.shell);
  }

  void _next() {
    if (_index >= _pages.length - 1) {
      _finish();
      return;
    }
    _page.nextPage(
      duration: AppSpace.motion,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _index == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: page.accent.withValues(alpha: 0.06),
                                  ),
                                  child: Image.asset(
                                    page.imageAsset,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppConstants.appName,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          page.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.body,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodyLarge?.color
                                ?.withValues(alpha: 0.72),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: AppSpace.motion,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(last ? 'Get started' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  const _PageData({
    required this.imageAsset,
    required this.title,
    required this.body,
    required this.accent,
  });

  final String imageAsset;
  final String title;
  final String body;
  final Color accent;
}
