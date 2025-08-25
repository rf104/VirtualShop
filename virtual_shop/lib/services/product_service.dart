import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ProductService {
  // Use 10.0.2.2 for Android emulator, 127.0.0.1 for iOS simulator or web
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000'; // Android emulator
    } else {
      return 'http://127.0.0.1:8000'; // iOS simulator, web, or desktop
    }
  }
  
  /// Submit a product to the database with all form data and images
  static Future<Map<String, dynamic>> submitProduct({
    required String productName,
    required String description,
    required double price,
    required String category,
    required int stockQuantity,
    required String condition,
    String? brand,
    double? weight,
    String? dimensions,
    bool isRefurbished = false,
    bool inStock = true,
    bool featuredProduct = false,
    int sellerId = 1,
    int categoryId = 1,
    required List<File> images,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/comprehensive-product/');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      
      // Add form fields
      request.fields.addAll({
        'product_name': productName,
        'description': description,
        'price': price.toString(),
        'category': category,
        'stock_quantity': stockQuantity.toString(),
        'condition': condition,
        'is_refurbished': isRefurbished.toString(),
        'in_stock': inStock.toString(),
        'featured_product': featuredProduct.toString(),
        'seller_id': sellerId.toString(),
        'category_id': categoryId.toString(),
      });
      
      // Add optional fields if they are not null
      if (brand != null && brand.isNotEmpty) {
        request.fields['brand'] = brand;
      }
      if (weight != null) {
        request.fields['weight'] = weight.toString();
      }
      if (dimensions != null && dimensions.isNotEmpty) {
        request.fields['dimensions'] = dimensions;
      }
      
      // Add image files
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final multipartFile = await http.MultipartFile.fromPath(
          'images', // Field name in the API
          file.path,
        );
        request.files.add(multipartFile);
      }
      
      print('🚀 Sending request to: ${uri.toString()}');
      print('📝 Form fields: ${request.fields}');
      print('🖼️ Images count: ${request.files.length}');
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📊 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
          'message': 'Product created successfully!'
        };
      } else {
        String errorMessage = 'Unknown error occurred';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['detail'] ?? errorData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = response.body.isNotEmpty ? response.body : 'Server error';
        }
        
        return {
          'success': false,
          'error': errorMessage,
          'message': 'Failed to create product'
        };
      }
    } catch (e) {
      print('❌ Network error: $e');
      
      String errorMessage = 'Network error occurred';
      String troubleshooting = '';
      
      if (e.toString().contains('Connection refused')) {
        errorMessage = 'Cannot connect to server';
        troubleshooting = 'Please ensure the FastAPI server is running at $baseUrl';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Network connection failed';
        troubleshooting = 'Check your internet connection and server status';
      }
      
      return {
        'success': false,
        'error': errorMessage,
        'message': troubleshooting.isNotEmpty ? troubleshooting : 'Network error occurred',
        'details': e.toString(),
      };
    }
  }
  
  /// Get all products
  static Future<Map<String, dynamic>> getAllProducts() async {
    try {
      final uri = Uri.parse('$baseUrl/comprehensive-product/');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch products',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Get a specific product by ID
  static Future<Map<String, dynamic>> getProductById(int productId) async {
    try {
      final uri = Uri.parse('$baseUrl/comprehensive-product/$productId');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'Product not found',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}