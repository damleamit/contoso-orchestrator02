# PowerShell script for running evaluations
param(
    [switch]$SkipEval = $false
)

# Set error action preference to stop on errors
$ErrorActionPreference = "Stop"

# Colors for output (if terminal supports ANSI)
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

try {
    # 1) Validate environment
    Write-Host "${BLUE}▶ Validating environment...${NC}"
    if (-not $env:APP_CONFIG_ENDPOINT) {
        Write-Host "${RED}❌ Error: APP_CONFIG_ENDPOINT is not set${NC}"
        exit 1
    }
    Write-Host "${GREEN}✅ APP_CONFIG_ENDPOINT is set${NC}"

    # 2) Create & activate venv
    Write-Host "${BLUE}▶ Creating virtual environment...${NC}"
    python -m venv evaluations\.venv
    & "evaluations\.venv\Scripts\Activate.ps1"
    Write-Host "${GREEN}✅ Virtual environment activated${NC}"

    # 3) Install dependencies - install main requirements first, then evaluation-specific ones
    Write-Host "${BLUE}▶ Installing Python dependencies...${NC}"
    python -m pip install --upgrade pip

    Write-Host "${BLUE}▶ Installing main application dependencies...${NC}"
    if (Test-Path "requirements.txt") {
        python -m pip install -r requirements.txt
        Write-Host "${GREEN}✅ Main dependencies installed${NC}"
    } else {
        Write-Host "${YELLOW}⚠️ Warning: requirements.txt not found in root directory${NC}"
    }

    Write-Host "${BLUE}▶ Installing evaluation-specific dependencies...${NC}"
    if (Test-Path "evaluations\requirements.txt") {
        python -m pip install -r evaluations\requirements.txt
        Write-Host "${GREEN}✅ Evaluation dependencies installed${NC}"
    } else {
        Write-Host "${RED}❌ Error: evaluations\requirements.txt not found${NC}"
        exit 1
    }

    # 4) Set up Python path to ensure imports work
    Write-Host "${BLUE}▶ Setting up Python path and environment...${NC}"
    $currentPath = (Get-Location).Path
    $srcPath = Join-Path $currentPath "src"
    $env:PYTHONPATH = "$currentPath;$srcPath;$($env:PYTHONPATH)"
    # Allow environment variables to be used when Azure App Configuration is not available
    $env:allow_environment_variables = "true"
    Write-Host "${GREEN}✅ PYTHONPATH configured: $($env:PYTHONPATH)${NC}"
    Write-Host "${GREEN}✅ Environment variables enabled for configuration fallback${NC}"

    # 5) Verify critical imports work
    Write-Host "${BLUE}▶ Verifying critical imports...${NC}"
    $verifyScript = @"
import sys
print('Python version:', sys.version)
try:
    import tiktoken
    print('✅ tiktoken imported successfully')
except ImportError as e:
    print('❌ Failed to import tiktoken:', e)
    sys.exit(1)

try:
    import pyodbc
    print('✅ pyodbc imported successfully')
except ImportError as e:
    print('❌ Failed to import pyodbc:', e)
    sys.exit(1)

try:
    from src.main import app
    print('✅ Successfully imported src.main.app')
except ImportError as e:
    print('❌ Failed to import src.main.app:', e)
    sys.exit(1)
"@

    python -c $verifyScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "${RED}❌ Import verification failed. Exiting.${NC}"
        throw "Import verification failed"
    }

    Write-Host "${GREEN}✅ All critical imports verified${NC}"

    # 6) Generate eval-input
    Write-Host "${BLUE}▶ Generating eval input...${NC}"
    python evaluations\generate_eval_input.py
    if ($LASTEXITCODE -ne 0) {
        Write-Host "${RED}❌ Failed to generate eval input${NC}"
        throw "Failed to generate eval input"
    }
    Write-Host "${GREEN}✅ Eval input generated successfully${NC}"

    # 7) Conditionally run evaluation
    if (-not $SkipEval) {
        Write-Host "${BLUE}▶ Running evaluation...${NC}"
        python evaluations\evaluate.py
        if ($LASTEXITCODE -ne 0) {
            Write-Host "${RED}❌ Evaluation failed${NC}"
            throw "Evaluation failed"
        }
        Write-Host "${GREEN}✅ Evaluation completed successfully${NC}"
    } else {
        Write-Host "${YELLOW}▶ Skipping evaluation as requested (-SkipEval).${NC}"
    }

    Write-Host "${GREEN}✅ All done.${NC}"
}
catch {
    Write-Host "${RED}❌ Script failed: $($_.Exception.Message)${NC}"
    exit 1
}
finally {
    # 8) Teardown
    Write-Host "${BLUE}▶ Cleaning up...${NC}"
    if (Get-Command deactivate -ErrorAction SilentlyContinue) {
        deactivate
    } elseif (Get-Command Deactivate -ErrorAction SilentlyContinue) {
        Deactivate
    }
    if (Test-Path "evaluations\.venv") {
        Remove-Item -Recurse -Force "evaluations\.venv" -ErrorAction SilentlyContinue
    }
}
