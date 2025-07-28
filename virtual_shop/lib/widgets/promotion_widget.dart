import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class PromotionWidget extends StatefulWidget {
  const PromotionWidget({super.key});

  @override
  State<PromotionWidget> createState() => _PromotionWidgetState();
}

class _PromotionWidgetState extends State<PromotionWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late final List<Color> _dominantColors;

  final List<Map<String, String>> _promotions = [
    {
      'title': 'Great Product Collection',
      'subtitle': 'We have the best products',
      'image': 'assets/images/hoodie.jpg',
    },
    {
      'title': 'For Everyone',
      'subtitle': 'You can find something for everyone',
      'image': 'assets/images/glass1.jpg',
    },
    {
      'title': 'Try On',
      'subtitle': 'Virtually try before you buy',
      'image': 'assets/images/profile6.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _dominantColors = List.filled(_promotions.length, Colors.grey[900]!);
    _pageController.addListener(() {
      if (_pageController.page != null) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
    _updateAllPalettes();
  }

  Future<void> _updateAllPalettes() async {
    if (!mounted) return;

    for (int i = 0; i < _promotions.length; i++) {
      final provider = AssetImage(_promotions[i]['image']!);
      try {
        final paletteGenerator = await PaletteGenerator.fromImageProvider(
          provider,
          size: const Size(150, 190), // Specify size for performance
        );
        if (mounted) {
          setState(() {
            _dominantColors[i] =
                paletteGenerator.dominantColor?.color ?? Colors.grey[900]!;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _dominantColors[i] = Colors.grey[900]!;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 190,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _promotions.length,
            itemBuilder: (context, index) {
              final promotion = _promotions[index];
              return PromotionCard(
                title: promotion['title']!,
                subtitle: promotion['subtitle']!,
                image: promotion['image']!,
                dominantColor: _dominantColors[index],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_promotions.length, (index) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class PromotionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final Color dominantColor;

  const PromotionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.dominantColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [dominantColor, dominantColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 110),
                ],
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      dominantColor,
                      dominantColor.withOpacity(1.0),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  image,
                  width: 150,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
