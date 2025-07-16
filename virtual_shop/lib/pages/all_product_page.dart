import 'package:flutter/material.dart';
import 'package:virtual_shop/models/product.dart';
import 'package:virtual_shop/pages/product_detail_page.dart';

class AllProductPage extends StatefulWidget {
  const AllProductPage({super.key});

  @override
  State<AllProductPage> createState() => _AllProductPageState();
}

class _AllProductPageState extends State<AllProductPage> {
  final List<Product> products = [
    Product(
      name: 'Winter Shearling Jacket',
      image: 'assets/images/hoodie.jpg',
      rating: 4.1,
      price: 120.00,
      category: 'Cozy Wear',
      weather: 'Rainy',
      temp: '16-22°C',
      event: 'Promenade',
      description:
          'Elevate your winter wardrobe with this luxurious white shearling jacket, paired with a chic black turtleneck and matching skirt. Perfect for a stylish day out, this outfit combines comfort and high fashion, ensuring you stay warm and turn heads wherever you go.',
    ),
    Product(
      name: 'Casual Chic Ensemble',
      image: 'assets/images/hat1.jpg',
      rating: 4.1,
      price: 85.50,
      category: 'Regular Wear',
      weather: 'Neutral',
      temp: '16-22°C',
      event: 'Promenade',
      description:
          'Step out in style with this casual chic ensemble featuring a trendy hat.',
    ),
    Product(
      name: 'Urban Explorer Outfit',
      image: 'assets/images/shoe.jpg',
      rating: 4.9,
      price: 215.00,
      category: 'Cozy Wear',
      weather: 'Rainy',
      temp: '16-22°C',
      event: 'Promenade',
      description:
          'Gear up for your next adventure with this urban explorer outfit, featuring a rugged jacket, durable boots, and practical cargo pants. Designed for comfort and functionality, this outfit is perfect for exploring the city or enjoying a weekend getaway.',
    ),
  ];

  String _selectedWeather = 'Rainy';
  String _selectedTemp = '16-22°C';
  String _selectedEvent = 'Promenade';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              // const SizedBox(height: 20),
              // _buildFilterChips(),
              const SizedBox(height: 20),
              Expanded(child: _buildProductGrid()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.shopping_bag_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Shop',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Row(
          children: [_buildHeaderButton('Items', products.length.toString())],
        ),
      ],
    );
  }

  Widget _buildHeaderButton(String title, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 5),
          Text(
            count,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return const TextField(
      decoration: InputDecoration(
        hintText: 'Type to search...',
        prefixIcon: Icon(Icons.search),
        suffixIcon: Icon(Icons.filter_list),
      ),
    );
  }

  // Widget _buildFilterChips() {
  //   return SingleChildScrollView(
  //     scrollDirection: Axis.horizontal,
  //     child: Row(
  //       children: [
  //         _buildFilterChip('Weather', _selectedWeather, (newValue) {
  //           setState(() {
  //             _selectedWeather = newValue;
  //           });
  //         }),
  //         const SizedBox(width: 10),
  //         _buildFilterChip('Temp', _selectedTemp, (newValue) {
  //           setState(() {
  //             _selectedTemp = newValue;
  //           });
  //         }),
  //         const SizedBox(width: 10),
  //         _buildFilterChip('Event', _selectedEvent, (newValue) {
  //           setState(() {
  //             _selectedEvent = newValue;
  //           });
  //         }),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildFilterChip(
  //   String label,
  //   String value,
  //   ValueChanged<String> onSelected,
  // ) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).inputDecorationTheme.fillColor,
  //       borderRadius: BorderRadius.circular(20),
  //     ),
  //     child: Row(
  //       children: [
  //         Text('$label: $value', style: Theme.of(context).textTheme.bodySmall),
  //         const SizedBox(width: 4),
  //         const Icon(Icons.close, size: 14),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildProductGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(product: product),
              ),
            );
          },
          child: Hero(
            tag: product.image,
            child: ProductCard(product: product),
          ),
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              product.image,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          product.category,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '\৳${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    product.rating.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
