# Product Upload Testing Guide

## Quick Setup and Testing Steps

### 1. Start the FastAPI Server

**Option A: Using the batch file (Recommended)**
```bash
cd "e:\SDP II\VirtualShop\server"
start_server.bat
```

**Option B: Manual startup**
```bash
cd "e:\SDP II\VirtualShop\server"
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Verify Server is Running
- Open browser and go to: http://127.0.0.1:8000/docs
- You should see the FastAPI Swagger documentation
- Look for the `/comprehensive-product/` endpoint

### 3. Test Flutter App

**For Android Emulator:**
- The app will automatically use `http://10.0.2.2:8000`
- Make sure internet permissions are added (already done)

**For iOS Simulator or Desktop:**
- The app will use `http://127.0.0.1:8000`

### 4. Testing Steps
1. Open the Flutter app
2. Navigate to "Add Product" page
3. Fill in all required fields:
   - Product Name
   - Description  
   - Price
   - Category
   - Stock Quantity
   - Condition
4. Select at least one image
5. Click "Add Product"

### 5. Troubleshooting

**If you see "Connection refused" error:**
1. Make sure the FastAPI server is running
2. Check if port 8000 is available
3. Try restarting the server

**If images fail to upload:**
1. Check image file size (should be reasonable)
2. Ensure images are in supported formats (jpg, png)
3. Check server logs for upload errors

**Server Logs Location:**
The server will show logs in the terminal where you started it. Look for:
- `INFO: Uvicorn running on http://0.0.0.0:8000`
- Product creation logs
- Any error messages

### 6. Expected Behavior

**Successful Product Creation:**
1. Form validation passes
2. Images are uploaded successfully
3. Product is saved to database
4. Vector embeddings are generated for images
5. Success message is displayed

**Response Format:**
```json
{
  "success": true,
  "data": {
    "product_id": 123,
    "message": "Product created successfully"
  }
}
```

### 7. Database Verification

You can check if products are created by:
1. Using Supabase dashboard
2. Accessing: http://127.0.0.1:8000/comprehensive-product/ (GET request)
3. Checking the `products` and `product_img` tables

### 8. Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Server won't start | Check if port 8000 is in use, install dependencies |
| Connection refused | Ensure server is running on correct port |
| Image upload fails | Check file size and format |
| Form validation errors | Ensure all required fields are filled |
| Database errors | Check Supabase connection and schema |

## Network Configuration

- **Android Emulator**: Uses `10.0.2.2:8000` (automatically configured)
- **iOS Simulator**: Uses `127.0.0.1:8000`  
- **Desktop/Web**: Uses `127.0.0.1:8000`

The app automatically detects the platform and uses the correct URL.