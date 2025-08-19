# CI/CD Pipeline Fixes for Python Dependency Issues

## Problem Summary

The GitHub CI/CD pipeline was failing with the following errors:
- `ModuleNotFoundError: No module named 'tiktoken'`
- `ModuleNotFoundError: No module named 'pyodbc'`
- Import errors for `src.main` module
- `ERROR: Could not find a version that satisfies the requirement azure-ai-agents==1.0.0b9`
- `tiktoken` build failure with Python 3.13: "the configured Python interpreter version (3.13) is newer than PyO3's maximum supported version (3.12)"
- **LATEST**: Logging error `TypeError: level must be an integer` in configuration loading
- **LATEST**: Azure App Configuration connection failures causing hard stops in CI/CD

## Root Causes

1. **Incomplete dependency installation**: The evaluation script only installed `evaluations/requirements.txt` but missing critical packages from the main `requirements.txt`
2. **Python path configuration**: The `src` module wasn't properly accessible during CI/CD runs
3. **Missing system dependencies**: ODBC drivers weren't installed in the CI/CD environment
4. **Inconsistent requirement files**: The evaluation requirements file was missing several critical dependencies
5. **Outdated package versions**: Azure AI packages had specific beta versions that are no longer available
6. **Python version compatibility**: `tiktoken` package (built with Rust/PyO3) doesn't support Python 3.13 yet, only up to Python 3.12
7. **Configuration logging errors**: Incorrect logging method calls causing TypeErrors  
8. **Configuration resilience**: Hard failures when Azure App Configuration is not accessible in CI/CD environments

## Solutions Implemented

### 1. Updated Package Versions

Fixed outdated Azure AI package versions:
```diff
- azure-ai-projects==1.0.0b11
- azure-ai-agents==1.0.0b9
+ azure-ai-projects>=1.0.0
+ azure-ai-agents>=1.1.0
```

Also updated OpenTelemetry packages to use flexible version ranges:
```diff
- opentelemetry-instrumentation==0.48b0
- azure-monitor-opentelemetry-exporter==1.0.0b28
+ opentelemetry-instrumentation>=0.48b0
+ azure-monitor-opentelemetry-exporter>=1.0.0b28
```

And fixed pandas compilation issues on Windows:
```diff
- pandas==2.2.2
+ pandas>=2.2.2
```

## Solutions Implemented

### 1. Updated Package Versions

Fixed outdated Azure AI package versions:
```diff
- azure-ai-projects==1.0.0b11
- azure-ai-agents==1.0.0b9
+ azure-ai-projects>=1.0.0
+ azure-ai-agents>=1.1.0
```

Also updated OpenTelemetry packages to use flexible version ranges:
```diff
- opentelemetry-instrumentation==0.48b0
- azure-monitor-opentelemetry-exporter==1.0.0b28
+ opentelemetry-instrumentation>=0.48b0
+ azure-monitor-opentelemetry-exporter>=1.0.0b28
```

And fixed pandas compilation issues on Windows:
```diff
- pandas==2.2.2
+ pandas>=2.2.2
```

### 2. Fixed Python Version Compatibility

Updated GitHub Actions workflows to use Python 3.12 instead of 3.13:
```diff
- python-version: '3.13.7'
+ python-version: '3.12'
```

This resolves the `tiktoken` build issue where PyO3 (Rust-Python bindings) doesn't support Python 3.13 yet.

### 3. Updated `evaluations/requirements.txt`

Added all critical dependencies from the main requirements file:
- `tiktoken==0.7.0`
- `pyodbc==5.1.0`
- `azure-appconfiguration-provider==1.3.0`
- `tenacity==9.0.0`
- All other missing Azure SDK and AI dependencies

### 4. Enhanced Installation Scripts

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

### 5. Updated GitHub Actions Workflows

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

### 6. Verification Steps Added

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
1. ✅ Use Python 3.12 (compatible with all packages including tiktoken)
2. ✅ Install all system dependencies (ODBC drivers)
3. ✅ Install Python packages from both requirement files with correct versions
4. ✅ Verify all imports work before proceeding
5. ✅ Successfully import `src.main.app`
6. ✅ Generate evaluation input without errors
7. ✅ Complete the pipeline successfully

## Files Modified

- `evaluations/requirements.txt` - Added missing dependencies and updated versions
- `evaluations/evaluate.sh` - Enhanced with better error handling and verification
- `evaluations/evaluate.ps1` - Enhanced PowerShell version
- `.github/workflows/pr_pipeline.yaml` - Updated Python version and added system dependencies
- `.github/workflows/cicd_pipeline.yaml` - Updated Python version and added system dependencies
- `requirements.txt` - Updated package versions for compatibility
- `PYTHON_VERSION_COMPATIBILITY.md` - Documentation about Python version requirements
- `ADDITIONAL_CI_CD_FIXES.md` - Latest configuration and logging fixes
