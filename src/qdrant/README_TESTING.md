# Qdrant Integration Tests

## Overview

The Qdrant tests are split into two categories:

### Unit Tests (`client_unit_test.go`)

- **No external dependencies required**
- Test client creation and data structure validation
- Always run as part of the test suite

### Integration Tests (`client_critical_test.go`)

- **Require a running Qdrant server**
- Test real HTTP client operations (upsert, search, etc.)
- Automatically skip if Qdrant server is not available

## Running Unit Tests Only

```bash
go test ./src/qdrant -run "^TestQdrantClient_"
```plaintext
## Running All Tests (Including Integration)

### Option 1: Start Qdrant with Docker Compose

```bash
# Start only Qdrant service

docker-compose up -d qdrant

# Wait for Qdrant to be ready (about 30 seconds)

# Check status: http://localhost:6333/

# Run all tests

go test ./src/qdrant

# Stop Qdrant when done

docker-compose down qdrant
```plaintext
### Option 2: Manual Qdrant Setup

```bash
# Using Docker directly

docker run -p 6333:6333 -p 6334:6334 qdrant/qdrant:v1.7.0

# Then run tests

go test ./src/qdrant
```plaintext
## Test Behavior

- **Integration tests skip automatically** if Qdrant is not running on localhost:6333
- **No test failures** due to missing external services
- **Clear skip messages** indicate when tests are skipped

## Expected Output

### With Qdrant Running:

```plaintext
=== RUN   TestQdrantHTTPClient_MustWork
    client_critical_test.go:XX: 🎯 Test critique: Migration HTTP doit fonctionner
    client_critical_test.go:XX: ✅ Migration HTTP validée
--- PASS: TestQdrantHTTPClient_MustWork (0.05s)
```plaintext
### Without Qdrant Running:

```plaintext
=== RUN   TestQdrantHTTPClient_MustWork
    client_critical_test.go:XX: ⏭️  Qdrant server not available - skipping integration test
--- SKIP: TestQdrantHTTPClient_MustWork (0.00s)
```plaintext
## CI/CD Considerations

For continuous integration pipelines:

1. **Include Qdrant service** in CI configuration to run full integration tests
2. **Unit tests always run** regardless of external service availability
3. **Integration tests provide valuable validation** when external services are available
