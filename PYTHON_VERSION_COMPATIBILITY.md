# Python Version Compatibility Notice

## Current Python Version Requirement: 3.12

This project currently requires **Python 3.12** due to dependencies on packages built with Rust/PyO3 that do not yet support Python 3.13.

### Affected Packages
- `tiktoken` - Uses PyO3 (Rust-Python bindings) which currently supports up to Python 3.12

### CI/CD Configuration
- GitHub Actions workflows are configured to use Python 3.12
- Dockerfile uses Python 3.12 base image
- All requirements are tested and compatible with Python 3.12

### Future Updates
Once the PyO3 ecosystem fully supports Python 3.13, this project can be upgraded. Monitor these resources:
- [PyO3 Python Support Status](https://pyo3.rs/main/python_versions)
- [tiktoken Release Notes](https://github.com/openai/tiktoken/releases)

### Local Development
If you're using Python 3.13 locally, you may encounter build errors. Please use Python 3.12 for development:

```bash
# Using pyenv (recommended)
pyenv install 3.12.7
pyenv local 3.12.7

# Or using conda
conda create -n contoso-env python=3.12
conda activate contoso-env
```

### Docker Development
The provided Dockerfile uses Python 3.12, so container-based development will work correctly regardless of your local Python version.
