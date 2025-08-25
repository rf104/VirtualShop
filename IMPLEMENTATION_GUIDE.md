# Product Upload Implementation Guide

This guide explains how to test the comprehensive product upload system that integrates Flutter app with FastAPI backend and Supabase database.

## 🎯 Overview

The implementation includes:
- **Flutter Frontend**: Enhanced `AddProductPage` with comprehensive form fields
- **FastAPI Backend**: New `/comprehensive-product/` endpoint with image upload and embedding generation
- **Database Integration**: Extended product table schema with additional fields
- **Vector Embeddings**: Automatic generation and storage of image embeddings for search functionality

## 🚀 Quick Start

### 1. Backend Setup

```bash
# Navigate to server directory
cd "e:\SDP II\VirtualShop\server"

# Install dependencies
pip install -r requirements.txt

# Start the server (includes schema check)
python start_server.py
```

### 2. Test API Endpoints

```bash
# Test the comprehensive product API
python test_comprehensive_product.py
```

### 3. Flutter App

1. Open the Flutter project in VS Code
2. Run the app: `flutter run`
3. Navigate to Add Product page
4. Fill in all fields and upload images
5. Click "Add Product"

## 📋 Required Fields

### Form Fields
- **Product Name** (required)
- **Description** (required)
- **Price** (required, float)
- **Category** (dropdown: Electronics, Fashion, etc.)
- **Stock Quantity** (required, integer)
- **Condition** (dropdown: New, Like New, Good, Fair, Poor)
- **Brand** (optional)
- **Weight** (optional, float in kg)
- **Dimensions** (optional, string like "20 x 15 x 10 cm")

### Settings
- **Featured Product** (boolean toggle)
- **In Stock** (boolean toggle)

### Images
- **1-5 product images** (required, JPG/PNG)

## 🔧 API Endpoints

### Create Product
```http
POST /comprehensive-product/
Content-Type: multipart/form-data

Fields:
- product_name: string
- description: string
- price: float
- category: string
- stock_quantity: integer
- condition: string
- brand: string (optional)
- weight: float (optional)
- dimensions: string (optional)
- is_refurbished: boolean
- in_stock: boolean
- featured_product: boolean
- seller_id: integer (default: 1)
- category_id: integer (default: 1)
- images: file[] (1-5 images)
```

### Get All Products
```http
GET /comprehensive-product/
```

### Get Product by ID
```http
GET /comprehensive-product/{product_id}
```

## 🗄️ Database Schema

The `product` table includes these fields:
```sql
-- Existing fields
product_id BIGINT PRIMARY KEY
created_at TIMESTAMP
seller_id BIGINT
category_id BIGINT
product_name VARCHAR
description VARCHAR
price DOUBLE PRECISION
is_refurbished BOOLEAN

-- New fields added automatically
category VARCHAR
brand VARCHAR
stock_quantity INTEGER DEFAULT 0
condition VARCHAR
weight REAL
dimensions VARCHAR
in_stock BOOLEAN DEFAULT FALSE
featured_product BOOLEAN DEFAULT FALSE
```

The `product_img` table stores image URLs:
```sql
img_id BIGINT PRIMARY KEY
created_at TIMESTAMP
product_id BIGINT (FK to product)
img_url VARCHAR
type VARCHAR
```

## 🔍 Vector Embeddings

Images are automatically processed for similarity search:
- **Model**: CLIP-ViT-B-32 for generating 512-dimensional embeddings
- **Storage**: Supabase vector database (`product_images` collection)
- **Metadata**: Includes product_id, image_url, and type
- **Search**: Enables visual product search functionality

## ✅ Testing Checklist

### Backend Tests
- [ ] Server starts successfully
- [ ] Database schema is updated correctly
- [ ] API endpoints respond correctly
- [ ] Image upload works
- [ ] Embeddings are generated and stored
- [ ] Product data is saved to database

### Frontend Tests
- [ ] Form validation works correctly
- [ ] Image picker allows 1-5 images
- [ ] All form fields are captured
- [ ] HTTP request is sent correctly
- [ ] Success/error messages are displayed
- [ ] Product creation succeeds

### Integration Tests
- [ ] End-to-end product creation flow
- [ ] Image files are uploaded and stored
- [ ] Product data appears in database
- [ ] Vector embeddings are created
- [ ] Product can be retrieved via API

## 🚨 Troubleshooting

### Common Issues

1. **Server won't start**
   - Check database connection string
   - Ensure all dependencies are installed
   - Verify Supabase credentials

2. **Image upload fails**
   - Check file size limits
   - Verify image format (JPG/PNG)
   - Ensure uploads directory exists

3. **Database errors**
   - Run schema checker manually: `python schema_checker.py`
   - Check Supabase connection
   - Verify table permissions

4. **Flutter app errors**
   - Check API endpoint URL in `product_service.dart`
   - Verify HTTP permissions in app
   - Check network connectivity

### Debug Mode

Enable debug logging by setting environment variable:
```bash
export FASTAPI_DEBUG=true
```

## 📊 Response Examples

### Successful Product Creation
```json
{
  "product_id": 123,
  "created_at": "2025-01-22T10:30:00Z",
  "seller_id": 1,
  "category_id": 1,
  "product_name": "Wireless Headphones",
  "description": "High-quality wireless headphones with noise cancellation",
  "price": 199.99,
  "is_refurbished": false,
  "category": "Electronics",
  "brand": "TechCorp",
  "stock_quantity": 50,
  "condition": "New",
  "weight": 0.3,
  "dimensions": "18 x 15 x 8 cm",
  "in_stock": true,
  "featured_product": true,
  "image_urls": [
    "/uploads/products/abc123_headphones1.jpg",
    "/uploads/products/def456_headphones2.jpg"
  ]
}
```

### Error Response
```json
{
  "detail": "At least one product image is required"
}
```

## 📚 Additional Notes

- Images are stored locally in `/uploads/products/` directory
- In production, consider using Supabase Storage for images
- Vector embeddings enable advanced search features
- All operations are asynchronous for better performance
- CORS is enabled for cross-origin requests from Flutter app