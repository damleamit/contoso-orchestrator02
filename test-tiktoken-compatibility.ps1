# Test script to check tiktoken compatibility
Write-Host "🧪 Testing tiktoken compatibility with different Python versions..." -ForegroundColor Blue

# Check if we can find information about tiktoken's Python version requirements
Write-Host "▶ Checking tiktoken package information..." -ForegroundColor Yellow

try {
    # Try to get package info from pip
    $pipShow = pip show tiktoken 2>$null
    if ($pipShow) {
        Write-Host "✅ tiktoken is currently installed:" -ForegroundColor Green
        Write-Host $pipShow
    } else {
        Write-Host "ℹ️ tiktoken is not currently installed" -ForegroundColor Cyan
    }
    
    # Check current Python version
    $pythonVersion = python --version
    Write-Host "📍 Current Python version: $pythonVersion" -ForegroundColor Cyan
    
    # Check if we can see tiktoken requirements
    Write-Host "▶ Checking tiktoken availability for current Python..." -ForegroundColor Yellow
    $tikTokenCheck = python -c "
import sys
print(f'Python version: {sys.version}')
print(f'Python version info: {sys.version_info}')

# Check if we can import tiktoken
try:
    import tiktoken
    print('✅ tiktoken is available and can be imported')
    try:
        version = tiktoken.__version__
        print(f'tiktoken version: {version}')
    except AttributeError:
        print('tiktoken version: unknown')
except ImportError as e:
    print(f'❌ tiktoken cannot be imported: {e}')
except Exception as e:
    print(f'⚠️ Other error with tiktoken: {e}')
"
    Write-Host $tikTokenCheck

} catch {
    Write-Host "❌ Error checking tiktoken: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "💡 Recommendations for CI/CD:" -ForegroundColor Blue
Write-Host "  ✓ GitHub Actions should use Python 3.12" -ForegroundColor Green
Write-Host "  ✓ Dockerfile already uses Python 3.12" -ForegroundColor Green  
Write-Host "  ✓ Local development may need Python 3.12 for full compatibility" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔗 Reference: https://pyo3.rs/main/python_versions" -ForegroundColor Cyan
