# URGENT: Android Emulator Connection Issue Fix

## The Issue
You're getting `Software caused connection abort (errno = 103)` when the Flutter app tries to connect to the FastAPI server. This error means:

1. **Connection is established** (TCP handshake succeeds)
2. **Connection is immediately terminated** (server drops the connection)

## Why This Happens

### Common Causes:
1. **Server not running** - Most likely cause
2. **Firewall blocking connections** 
3. **Server binding to wrong interface** (127.0.0.1 vs 0.0.0.0)
4. **Port already in use by another service**
5. **Server crashing on request**

## STEP-BY-STEP FIX

### Step 1: Kill Any Existing Processes
```bash
# Windows
taskkill /f /im python.exe
# Or check what's using port 8000
netstat -ano | findstr :8000
```

### Step 2: Run Emergency Diagnostics
```bash
cd "e:\SDP II\VirtualShop\server"
python diagnose_connection.py
```

This will test:
- ✅ Raw socket connections
- ✅ HTTP endpoints  
- ✅ Multipart requests (simulating Flutter)

### Step 3: Start Minimal Test Server
```bash
cd "e:\SDP II\VirtualShop\server"
python minimal_server.py
```

This runs a bare-bones server to isolate the issue.

### Step 4: Test Minimal Server
Open browser and test:
- http://127.0.0.1:8000/test
- http://10.0.2.2:8000/test (if on emulator)

### Step 5: If Minimal Server Works, Start Full Server
```bash
cd "e:\SDP II\VirtualShop\server"
python emergency_start.py
```

This will:
- ✅ Install all dependencies
- ✅ Check port usage
- ✅ Start server with maximum logging
- ✅ Test all endpoints

## Expected Output When Working

### Server Startup:
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [####]
INFO:     Started server process [####]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

### Flutter App Success:
```
I/flutter: 🚀 Sending request to: http://10.0.2.2:8000/comprehensive-product/
I/flutter: 📊 Response status: 200
I/flutter: Product submitted successfully
```

## If Still Not Working

### Check Windows Firewall
1. Open Windows Defender Firewall
2. Click "Allow an app through firewall"
3. Add Python.exe if not listed
4. Enable for both Private and Public networks

### Check Antivirus
Some antivirus software blocks local server connections:
1. Temporarily disable real-time protection
2. Test the connection
3. Add exception for Python/FastAPI if it works

### Alternative Port Test
If port 8000 is problematic, try port 8080:

Update server startup:
```python
uvicorn.run(app, host="0.0.0.0", port=8080)
```

Update Flutter service:
```dart
static String get baseUrl {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8080'; // Changed port
  } else {
    return 'http://127.0.0.1:8080';
  }
}
```

## Quick Test Commands

### Test if server is responding:
```bash
curl http://127.0.0.1:8000/docs
curl http://10.0.2.2:8000/docs
```

### Test multipart upload:
```bash
curl -X POST http://10.0.2.2:8000/comprehensive-product/ \
  -F "product_name=test" \
  -F "description=test" \
  -F "price=10.0" \
  -F "category=Electronics" \
  -F "stock_quantity=1" \
  -F "condition=New" \
  -F "images=@test.jpg"
```

## NEXT STEPS FOR YOU

1. **Run diagnostics**: `python diagnose_connection.py`
2. **Start minimal server**: `python minimal_server.py`  
3. **Test in browser**: http://127.0.0.1:8000/test
4. **If working, start full server**: `python emergency_start.py`
5. **Test Flutter app again**

The key is to isolate whether it's a networking issue or an application issue. The diagnostic tools will tell us exactly what's happening.