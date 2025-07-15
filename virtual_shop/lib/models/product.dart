class Product {
  final String name;
  final String image;
  final double rating;
  final double price;
  final String category;
  final String weather;
  final String temp;
  final String event;
  final String description;
  bool isLoved;

  Product({
    required this.name,
    required this.image,
    required this.rating,
    required this.price,
    required this.category,
    required this.weather,
    required this.temp,
    required this.event,
    required this.description,
    this.isLoved = false,
  });
}
