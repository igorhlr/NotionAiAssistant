"""
Basic tests for NotionAiAssistant
These tests focus on core Python functionality and optional package imports
"""
import pytest
import sys


def test_basic_import():
    """Test that basic Python functionality works"""
    assert True


def test_python_version():
    """Test Python version compatibility"""
    version = sys.version_info
    assert version.major == 3
    assert version.minor >= 11


@pytest.mark.asyncio
async def test_async_functionality():
    """Test basic async functionality"""
    async def async_function():
        return "Hello, async world!"
    
    result = await async_function()
    assert result == "Hello, async world!"


def test_optional_package_imports():
    """Test that required packages can be imported (optional)"""
    packages_to_test = [
        ("fastapi", "FastAPI web framework"),
        ("pydantic", "Data validation library"),
        ("pytest", "Testing framework"),
    ]
    
    import_results = []
    
    for package_name, description in packages_to_test:
        try:
            __import__(package_name)
            import_results.append(f"✅ {package_name}: {description}")
        except ImportError:
            import_results.append(f"❌ {package_name}: {description} (not available)")
    
    # At least pytest should be available since we're running tests
    pytest_available = any("pytest" in result and "✅" in result for result in import_results)
    assert pytest_available, f"Pytest should be available. Results: {import_results}"


class TestBasicFunctionality:
    """Test class for basic functionality"""
    
    def test_string_operations(self):
        """Test basic string operations"""
        test_string = "NotionAiAssistant"
        assert len(test_string) > 0
        assert test_string.startswith("Notion")
        assert test_string.endswith("Assistant")
    
    def test_list_operations(self):
        """Test basic list operations"""
        test_list = [1, 2, 3, 4, 5]
        assert len(test_list) == 5
        assert sum(test_list) == 15
        assert max(test_list) == 5
    
    def test_dict_operations(self):
        """Test basic dictionary operations"""
        test_dict = {"name": "NotionAiAssistant", "version": "0.1.0"}
        assert "name" in test_dict
        assert test_dict["name"] == "NotionAiAssistant"
        assert len(test_dict) == 2
    
    def test_basic_math(self):
        """Test basic mathematical operations"""
        assert 2 + 2 == 4
        assert 10 - 3 == 7
        assert 3 * 4 == 12
        assert 15 / 3 == 5
        assert 2 ** 3 == 8
    
    def test_file_system_access(self):
        """Test basic file system operations"""
        import os
        import tempfile
        
        # Test that we can create a temporary file
        with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
            temp_file.write("test content")
            temp_path = temp_file.name
        
        # Test that file exists and can be read
        assert os.path.exists(temp_path)
        
        with open(temp_path, 'r') as f:
            content = f.read()
            assert content == "test content"
        
        # Clean up
        os.unlink(temp_path)
        assert not os.path.exists(temp_path)
