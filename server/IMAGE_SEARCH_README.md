# Image Search API

This FastAPI application provides image search functionality using CLIP embeddings and vector similarity search.

## Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Make sure your `.env` file contains the `SUPABASE_DB_URL`:
```
SUPABASE_DB_URL=your_database_connection_string_here
```

3. Make sure you have seeded the database with images using the backend image search script first.

## Running the API

```bash
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

## API Endpoints

### POST `/image-search/search`
Search for similar images using a base64 encoded image.

**Request Body:**
```json
{
    "base64_image": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ...",
    "limit": 3
}
```

**Response:**
```json
{
    "image_ids": ["demo1", "demo3", "demo2"],
    "message": "Found 3 similar images"
}
```

### GET `/image-search/health`
Health check endpoint for the image search service.

## API Documentation

Once the server is running, visit:
- Swagger UI: http://127.0.0.1:8000/docs
- ReDoc: http://127.0.0.1:8000/redoc
