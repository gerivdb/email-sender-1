# Makefile for BranchingManager
.PHONY: build test clean run deps lint

# Build settings
BINARY_NAME=branching-manager
BUILD_DIR=./bin
GO_FILES=$(shell find . -name "*.go" -type f)

# Default target
all: deps lint test build

# Install dependencies
deps:
	go mod init branching-manager
	go mod tidy
	go get github.com/google/uuid
	go get gopkg.in/yaml.v3
	go get github.com/stretchr/testify/assert
	go get github.com/stretchr/testify/mock

# Build the binary
build: deps
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	go build -o $(BUILD_DIR)/$(BINARY_NAME) ./cmd

# Run tests
test:
	@echo "Running tests..."
	go test -v ./tests/...

# Run tests with coverage
test-coverage:
	@echo "Running tests with coverage..."
	go test -v -coverprofile=coverage.out ./tests/...
	go tool cover -html=coverage.out -o coverage.html

# Run the application
run: build
	@echo "Running $(BINARY_NAME)..."
	$(BUILD_DIR)/$(BINARY_NAME) -config ./config/branching_config.yaml

# Run in development mode
dev:
	@echo "Running in development mode..."
	go run ./cmd -config ./config/branching_config.yaml

# Lint the code
lint:
	@echo "Linting code..."
	go vet ./...
	go fmt ./...

# Clean build artifacts
clean:
	@echo "Cleaning..."
	rm -rf $(BUILD_DIR)
	rm -f coverage.out coverage.html

# Docker build
docker-build:
	@echo "Building Docker image..."
	docker build -t branching-manager:latest .

# Docker run
docker-run: docker-build
	@echo "Running Docker container..."
	docker run -p 8080:8080 --rm branching-manager:latest

# Install tools
install-tools:
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Advanced linting
lint-advanced: install-tools
	golangci-lint run

# Benchmark tests
benchmark:
	@echo "Running benchmarks..."
	go test -bench=. ./tests/...

# Check for security vulnerabilities
security:
	go list -json -m all | docker run --rm -i sonatypecommunity/nancy:latest sleuth

# Generate documentation
docs:
	@echo "Generating documentation..."
	godoc -http=:6060

# Show help
help:
	@echo "Available targets:"
	@echo "  all          - Install deps, lint, test, and build"
	@echo "  deps         - Install Go dependencies"
	@echo "  build        - Build the binary"
	@echo "  test         - Run tests"
	@echo "  test-coverage- Run tests with coverage report"
	@echo "  run          - Build and run the application"
	@echo "  dev          - Run in development mode"
	@echo "  lint         - Basic linting"
	@echo "  lint-advanced- Advanced linting with golangci-lint"
	@echo "  clean        - Clean build artifacts"
	@echo "  docker-build - Build Docker image"
	@echo "  docker-run   - Build and run Docker container"
	@echo "  benchmark    - Run benchmark tests"
	@echo "  security     - Check for security vulnerabilities"
	@echo "  docs         - Generate and serve documentation"
	@echo "  help         - Show this help message"
