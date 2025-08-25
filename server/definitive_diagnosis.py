"""
DEFINITIVE SERVER STATUS CHECKER
This will tell us exactly what's happening with the server
"""

import socket
import subprocess
import sys
import os
import time
import requests
from pathlib import Path

def check_port_detailed():
    """Check what's actually using port 8000"""
    print("🔍 CHECKING PORT 8000 STATUS...")
    print("=" * 50)
    
    try:
        # Check if anything is listening on port 8000
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        result = sock.connect_ex(('127.0.0.1', 8000))
        sock.close()
        
        if result == 0:
            print("✅ Something IS listening on port 8000")
            
            # Find out what process is using it
            if os.name == 'nt':  # Windows
                try:
                    cmd = ['netstat', '-ano', '|', 'findstr', ':8000']
                    result = subprocess.run(' '.join(cmd), shell=True, 
                                          capture_output=True, text=True)
                    if result.stdout:
                        print("📊 Port 8000 usage details:")
                        print(result.stdout)
                        
                        # Extract PID and get process name
                        lines = result.stdout.strip().split('\n')
                        for line in lines:
                            if ':8000' in line and 'LISTENING' in line:
                                parts = line.split()
                                if len(parts) >= 5:
                                    pid = parts[-1]
                                    try:
                                        tasklist_cmd = f'tasklist /fi "pid eq {pid}"'
                                        tasklist_result = subprocess.run(tasklist_cmd, shell=True,
                                                                       capture_output=True, text=True)
                                        print(f"🔍 Process using port 8000:")
                                        print(tasklist_result.stdout)
                                    except:
                                        print(f"PID using port 8000: {pid}")
                    else:
                        print("⚠️  Port appears busy but can't identify process")
                except Exception as e:
                    print(f"❌ Error checking port usage: {e}")
        else:
            print("❌ NOTHING is listening on port 8000")
            print("   This means the FastAPI server is definitely NOT running")
            
    except Exception as e:
        print(f"❌ Error checking port: {e}")

def test_actual_server_response():
    """Test if there's actually a working HTTP server"""
    print("\n🔍 TESTING HTTP SERVER RESPONSE...")
    print("=" * 50)
    
    test_urls = [
        "http://127.0.0.1:8000",
        "http://127.0.0.1:8000/docs", 
        "http://127.0.0.1:8000/comprehensive-product/"
    ]
    
    server_responding = False
    
    for url in test_urls:
        try:
            print(f"Testing: {url}")
            response = requests.get(url, timeout=3)
            print(f"✅ SUCCESS - Status: {response.status_code}")
            if response.status_code == 200:
                server_responding = True
            print(f"   Response preview: {response.text[:100]}...")
        except requests.exceptions.ConnectionError:
            print(f"❌ CONNECTION REFUSED - No server running")
        except requests.exceptions.Timeout:
            print(f"❌ TIMEOUT - Server not responding")
        except Exception as e:
            print(f"❌ ERROR: {e}")
        print()
    
    return server_responding

def check_python_processes():
    """Check if any Python processes are running that might be our server"""
    print("\n🔍 CHECKING PYTHON PROCESSES...")
    print("=" * 50)
    
    try:
        if os.name == 'nt':  # Windows
            cmd = 'tasklist /fi "imagename eq python.exe"'
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if "python.exe" in result.stdout:
                print("🐍 Python processes found:")
                print(result.stdout)
            else:
                print("❌ NO Python processes running")
                print("   This confirms the FastAPI server is not running")
    except Exception as e:
        print(f"❌ Error checking Python processes: {e}")

def attempt_server_start():
    """Try to start the server and see what happens"""
    print("\n🚀 ATTEMPTING TO START SERVER...")
    print("=" * 50)
    
    server_dir = Path(__file__).parent
    os.chdir(server_dir)
    
    print(f"Working directory: {server_dir}")
    
    # Check if main.py exists
    if not Path("main.py").exists():
        print("❌ main.py not found in current directory")
        print(f"   Current files: {list(Path('.').glob('*.py'))}")
        return False
    
    print("✅ main.py found")
    
    try:
        print("Starting server with: uvicorn main:app --host 0.0.0.0 --port 8000")
        
        # Start server in background and capture output
        cmd = [sys.executable, "-m", "uvicorn", "main:app", 
               "--host", "0.0.0.0", "--port", "8000"]
        
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, 
                                 stderr=subprocess.PIPE, text=True)
        
        # Wait a few seconds for startup
        print("⏳ Waiting for server to start...")
        time.sleep(5)
        
        # Check if process is still running
        if process.poll() is None:
            print("✅ Server process started successfully!")
            print("   Process ID:", process.pid)
            
            # Test if it's responding
            time.sleep(2)
            if test_actual_server_response():
                print("🎉 SERVER IS NOW WORKING!")
                return True
            else:
                print("❌ Server started but not responding to HTTP requests")
        else:
            stdout, stderr = process.communicate()
            print("❌ Server process exited")
            print("STDOUT:", stdout)
            print("STDERR:", stderr)
            
    except FileNotFoundError:
        print("❌ uvicorn not found. Installing...")
        subprocess.run([sys.executable, "-m", "pip", "install", "uvicorn[standard]"])
        print("   Try running the server manually after this completes")
    except Exception as e:
        print(f"❌ Error starting server: {e}")
    
    return False

def main():
    """Run comprehensive diagnostics"""
    print("🔍 DEFINITIVE SERVER DIAGNOSIS")
    print("=" * 60)
    print("This will tell us EXACTLY what's wrong")
    print("=" * 60)
    
    # Step 1: Check port status
    check_port_detailed()
    
    # Step 2: Test HTTP responses
    server_working = test_actual_server_response()
    
    # Step 3: Check Python processes
    check_python_processes()
    
    # Final diagnosis
    print("\n" + "=" * 60)
    print("🎯 DIAGNOSIS:")
    
    if server_working:
        print("✅ Server IS running and responding!")
        print("   The issue is elsewhere (firewall, network, etc.)")
        print("   Try the Flutter app now.")
    else:
        print("❌ Server is NOT running!")
        print("   This is why you're getting connection abort errors.")
        print("   The Android emulator connects to a dead socket.")
        
        # Step 4: Try to start server
        print("\n🔧 ATTEMPTING AUTOMATIC FIX...")
        if attempt_server_start():
            print("🎉 FIXED! Server is now running. Test your Flutter app!")
        else:
            print("❌ Could not start server automatically.")
            print("\n📋 MANUAL STEPS REQUIRED:")
            print("1. cd \"e:\\SDP II\\VirtualShop\\server\"")
            print("2. pip install -r requirements.txt")
            print("3. python -m uvicorn main:app --host 0.0.0.0 --port 8000")
    
    print("=" * 60)

if __name__ == "__main__":
    main()