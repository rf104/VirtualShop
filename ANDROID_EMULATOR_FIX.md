# Android Emulator Network Connectivity Troubleshooting Guide

## The Problem
The Flutter app is getting "Software caused connection abort" error when trying to connect to the FastAPI server from Android emulator.

## Root Cause
The server was configured to bind to `127.0.0.1` which only accepts local connections. Android emulator needs the server to bind to `0.0.0.0` to accept connections from `10.0.2.2`.

## Solution Steps

### 1. ✅ FIXED - Server Configuration
Updated `start_server.py` and `start_server.bat` to use:
```python
host="0.0.0.0"  # Instead of "127.0.0.1"
```

### 2. ✅ FIXED - Flutter Network Configuration  
Updated `product_service.dart` to automatically detect platform:
- Android Emulator: `http://10.0.2.2:8000`
- iOS/Desktop: `http://127.0.0.1:8000`

### 3. ✅ FIXED - Android Permissions
Added to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## Testing Steps

### Step 1: Start the Server (CRITICAL)
```bash
cd "e:\SDP II\VirtualShop\server"
python start_server.py
```

You should see:
```
📱 Android emulator will connect to: http://10.0.2.2:8000
🖥️  Desktop/iOS will connect to: http://127.0.0.1:8000
🌐 API docs available at: http://127.0.0.1:8000/docs
```

### Step 2: Verify Server Accessibility
```bash
python test_connectivity.py
```

This will test all connection scenarios.

### Step 3: Test Flutter App
1. Make sure Android emulator is running
2. Open the Flutter app
3. Navigate to "Add Product" page
4. Fill all required fields
5. Select images
6. Click "Add Product"

## Expected vs Actual Behavior

### ✅ Expected (Fixed)
```
Server binding to: 0.0.0.0:8000
Flutter connects to: 10.0.2.2:8000
Connection: SUCCESS
```

### ❌ Previous Issue
```
Server binding to: 127.0.0.1:8000
Flutter connects to: 10.0.2.2:8000  
Connection: REFUSED (because 127.0.0.1 ≠ 0.0.0.0)
```

## Network Architecture

```
Android Emulator Network:
┌─────────────────────┐    ┌──────────────────────┐
│   Flutter App       │───▶│   10.0.2.2:8000      │
│   (Android Emulator)│    │   (Emulator Gateway) │
└─────────────────────┘    └──────────────────────┘
                                      │
                                      ▼
┌─────────────────────┐    ┌──────────────────────┐
│   FastAPI Server    │◀───│   0.0.0.0:8000       │
│   (Host Machine)    │    │   (All Interfaces)   │
└─────────────────────┘    └──────────────────────┘
```

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Connection Refused | Server not running or wrong host binding |
| Timeout | Server taking too long, check performance |
| Permission Denied | Missing internet permissions (fixed) |
| Wrong URL | Platform detection issue (fixed) |

## Verification Commands

Test server from host machine:
```bash
curl http://127.0.0.1:8000/docs
curl http://10.0.2.2:8000/docs  # This should also work now
```

## Next Steps After Starting Server

1. ✅ Verify server starts successfully
2. ✅ Test connectivity with `test_connectivity.py`
3. ✅ Open Flutter app in Android emulator
4. ✅ Test product upload functionality
5. ✅ Check server logs for successful requests