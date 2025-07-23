# 🧪 SOC Test Suite

This directory contains automated tests for the SOC environment, including unit tests, integration tests, and security tests to ensure the reliability and security of the infrastructure.

## 🧩 Test Categories

### 1. Unit Tests
- **Purpose**: Test individual components in isolation
- **Location**: `tests/unit/`
- **Coverage**:
  - Configuration validation
  - Helper functions
  - Utility scripts

### 2. Integration Tests
- **Purpose**: Test interactions between components
- **Location**: `tests/integration/`
- **Coverage**:
  - Service communication
  - Data flow between components
  - API endpoints

### 3. Security Tests
- **Purpose**: Validate security controls
- **Location**: `tests/security/`
- **Coverage**:
  - Authentication and authorization
  - Input validation
  - Security headers
  - Vulnerability scanning

### 4. Performance Tests
- **Purpose**: Validate system performance
- **Location**: `tests/performance/`
- **Coverage**:
  - Load testing
  - Stress testing
  - Endurance testing

## 🚀 Getting Started

### Prerequisites
- Python 3.8+
- Docker and Docker Compose
- Node.js 14+ (for some frontend tests)

### Running Tests

#### Run All Tests
```bash
# Install test dependencies
pip install -r tests/requirements.txt

# Run all tests
pytest
```

#### Run Specific Test Category
```bash
# Run unit tests
pytest tests/unit

# Run integration tests
pytest tests/integration

# Run security tests
pytest tests/security

# Run performance tests
pytest tests/performance
```

## 🛠 Test Configuration

### Environment Variables
Create a `.env.test` file in the tests directory:
```ini
# Test environment configuration
TEST_ENV=ci
LOG_LEVEL=DEBUG

# Test credentials (use test accounts)
TEST_USER=test@example.com
TEST_PASSWORD=testpass123

# Test endpoints
API_URL=http://localhost:8000
```

### Test Data
- Store test fixtures in `tests/fixtures/`
- Use factories for generating test data
- Clean up test data after each test

## 🔒 Security Testing

### OWASP ZAP Integration
```bash
# Run ZAP baseline scan
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t http://target:8080 -r testreport.html
```

### Bandit (Python Security Scanner)
```bash
# Install bandit
pip install bandit

# Run security scan
bandit -r . -f html -o bandit_report.html
```

## 📊 Test Reporting

### Generate HTML Report
```bash
pytest --html=reports/test_report.html --self-contained-html
```

### Generate JUnit XML (for CI/CD)
```bash
pytest --junitxml=reports/junit.xml
```

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install -r tests/requirements.txt
    
    - name: Run tests
      run: |
        pytest --cov=./ --cov-report=xml
    
    - name: Upload coverage
      uses: codecov/codecov-action@v1
      with:
        token: ${{ secrets.CODECOV_TOKEN }}
        file: ./coverage.xml
        fail_ci_if_error: true
```

## 📚 Documentation

- [Writing Tests](./docs/writing_tests.md)
- [Test Architecture](./docs/architecture.md)
- [CI/CD Integration](./docs/ci_cd.md)
- [Troubleshooting](./docs/troubleshooting.md)
