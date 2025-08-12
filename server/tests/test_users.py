import sys
import os
import pytest
from httpx import AsyncClient, ASGITransport

# Ensure the project root is in the import path
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from main import app  # Adjust if your FastAPI app is named differently

@pytest.mark.asyncio
async def test_user_crud():
    """
    Full CRUD test for /users/ endpoint.
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:

        # 1. Create user
        create_payload = {
            "name": "Test User",
            "email": "test@example.com",
            "phone": "0123456789",
            "user_type": "tester"
        }
        create_response = await client.post("/users/", json=create_payload)
        assert create_response.status_code == 200
        user = create_response.json()
        user_id = user["user_id"]

        # 2. Read all users
        all_response = await client.get("/users/")
        assert all_response.status_code == 200
        assert any(u["user_id"] == user_id for u in all_response.json())

        # 3. Read single user
        single_response = await client.get(f"/users/{user_id}")
        assert single_response.status_code == 200
        assert single_response.json()["email"] == "test@example.com"

        # 4. Update user
        update_payload = {
            "name": "Updated User",
            "email": "updated@example.com",
            "phone": "9876543210",
            "user_type": "admin"
        }
        update_response = await client.put(f"/users/{user_id}", json=update_payload)
        assert update_response.status_code == 200
        assert update_response.json()["name"] == "Updated User"

        # 5. Delete user
        delete_response = await client.delete(f"/users/{user_id}")
        assert delete_response.status_code == 200
        assert delete_response.json()["message"] == "🗑️ User deleted successfully"

        # 6. Confirm deletion
        confirm_response = await client.get(f"/users/{user_id}")
        assert confirm_response.status_code == 404
