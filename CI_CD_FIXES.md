# CI/CD Pipeline Fixes for Python Dependency Issues

## Problem Summary

The GitHub CI/CD pipeline was failing with the following errors:
- `ModuleNotFoundError: No module named 'tiktoken'`
- `ModuleNotFoundError: No module named 'pyodbc'`
- Import errors for `src.main` module

## Root Causes

1. **Incomplete dependency installation**: The evaluation script only installed `evaluations/requirements.txt` but missing critical packages from the main `requirements.txt`
2. **Python path configuration**: The `src` module wasn't properly accessible during CI/CD runs
3. **Missing system dependencies**: ODBC drivers weren't installed in the CI/CD environment
4. **Inconsistent requirement files**: The evaluation requirements file was missing several critical dependencies

## Solutions Implemented

### 1. Updated `evaluations/requirements.txt`

Added all critical dependencies from the main requirements file:
- `tiktoken==0.7.0`
- `pyodbc==5.1.0`
- `azure-appconfiguration-provider==1.3.0`
- `tenacity==9.0.0`
- All other missing Azure SDK and AI dependencies

### 2. Enhanced Installation Scripts

#### Bash Script (`evaluations/evaluate.sh`)
- Added proper error handling and colored output
- Install main requirements first, then evaluation-specific ones
- Added import verification step before running evaluation
- Better Python path configuration
- Comprehensive error reporting

#### PowerShell Script (`evaluations/evaluate.ps1`)
- Windows-compatible version with same improvements
- Proper error handling with try-catch blocks
- ANSI color support for better output
- Consistent with bash script functionality

### 3. Updated GitHub Actions Workflows

#### PR Pipeline (`.github/workflows/pr_pipeline.yaml`)
```yaml
- name: Cache pip dependencies
  uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
    restore-keys: |
      ${{ runner.os }}-pip-

- name: Install system dependencies (Ubuntu)
  run: |
    sudo apt-get update
    sudo apt-get install -y unixodbc-dev
```

#### CI/CD Pipeline (`.github/workflows/cicd_pipeline.yaml`)
- Added same pip caching and system dependency installation
- Ensures ODBC drivers are available for `pyodbc`

### 4. Verification Steps Added

Both scripts now include verification steps that:
1. Check if critical packages can be imported
2. Verify the main application module can be loaded
3. Provide detailed error messages if imports fail
4. Exit gracefully if verification fails

## Key Improvements

1. **Dependency Management**
   - Main requirements installed before evaluation requirements
   - All critical packages now included in evaluation requirements
   - Version pinning for consistency

2. **Error Handling**
   - Comprehensive error checking at each step
   - Colored output for better visibility
   - Graceful cleanup on failure

3. **System Dependencies**
   - ODBC drivers installed in CI/CD environment
   - Pip caching for faster builds

4. **Import Verification**
   - Pre-flight checks ensure all imports work
   - Clear error messages for debugging

## Testing

To test locally:

### Windows (PowerShell)
```powershell
./evaluations/evaluate.ps1 -SkipEval
```

### Linux/macOS (Bash)
```bash
./evaluations/evaluate.sh --skip-eval
```

## Expected CI/CD Behavior

With these fixes, the CI/CD pipeline should:
1. ✅ Install all system dependencies (ODBC drivers)
2. ✅ Install Python packages from both requirement files
3. ✅ Verify all imports work before proceeding
4. ✅ Successfully import `src.main.app`
5. ✅ Generate evaluation input without errors
6. ✅ Complete the pipeline successfully

## Files Modified

- `evaluations/requirements.txt` - Added missing dependencies
- `evaluations/evaluate.sh` - Enhanced with better error handling and verification
- `evaluations/evaluate.ps1` - Enhanced PowerShell version
- `.github/workflows/pr_pipeline.yaml` - Added system dependencies and caching
- `.github/workflows/cicd_pipeline.yaml` - Added system dependencies and caching
