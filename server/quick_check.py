"""
QUICK SERVER STATUS CHECK
Run this first to immediately see if the server is working
"""

import requests
import socket

def quick_check():
    print("⚡ QUICK SERVER STATUS CHECK")
    print("=" * 40)
    
    # Test 1: Is anything listening on port 8000?
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        result = sock.connect_ex(('127.0.0.1', 8000))
        sock.close()
        
        if result == 0:
            print("✅ Port 8000: Something is listening")
        else:
            print("❌ Port 8000: Nothing listening")
            print("   → FastAPI server is NOT running")
            return False
    except:
        print("❌ Port 8000: Cannot test")
        return False
    
    # Test 2: Is it responding to HTTP?
    try:
        response = requests.get("http://127.0.0.1:8000/docs", timeout=3)
        if response.status_code == 200:
            print("✅ HTTP Response: Server working!")
            print("   → FastAPI server IS running correctly")
            return True
        else:
            print(f"⚠️  HTTP Response: Status {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ HTTP Response: Connection refused")
        print("   → Something on port 8000 but not HTTP server")
        return False
    except:
        print("❌ HTTP Response: Failed")
        return False

def show_fix_steps():
    print("\n🔧 TO FIX:")
    print("1. Open terminal/command prompt")
    print("2. cd \"e:\\SDP II\\VirtualShop\\server\"")  
    print("3. python -m uvicorn main:app --host 0.0.0.0 --port 8000")
    print("\nThen test your Flutter app again!")

if __name__ == "__main__":
    if not quick_check():
        show_fix_steps()
    else:
        print("\n🎉 Server is working! Try your Flutter app now.")
        print("If Flutter still fails, the issue is:")
        print("- Windows Firewall blocking emulator")
        print("- Antivirus blocking connections") 
        print("- Network configuration issue")