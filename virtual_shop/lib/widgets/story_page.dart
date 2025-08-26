import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:virtual_shop/models/product.dart';
import 'package:virtual_shop/pages/product_detail_page.dart';
import 'package:virtual_shop/widgets/glass_container.dart';
// import 'package:virtual_shop/widgets/glass_container.dart';

Future<List<Color>> _generatePalette(ImageProvider imageProvider) async {
  final PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
    imageProvider,
  );
  if (generator.dominantColor?.color != null) {
    return [generator.dominantColor!.color, const Color(0xFFFFFFFF)];
  } else {
    return [Colors.blue, Colors.white];
  }
}

class Person {
  final String name;
  final String profileImage;
  final List<Product> products;
  const Person({
    required this.name,
    required this.profileImage,
    required this.products,
  });
}

class Story extends StatefulWidget {
  const Story({super.key});

  @override
  State<Story> createState() => _StoryState();
}

class _StoryState extends State<Story> {
  final Map<String, List<Color>> _colorCache = {};
  List<Color> _allColors = [Colors.blue, Colors.white];
  List<Color> _textColors = [Colors.blue, Colors.white];

  final List<Person> people = [
    Person(
      name: "Arik",
      profileImage: 'assets/images/demo1.jpg',
      products: [
        Product(
          id: 'arik_product_1',
          authId: 'arik_seller_id',
          name: "Arik's Winter Jacket",
          description: 'A nice jacket.',
          category: ProductCategory.cozyWear,
          brand: 'Winter Wear Co.',
          price: 150.00,
          stock: 12,
          condition: ProductCondition.newCondition,
          weightKg: 0.9,
          dimensions: '55x40x8 cm',
          isFeatured: true,
          isInStock: true,
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          image: 'assets/images/demo2.jpg',
          rating: 4.1,
          isLoved: false,
        ),
        Product(
          id: 'arik_product_2',
          authId: 'arik_seller_id',
          name: "Arik's Summer Shirt",
          description: 'A nice shirt.',
          category: ProductCategory.regularWear,
          brand: 'Summer Style',
          price: 75.00,
          stock: 20,
          condition: ProductCondition.newCondition,
          weightKg: 0.3,
          dimensions: '35x25x2 cm',
          isFeatured: false,
          isInStock: true,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          image: 'assets/images/demo1.jpg',
          rating: 4.2,
          isLoved: false,
        ),
        Product(
          id: 'arik_product_3',
          authId: 'arik_seller_id',
          name: "Arik's Fall Coat",
          description: 'A nice coat.',
          category: ProductCategory.formalWear,
          brand: 'Autumn Elegance',
          price: 180.00,
          stock: 8,
          condition: ProductCondition.newCondition,
          weightKg: 1.1,
          dimensions: '60x45x10 cm',
          isFeatured: true,
          isInStock: true,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
          image: 'assets/images/demo3.jpg',
          rating: 4.3,
          isLoved: false,
        ),
        Product(
          id: 'arik_product_4',
          authId: 'arik_seller_id',
          name: "Arik's Clothing Set",
          description: 'A nice set.',
          category: ProductCategory.regularWear,
          brand: 'Complete Wardrobe',
          price: 250.00,
          stock: 5,
          condition: ProductCondition.newCondition,
          weightKg: 1.5,
          dimensions: '50x40x15 cm',
          isFeatured: true,
          isInStock: true,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
          image: 'assets/images/demo4.jpg',
          rating: 4.4,
          isLoved: false,
        ),
      ],
    ),
    Person(
      name: "Aref",
      profileImage: 'assets/images/demo2.jpg',
      products: [
        Product(
          id: 'aref_product_1',
          authId: 'aref_seller_id',
          name: "Aref's Clothing Set",
          description: 'A nice set.',
          category: ProductCategory.formalWear,
          brand: 'Premium Collection',
          price: 300.00,
          stock: 3,
          condition: ProductCondition.newCondition,
          weightKg: 1.8,
          dimensions: '55x45x20 cm',
          isFeatured: true,
          isInStock: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
          image: 'assets/images/demo5.jpg',
          rating: 4.5,
          isLoved: false,
        ),
        Product(
          id: 'aref_product_2',
          authId: 'aref_seller_id',
          name: "Aref's Summer Shirt",
          description: 'A nice shirt.',
          category: ProductCategory.regularWear,
          brand: 'Beach Vibes',
          price: 75.00,
          stock: 15,
          condition: ProductCondition.newCondition,
          weightKg: 0.25,
          dimensions: '35x25x2 cm',
          isFeatured: false,
          isInStock: true,
          createdAt: DateTime.now().subtract(const Duration(days: 12)),
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
          image: 'assets/images/demo1.jpg',
          rating: 4.2,
          isLoved: false,
        ),
      ],
    ),
    Person(
      name: "Samin",
      profileImage: 'assets/images/demo3.jpg',
      products: [
        Product(
          id: 'samin_product_1',
          authId: 'samin_seller_id',
          name: "Samin's Clothing Set",
          description: 'A nice set.',
          category: ProductCategory.cozyWear,
          brand: 'Comfort Plus',
          price: 300.00,
          stock: 6,
          condition: ProductCondition.newCondition,
          weightKg: 1.6,
          dimensions: '50x40x18 cm',
          isFeatured: true,
          isInStock: true,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 10)),
          image: 'assets/images/demo4.jpg',
          rating: 4.5,
          isLoved: false,
        ),
        Product(
          id: 'samin_product_2',
          authId: 'samin_seller_id',
          name: "Samin's Winter Jacket",
          description: 'A nice jacket.',
          category: ProductCategory.cozyWear,
          brand: 'Arctic Warmth',
          price: 150.00,
          stock: 10,
          condition: ProductCondition.newCondition,
          weightKg: 0.95,
          dimensions: '55x40x9 cm',
          isFeatured: false,
          isInStock: true,
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          image: 'assets/images/demo2.jpg',
          rating: 4.1,
          isLoved: false,
        ),
      ],
    ),
  ];

  int selectedPersonIndex = 0;
  int selectedProductIndex = 0;
  late String selectedImage;
  late String selectedName;
  late PageController _pageController;
  late PageController _personPageController;

  @override
  void initState() {
    super.initState();
    selectedImage = people[0].products[0].image;
    selectedName = people[0].products[0].name;
    _pageController = PageController();
    _personPageController = PageController(viewportFraction: 0.25);
    _precachePalettes();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _personPageController.dispose();
    super.dispose();
  }

  Future<void> _precachePalettes() async {
    for (final person in people) {
      for (final product in person.products) {
        if (!_colorCache.containsKey(product.image)) {
          final imageProvider = AssetImage(product.image);
          final colors = await _generatePalette(imageProvider);
          _colorCache[product.image] = colors;
        }
      }
    }
    if (mounted) {
      setState(() {
        final initialColors =
            _colorCache[selectedImage] ?? [Colors.blue, Colors.white];
        _allColors = initialColors;
        _textColors = initialColors;
      });
    }
  }

  void updatePerson(int index) {
    setState(() {
      selectedPersonIndex = index;
      selectedProductIndex = 0;
      selectedImage = people[index].products[0].image;
      selectedName = people[index].products[0].name;
      final newColors =
          _colorCache[selectedImage] ?? [Colors.blue, Colors.white];
      _allColors = newColors;
      _textColors = newColors;
    });
    _pageController.jumpToPage(0);
  }

  void updateProduct(int index) {
    setState(() {
      selectedProductIndex = index;
      selectedImage = people[selectedPersonIndex].products[index].image;
      selectedName = people[selectedPersonIndex].products[index].name;
      final newColors =
          _colorCache[selectedImage] ?? [Colors.blue, Colors.white];
      _allColors = newColors;
      _textColors = newColors;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Gradient titleGradient = LinearGradient(
      colors: _textColors.isNotEmpty
          ? _textColors
          : [Colors.blue, Colors.white],
    );
    final person = people[selectedPersonIndex];
    final products = person.products;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: _allColors.isNotEmpty
                    ? _allColors
                    : [Colors.blue, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds);
            },
            blendMode: BlendMode.modulate,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Image.asset(
                selectedImage,
                key: ValueKey(selectedImage),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: products.length,
                    onPageChanged: (index) {
                      updateProduct(index);
                    },
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final heroTag = 'product_image_${product.image}';
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailPage(product: product),
                            ),
                          );
                        },
                        child: Hero(
                          tag: heroTag,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                product.image,
                                fit: BoxFit.cover,
                                width: 180,
                                height: 180,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  selectedName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.height * 0.04,
                    fontFamily: 'Poppins',
                    foreground: Paint()
                      ..shader = titleGradient.createShader(
                        const Rect.fromLTWH(0, 0, 200, 70),
                      ),
                  ),
                ),
                SizedBox(
                  height: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: List.generate(products.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: selectedProductIndex == index ? 32 : 16,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GlassContainer(
                  width: 56,
                  height: 56,
                  borderRadius: 20,
                  settings: OCLiquidGlassSettings(
                    blendPx: 150,
                    lightbandColor: _allColors.isNotEmpty
                        ? _allColors[0]
                        : Colors.greenAccent,
                    specAngle: 0.0,
                    specStrength: 0.0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        products[selectedProductIndex].isLoved =
                            !products[selectedProductIndex].isLoved;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        products[selectedProductIndex].isLoved
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: products[selectedProductIndex].isLoved
                            ? Colors.redAccent
                            : Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                GlassContainer(
                  width: 56,
                  height: 56,
                  borderRadius: 20,
                  settings: OCLiquidGlassSettings(
                    blendPx: 150,
                    lightbandColor: _allColors.isNotEmpty
                        ? _allColors[0]
                        : Colors.greenAccent,
                    specAngle: 0.0,
                    specStrength: 0.0,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/demo2.jpg',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                GlassContainer(
                  width: 56,
                  height: 56,
                  borderRadius: 20,
                  settings: OCLiquidGlassSettings(
                    blendPx: 150,
                    lightbandColor: _allColors.isNotEmpty
                        ? _allColors[0]
                        : Colors.greenAccent,
                    specAngle: 0.0,
                    specStrength: 0.0,
                  ),
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: PersonSelector(
              people: people,
              selectedIndex: selectedPersonIndex,
              onPersonSelected: updatePerson,
            ),
          ),
          Positioned(
            left: 10,
            right: 0,
            top: 30,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(person.profileImage),
                ),
                const SizedBox(width: 20),
                Text(
                  person.name,
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PersonSelector extends StatelessWidget {
  final List<Person> people;
  final int selectedIndex;
  final void Function(int) onPersonSelected;

  const PersonSelector({
    super.key,
    required this.people,
    required this.selectedIndex,
    required this.onPersonSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: people.length,
        separatorBuilder: (context, index) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final person = people[index];
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onPersonSelected(index),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: CircleAvatar(
                    radius: isSelected ? 27 : 25,
                    backgroundImage: AssetImage(person.profileImage),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  person.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
