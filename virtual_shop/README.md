# virtual_shop

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

#connect wirelessly
adb devices

adb -s 0123456789ABCDEF tcpip 5555

adb connect 192.168.0.111:5555

## Backend API

This app talks to the FastAPI server in `../server`.

- Configure environment in `server/.env` (see `server/.env.example`).
- Install and run:

```
python -m venv ../.venv && source ../.venv/bin/activate
pip install -r ../server/requirements.txt
uvicorn server.main:app --reload --host 0.0.0.0 --port 8000
```

## Environment

The Flutter app loads `virtual_shop/.env` via `flutter_dotenv`.

- Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` as required.
- For local backend, set `SERVER_URL` (or `BACKEND_URL`) to your API base, e.g.:

```
SERVER_URL=http://127.0.0.1:8000
```

Notes
- On Android emulators, `127.0.0.1` maps automatically to `10.0.2.2` by the app.
- Ensure there is no space after the scheme: use `http://127.0.0.1:8000` (not `http:// 127.0.0.1:8000`).
- Android manifest allows cleartext HTTP for local development.
