import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../shared/widgets/safe_network_image.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  final List<Map<String, String>> _slides = [
    {
      'title': 'GOURMET\nDELIGHTS',
      'subtitle': 'Elevate your movie night with chef-crafted snacks and gourmet meals.',
      'image': 'https://images.unsplash.com/photo-1594007654729-407eedc4be65?w=1200&q=80',
    },
    {
      'title': 'DIRECT\nTO SEAT',
      'subtitle': 'Order from your phone and we will deliver directly to your velvet seat.',
      'image': 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=1200&q=80',
    },
    {
      'title': 'REWARDS\nPROGRAM',
      'subtitle': 'Earn points on every bite and unlock exclusive cinematic perks.',
      'image': 'https://images.unsplash.com/photo-1541599468348-e96984315621?w=1200&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Stack(
        children: [
          // Carousel Background
          CarouselSlider(
            carouselController: _carouselController,
            options: CarouselOptions(
              height: double.infinity,
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              onPageChanged: (index, reason) {
                setState(() => _currentIndex = index);
              },
            ),
            items: _slides.map((slide) {
              return Builder(
                builder: (BuildContext context) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      SafeNetworkImage(
                        imageUrl: slide['image']!,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.2),
                              Colors.black.withOpacity(0.5),
                              colorScheme.background,
                            ],
                            stops: const [0.0, 0.4, 0.9],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }).toList(),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  // Indicators
                  Row(
                    children: _slides.asMap().entries.map((entry) {
                      return GestureDetector(
                        onTap: () => _carouselController.animateToPage(entry.key),
                        child: Container(
                          width: _currentIndex == entry.key ? 32.0 : 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentIndex == entry.key 
                                ? colorScheme.primary 
                                : colorScheme.onBackground.withOpacity(0.2),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  // Title
                  Text(
                    _slides[_currentIndex]['title']!,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 64,
                      height: 0.9,
                      letterSpacing: -3,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Subtitle
                  Text(
                    _slides[_currentIndex]['subtitle']!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 18,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Actions
                  Column(
                    children: [
                      // Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: () => context.go('/login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'GET STARTED',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
