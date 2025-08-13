# Image Search with Supabase Vector Database

This project implements semantic image search using OpenAI's CLIP model and Supabase cloud vector database. You can search for images using either text descriptions or other images.

## Prerequisites

1. **Supabase Account** - Create a free account at [supabase.com](https://supabase.com)
2. **Python 3.13+** - For running the Python backend
3. **Poetry** - For dependency management

## Setup Instructions

### 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new account
2. Click "New Project" 
3. Choose your organization
4. Enter project name (e.g., "virtual-shop-image-search")
5. Enter a database password (save this password!)
6. Choose a region close to you
7. Click "Create new project"

### 2. Enable the pgvector Extension

1. In your Supabase dashboard, go to **Database** → **Extensions**
2. Search for "vector"
3. Click "Enable" next to the **vector** extension
4. Wait for it to be enabled (shows a green checkmark)

### 3. Get Your Database Connection String

1. In your Supabase dashboard, click the **Connect** button (top right)
2. Choose **Connection parameters** or **URI**
3. Copy the **Transaction** connection string (recommended for this use case)
4. It will look like: 
   ```
   postgresql://postgres.PROJECT_REF:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres
   ```

### 4. Configure Environment Variables

Update the `.env` file in the backend directory with your actual Supabase connection string:

```env
# Replace with your actual Supabase connection string
SUPABASE_DB_URL=postgresql://postgres.PROJECT_REF:[YOUR_PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres
```

**Important**: Replace the placeholders:
- `PROJECT_REF` - Your project reference ID
- `[YOUR_PASSWORD]` - The database password you set when creating the project
- `[REGION]` - Your project's region (e.g., us-east-1, eu-west-1)

### 5. Install Python Dependencies

Navigate to the backend directory and install dependencies:

```powershell
cd backend
poetry install
```

## Usage

### 1. Test Your Connection

First, verify that your connection works:

```powershell
# Activate the virtual environment
poetry shell

# Run the test script
python test_setup.py
```

This will verify:
- Database connection to Supabase cloud
- CLIP model loading
- Image file availability
- Image encoding capability

### 2. Seed the Database

Populate the database with image embeddings:

```powershell
# Run the seed function
python -c "from image_serach import seed; seed()"
```

This will:
- Create a vector collection called "image_vectors"
- Generate embeddings for demo images using CLIP
- Store the embeddings in your Supabase database
- Create an index for fast search

### 3. Search by Text

Run a text-to-image search:

```powershell
python -c "from image_serach import search; search()"
```

This will search for images matching the text query and display the result.

### 4. Search by Image

You can also search programmatically using the available functions:

```python
from image_serach import search_by_image, search_flexible

# Search for similar images using an image
results = search_by_image("../assets/images/demo1.jpg", limit=3)

# Flexible search (text or image)
results = search_flexible(query="a person wearing clothes")
results = search_flexible(image_path="../assets/images/demo2.jpg")
```

## Database Connection

### Supabase Cloud (Recommended)

The project is configured to work with Supabase cloud. Your connection string should look like:

```
# Transaction pooler (recommended for this use case)
postgresql://postgres.PROJECT_REF:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres

# Or direct connection (if you need persistent connections)
postgresql://postgres:[PASSWORD]@db.PROJECT_REF.supabase.co:5432/postgres

# Or session pooler (for persistent connections with IPv4/IPv6 support)
postgresql://postgres.PROJECT_REF:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:5432/postgres
```

**Connection Types Explained:**
- **Transaction pooler** (port 6543): Best for applications like this that make quick database queries
- **Direct connection** (port 5432): For persistent connections, requires IPv6 support
- **Session pooler** (port 5432): For persistent connections with IPv4/IPv6 support

### Finding Your Connection String

1. Go to your Supabase project dashboard
2. Click **Connect** (top right corner)
3. Choose your preferred connection method
4. Copy the connection string
5. Update your `.env` file with the copied string

### Important Notes

- **Never commit your database password to git**
- **The transaction pooler (port 6543) is recommended** for this application
- **Replace placeholder values** in the connection string with your actual project details

## Available Functions

### `seed()`
Populates the database with image embeddings from demo images.

### `search()`
Performs a text-to-image search with a predefined query.

### `search_by_image(image_path, limit=3)`
Searches for similar images using an input image.

### `search_flexible(query=None, image_path=None, limit=3)`
Flexible search function that handles both text and image queries.

## Features

- **Text-to-Image Search**: Find images that match text descriptions
- **Image-to-Image Search**: Find similar images using an input image
- **Flexible API**: Single function that handles both search types
- **Cloud-First**: Works directly with Supabase cloud
- **Production Ready**: Designed for production deployment
- **Error Handling**: Robust error handling for missing images and files

## Architecture

The system uses:
- **CLIP Model**: OpenAI's clip-ViT-B-32 for generating 512-dimensional embeddings
- **Supabase Vector**: PostgreSQL with pgvector extension for vector storage
- **vecs**: Python client for managing vector collections
- **SentenceTransformers**: Framework for encoding images and text

## Troubleshooting

### Common Issues

1. **Connection Error**: 
   - Verify your connection string is correct
   - Check that the pgvector extension is enabled
   - Ensure your Supabase project is active (not paused)

2. **Authentication Failed**: 
   - Double-check your database password
   - Make sure you're using the correct project reference ID
   - Try regenerating your database password in Supabase settings

3. **Import Errors**: 
   - Install dependencies with `poetry install`
   - Activate virtual environment with `poetry shell`

4. **Image Not Found**: 
   - Check that demo images exist in `../assets/images/`
   - Verify file paths are correct relative to the backend directory

5. **Vector Extension Error**: 
   - Go to Database > Extensions in your Supabase dashboard
   - Ensure "vector" extension is enabled (green checkmark)

### Viewing Data

You can inspect your vector data in Supabase Dashboard:
1. Go to **Database** > **Table Editor**
2. Select schema: **vecs**
3. View table: **image_vectors**

### Testing Connection

Run the test script to verify everything is working:
```powershell
python test_setup.py
```

### Getting Help

- **Supabase Docs**: https://supabase.com/docs
- **pgvector Docs**: https://github.com/pgvector/pgvector
- **Support**: https://supabase.com/support

## Next Steps

- Add more images to improve search quality
- Implement batch processing for large image collections
- Add API endpoints for web integration
- Implement image upload and real-time indexing
- Add metadata filtering (e.g., by category, date, etc.)
