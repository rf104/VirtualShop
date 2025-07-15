import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:async';
import 'package:virtual_shop/models/product.dart';

import 'package:virtual_shop/pages/product_detail_page.dart';

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
  List<Color> allColors = [];
  List<Color> textColors = [];
  bool _isMenuOpen = false;

  final List<Person> people = [
    Person(
      name: "Arik",
      profileImage: 'assets/images/demo1.jpg',
      products: [
        Product(
          image: 'assets/images/demo2.jpg',
          name: "Arik's Winter Jacket",
          rating: 4.1,
          price: 150.00,
          category: 'Cozy Wear',
          weather: 'Rainy',
          temp: '16-22°C',
          event: 'Promenade',
          description: 'A nice jacket.',
        ),
        Product(
          image: 'assets/images/demo1.jpg',
          name: "Arik's Summer Shirt",
          rating: 4.2,
          price: 75.00,
          category: 'Cozy Wear',
          weather: 'Sunny',
          temp: '25-30°C',
          event: 'Beach',
          description: 'A nice shirt.',
        ),
        Product(
          image: 'assets/images/demo3.jpg',
          name: "Arik's Fall Coat",
          rating: 4.3,
          price: 180.00,
          category: 'Cozy Wear',
          weather: 'Cloudy',
          temp: '10-15°C',
          event: 'Walk',
          description: 'A nice coat.',
        ),
        Product(
          image: 'assets/images/demo4.jpg',
          name: "Arik's Clothing Set",
          rating: 4.4,
          price: 250.00,
          category: 'Cozy Wear',
          weather: 'Any',
          temp: 'Any',
          event: 'Any',
          description: 'A nice set.',
        ),
      ],
    ),
    Person(
      name: "Aref",
      profileImage: 'assets/images/demo2.jpg',
      products: [
        Product(
          image: 'assets/images/demo5.jpg',
          name: "Aref's Clothing Set",
          rating: 4.5,
          price: 300.00,
          category: 'Cozy Wear',
          weather: 'Any',
          temp: 'Any',
          event: 'Any',
          description: 'A nice set.',
        ),
        Product(
          image: 'assets/images/demo1.jpg',
          name: "Aref's Summer Shirt",
          rating: 4.2,
          price: 75.00,
          category: 'Cozy Wear',
          weather: 'Sunny',
          temp: '25-30°C',
          event: 'Beach',
          description: 'A nice shirt.',
        ),
      ],
    ),
    Person(
      name: "Samin",
      profileImage: 'assets/images/demo3.jpg',
      products: [
        Product(
          image: 'assets/images/demo4.jpg',
          name: "Samin's Clothing Set",
          rating: 4.5,
          price: 300.00,
          category: 'Cozy Wear',
          weather: 'Any',
          temp: 'Any',
          event: 'Any',
          description: 'A nice set.',
        ),
        Product(
          image: 'assets/images/demo2.jpg',
          name: "Samin's Winter Jacket",
          rating: 4.1,
          price: 150.00,
          category: 'Cozy Wear',
          weather: 'Rainy',
          temp: '16-22°C',
          event: 'Promenade',
          description: 'A nice jacket.',
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
    _updatePalette();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _personPageController.dispose();
    super.dispose();
  }

  Future<void> _updatePalette() async {
    final ImageProvider imageProvider = AssetImage(selectedImage);
    final List<Color> colors = await _generatePalette(imageProvider);
    if (!mounted) return;
    setState(() {
      allColors = colors;
      textColors = colors;
    });
  }

  void updatePerson(int index) {
    setState(() {
      selectedPersonIndex = index;
      selectedProductIndex = 0;
      selectedImage = people[index].products[0].image;
      selectedName = people[index].products[0].name;
    });
    _pageController.jumpToPage(0);
    _updatePalette();
  }

  void updateProduct(int index) {
    setState(() {
      selectedProductIndex = index;
      selectedImage = people[selectedPersonIndex].products[index].image;
      selectedName = people[selectedPersonIndex].products[index].name;
    });
    _updatePalette();
  }

  @override
  Widget build(BuildContext context) {
    final Gradient titleGradient = LinearGradient(
      colors: textColors.isNotEmpty ? textColors : [Colors.blue, Colors.white],
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
                colors: allColors.isNotEmpty
                    ? allColors
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
                AnimatedOpacity(
                  opacity: _isMenuOpen ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Visibility(
                    visible: _isMenuOpen,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              products[selectedProductIndex].isLoved =
                                  !products[selectedProductIndex].isLoved;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              products[selectedProductIndex].isLoved
                                  ? 'assets/images/love.png'
                                  : 'assets/images/unlove.png',
                              width: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/demo2.jpg',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 15),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'assets/images/cart.png',
                              width: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMenuOpen = !_isMenuOpen;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      _isMenuOpen
                          ? 'assets/images/menu_open.png'
                          : 'assets/images/menu_closed.png',
                      width: 24,
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
