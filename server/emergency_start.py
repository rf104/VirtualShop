"""
Emergency Server Startup and Diagnostics Script
This will help us identify exactly what's happening with the connection.
"""

import subprocess
import sys
import os
import time
import threading
import requests
from pathlib import Path

def check_if_server_running():
    """Check if FastAPI server is already running"""
    try:
        response = requests.get("http://127.0.0.1:8000/docs", timeout=3)
        if response.status_code == 200:
            return True
    except:
        pass
    
    try:
        response = requests.get("http://10.0.2.2:8000/docs", timeout=3)
        if response.status_code == 200:
            return True
    except:
        pass
    
    return False

def check_port_usage():
    """Check what's using port 8000"""
    try:
        if os.name == 'nt':  # Windows
            result = subprocess.run(['netstat', '-ano', '|', 'findstr', ':8000'], 
                                  shell=True, capture_output=True, text=True)
            print("Port 8000 usage:")
            print(result.stdout if result.stdout else "Port 8000 appears to be free")
        else:  # Unix/Linux/Mac
            result = subprocess.run(['lsof', '-i', ':8000'], 
                                  capture_output=True, text=True)
            print("Port 8000 usage:")
            print(result.stdout if result.stdout else "Port 8000 appears to be free")
    except Exception as e:
        print(f"Could not check port usage: {e}")

def install_dependencies():
    """Install required dependencies"""
    print("🔧 Installing/updating dependencies...")
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"], 
                      check=True, cwd=".")
        print("✅ Dependencies installed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to install dependencies: {e}")
        return False

def start_server_direct():
    """Start the server directly with maximum verbosity"""
    print("🚀 Starting FastAPI server with maximum verbosity...")
    
    try:
        # Change to server directory
        server_dir = Path(__file__).parent
        os.chdir(server_dir)
        print(f"Working directory: {server_dir}")
        
        # Start server with maximum logging
        cmd = [
            sys.executable, "-m", "uvicorn", "main:app",
            "--host", "0.0.0.0",
            "--port", "8000", 
            "--reload",
            "--log-level", "debug",
            "--access-log"
        ]
        
        print(f"Command: {' '.join(cmd)}")
        print("=" * 60)
        print("🌐 Server will be accessible at:")
        print("   - Desktop/Web: http://127.0.0.1:8000")
        print("   - Android Emulator: http://10.0.2.2:8000")
        print("   - API Docs: http://127.0.0.1:8000/docs")
        print("=" * 60)
        print("Press Ctrl+C to stop the server")
        print()
        
        # Start the server
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, 
                                 stderr=subprocess.STDOUT, 
                                 text=True, bufsize=1, universal_newlines=True)
        
        # Monitor server output
        while True:
            output = process.stdout.readline()
            if output == '' and process.poll() is not None:
                break
            if output:
                print(output.strip())
                
                # Check if server started successfully
                if "Uvicorn running on" in output:
                    print("\n🎉 SERVER STARTED SUCCESSFULLY!")
                    print("Now test the Flutter app...")
                    
        return_code = process.poll()
        if return_code:
            print(f"❌ Server exited with code {return_code}")
        
    except KeyboardInterrupt:
        print("\n👋 Server stopped by user")
    except Exception as e:
        print(f"❌ Error starting server: {e}")

def test_connection_after_start():
    """Test connection after server should be running"""
    print("\n🔍 Testing server connectivity...")
    
    # Wait a moment for server to fully start
    time.sleep(2)
    
    test_urls = [
        "http://127.0.0.1:8000/docs",
        "http://10.0.2.2:8000/docs",
        "http://127.0.0.1:8000/comprehensive-product/",
        "http://10.0.2.2:8000/comprehensive-product/"
    ]
    
    for url in test_urls:
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                print(f"✅ {url} - Working")
            else:
                print(f"❌ {url} - Status: {response.status_code}")
        except requests.exceptions.ConnectionError:
            print(f"❌ {url} - Connection refused")
        except Exception as e:
            print(f"❌ {url} - Error: {e}")

def main():
    """Main troubleshooting function"""
    print("🔍 FastAPI Server Troubleshooting & Startup")
    print("=" * 60)
    
    # Check current status
    if check_if_server_running():
        print("✅ Server appears to be running already!")
        test_connection_after_start()
        return
    
    print("❌ Server is not running. Let's start it...")
    
    # Check port usage
    check_port_usage()
    print()
    
    # Install dependencies
    if not install_dependencies():
        return
    
    print()
    
    # Start server
    start_server_direct()

if __name__ == "__main__":
    main()