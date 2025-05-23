# Makefile for plan-generator

# Variables
BINARY_NAME=goplangen
BINARY_PATH=bin/$(BINARY_NAME)
MAIN_FILE=cmd/main.go
BUILD_DIR=bin
OUTPUT_DIR=d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/projet/roadmaps/plans/consolidated

# Default task
.PHONY: all
all: build

# Build the binary
.PHONY: build
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	@go build -o $(BINARY_PATH) $(MAIN_FILE)
	@echo "Build successful!"

# Run a test plan generation
.PHONY: test
test: build
	@echo "Testing plan generation..."
	@./$(BINARY_PATH) -version "test" -title "Plan de Test" -phases 3 -taskDepth 2

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR)
	@echo "Cleaned!"

# Generate plans with different depths
.PHONY: depths
depths: build
	@echo "Generating plans with different depths..."
	@for depth in 1 2 3 4 5 6 7; do \
		echo "Generating plan with depth $$depth..."; \
		./$(BINARY_PATH) -version "depth-$$depth" -title "Plan avec profondeur $$depth" \
			-description "Plan démontrant la profondeur de tâches $$depth" \
			-taskDepth $$depth -phases 3 -output $(OUTPUT_DIR); \
	done
	@echo "All plans generated!"

# Show help
.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make build  - Build the binary"
	@echo "  make test   - Run a test plan generation"
	@echo "  make clean  - Clean build artifacts"
	@echo "  make depths - Generate plans with different depths (1-7)"
	@echo "  make help   - Show this help"
