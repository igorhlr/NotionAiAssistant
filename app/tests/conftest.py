"""
Pytest configuration and fixtures for NotionAiAssistant tests
"""
import os
import sys
import pytest
from pathlib import Path

# Add the app directory to Python path for imports
app_dir = Path(__file__).parent.parent
sys.path.insert(0, str(app_dir))


@pytest.fixture(scope="session")
def test_environment():
    """Set up test environment"""
    os.environ["TESTING"] = "true"
    os.environ["DEBUG"] = "true"
    return {
        "testing": True,
        "debug": True
    }


@pytest.fixture
def sample_data():
    """Provide sample data for tests"""
    return {
        "user_data": {
            "email": "test@example.com",
            "name": "Test User"
        },
        "notion_data": {
            "page_id": "test-page-id",
            "database_id": "test-database-id"
        }
    }


@pytest.fixture
async def async_client():
    """Provide async client for testing"""
    # This would be used for FastAPI testing when implemented
    pass


def pytest_configure(config):
    """Configure pytest"""
    config.addinivalue_line(
        "markers", "unit: marks tests as unit tests"
    )
    config.addinivalue_line(
        "markers", "integration: marks tests as integration tests"
    )
    config.addinivalue_line(
        "markers", "slow: marks tests as slow running"
    )


def pytest_collection_modifyitems(config, items):
    """Modify test collection to add markers"""
    for item in items:
        # Add unit marker to all tests by default
        if not any(marker.name in ["integration", "slow"] for marker in item.iter_markers()):
            item.add_marker(pytest.mark.unit)
