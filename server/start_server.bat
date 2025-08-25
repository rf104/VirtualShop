@echo off
echo Starting FastAPI server...
cd /d "e:\SDP II\VirtualShop\server"
echo Installing dependencies if needed...
pip install -r requirements.txt
echo.
echo Starting server on http://0.0.0.0:8000
echo For Android emulator, the app will connect to http://10.0.2.2:8000
echo For Desktop/iOS, use http://127.0.0.1:8000
echo.
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload