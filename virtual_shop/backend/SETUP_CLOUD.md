# Quick Setup Guide for Supabase Cloud

Follow these steps to set up image search with Supabase cloud (no local installation needed).

## Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up/Sign in
3. Click **"New Project"**
4. Fill in:
   - **Name**: virtual-shop-image-search
   - **Database Password**: Choose a strong password (SAVE THIS!)
   - **Region**: Choose closest to you
5. Click **"Create new project"**
6. Wait for project to be created (2-3 minutes)

## Step 2: Enable Vector Extension

1. In your project dashboard, go to **Database** → **Extensions**
2. Search for **"vector"**
3. Click **"Enable"** next to the vector extension
4. Wait for green checkmark (enabled)

## Step 3: Get Connection String

1. Click **"Connect"** button (top right of dashboard)
2. Choose **"Transaction"** tab (recommended)
3. Copy the connection string
4. It looks like:
   ```
   postgresql://postgres.PROJECT_REF:[PASSWORD]@aws-0-REGION.pooler.supabase.com:6543/postgres
   ```

## Step 4: Configure Your App

1. Open `backend/.env` file
2. Replace the `SUPABASE_DB_URL` value with your connection string
3. Make sure to replace `[PASSWORD]` with your actual database password

Example:
```env
SUPABASE_DB_URL=postgresql://postgres.abcdefghijklmnop:mypassword123@aws-0-us-east-1.pooler.supabase.com:6543/postgres
```

## Step 5: Install Dependencies & Test

```powershell
cd backend
poetry install
poetry shell
python test_setup.py
```

If all tests pass, you're ready to go!

## Step 6: Run Image Search

```powershell
# Seed the database with image embeddings
python -c "from image_serach import seed; seed()"

# Test text-to-image search
python -c "from image_serach import search; search()"
```

## Important Notes

- ✅ **Use Transaction pooler** (port 6543) - best for this application
- ⚠️ **Never commit your password** to git
- 💡 **Free tier included** - Supabase provides generous free usage
- 🔒 **Secure by default** - Your database is protected

## Getting Help

- **Supabase Docs**: https://supabase.com/docs
- **Dashboard**: https://supabase.com/dashboard
- **Support**: https://supabase.com/support

## Troubleshooting

**Connection failed?**
- Check your connection string is correct
- Verify password is right
- Ensure project is not paused

**Vector extension error?**
- Go to Database > Extensions
- Make sure "vector" shows green checkmark
- Try disabling and re-enabling if needed

**Import errors?**
- Run `poetry install` to install dependencies
- Make sure you're in the backend directory
