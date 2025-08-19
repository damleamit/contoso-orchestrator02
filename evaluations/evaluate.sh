#!/usr/bin/env bash
set -euo pipefail

# Default: run evaluation
SKIP_EVAL=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-eval)
      SKIP_EVAL=true
      shift
      ;;
    *)
      echo "❌ Error: Unknown argument: $1"
      echo "Usage: $0 [--skip-eval]"
      exit 1
      ;;
  esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1) Validate environment
echo -e "${BLUE}▶ Validating environment...${NC}"
if [ -z "${APP_CONFIG_ENDPOINT:-}" ]; then
  echo -e "${RED}❌ Error: APP_CONFIG_ENDPOINT is not set${NC}"
  exit 1
fi
echo -e "${GREEN}✅ APP_CONFIG_ENDPOINT is set${NC}"

# 2) Create & activate venv
echo -e "${BLUE}▶ Creating virtual environment...${NC}"
python -m venv evaluations/.venv
source evaluations/.venv/bin/activate
echo -e "${GREEN}✅ Virtual environment activated${NC}"

# 3) Install dependencies - install main requirements first, then evaluation-specific ones
echo -e "${BLUE}▶ Installing Python dependencies...${NC}"
pip install --upgrade pip

echo -e "${BLUE}▶ Installing main application dependencies...${NC}"
if [ -f "requirements.txt" ]; then
  pip install -r requirements.txt
  echo -e "${GREEN}✅ Main dependencies installed${NC}"
else
  echo -e "${YELLOW}⚠️ Warning: requirements.txt not found in root directory${NC}"
fi

echo -e "${BLUE}▶ Installing evaluation-specific dependencies...${NC}"
if [ -f "evaluations/requirements.txt" ]; then
  pip install -r evaluations/requirements.txt
  echo -e "${GREEN}✅ Evaluation dependencies installed${NC}"
else
  echo -e "${RED}❌ Error: evaluations/requirements.txt not found${NC}"
  exit 1
fi

# 4) Set up Python path to ensure imports work
echo -e "${BLUE}▶ Setting up Python path and environment...${NC}"
export PYTHONPATH="$(pwd):$(pwd)/src:${PYTHONPATH:-}"
# Allow environment variables to be used when Azure App Configuration is not available
export allow_environment_variables=true
echo -e "${GREEN}✅ PYTHONPATH configured: $PYTHONPATH${NC}"
echo -e "${GREEN}✅ Environment variables enabled for configuration fallback${NC}"

# 5) Verify critical imports work
echo -e "${BLUE}▶ Verifying critical imports...${NC}"
python -c "
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
"

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Import verification failed. Exiting.${NC}"
  deactivate
  rm -rf evaluations/.venv
  exit 1
fi

echo -e "${GREEN}✅ All critical imports verified${NC}"

# 6) Generate eval-input
echo -e "${BLUE}▶ Generating eval input...${NC}"
if python evaluations/generate_eval_input.py; then
  echo -e "${GREEN}✅ Eval input generated successfully${NC}"
else
  echo -e "${RED}❌ Failed to generate eval input${NC}"
  deactivate
  rm -rf evaluations/.venv
  exit 1
fi

# 7) Conditionally run evaluation
if [ "$SKIP_EVAL" = false ]; then
  echo -e "${BLUE}▶ Running evaluation...${NC}"
  if python evaluations/evaluate.py; then
    echo -e "${GREEN}✅ Evaluation completed successfully${NC}"
  else
    echo -e "${RED}❌ Evaluation failed${NC}"
    deactivate
    rm -rf evaluations/.venv
    exit 1
  fi
else
  echo -e "${YELLOW}▶ Skipping evaluation as requested (--skip-eval).${NC}"
fi

# 8) Teardown
echo -e "${BLUE}▶ Cleaning up...${NC}"
deactivate
rm -rf evaluations/.venv

echo -e "${GREEN}✅ All done.${NC}"
