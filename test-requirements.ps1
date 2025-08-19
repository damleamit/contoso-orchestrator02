# Test script to validate requirements resolution
param(
    [switch]$TestMain,
    [switch]$TestEvaluations
)

Write-Host "🧪 Testing requirements resolution..." -ForegroundColor Blue

# Default to testing both if no switches provided
if (-not $TestMain -and -not $TestEvaluations) {
    $TestMain = $true
    $TestEvaluations = $true
}

# Create a temporary virtual environment for testing
$testVenv = "test-requirements-venv"
Write-Host "▶ Creating test virtual environment..." -ForegroundColor Yellow
python -m venv $testVenv

try {
    # Activate the test environment
    & "$testVenv\Scripts\Activate.ps1"
    
    # Upgrade pip
    Write-Host "▶ Upgrading pip..." -ForegroundColor Yellow
    python -m pip install --upgrade pip

    if ($TestMain) {
        Write-Host "▶ Testing main requirements.txt..." -ForegroundColor Yellow
        $result = python -m pip install -r requirements.txt --dry-run 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Main requirements.txt can be resolved" -ForegroundColor Green
        } else {
            Write-Host "❌ Main requirements.txt has issues:" -ForegroundColor Red
            Write-Host $result -ForegroundColor Red
        }
    }

    if ($TestEvaluations) {
        Write-Host "▶ Testing evaluations/requirements.txt..." -ForegroundColor Yellow
        $result = python -m pip install -r evaluations/requirements.txt --dry-run 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Evaluations requirements.txt can be resolved" -ForegroundColor Green
        } else {
            Write-Host "❌ Evaluations requirements.txt has issues:" -ForegroundColor Red
            Write-Host $result -ForegroundColor Red
        }
    }
}
finally {
    # Cleanup
    Write-Host "▶ Cleaning up test environment..." -ForegroundColor Yellow
    if (Get-Command deactivate -ErrorAction SilentlyContinue) {
        deactivate
    }
    Remove-Item -Recurse -Force $testVenv -ErrorAction SilentlyContinue
}

Write-Host "🏁 Requirements validation complete!" -ForegroundColor Blue
