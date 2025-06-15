# Makefile pour Error Pattern Analyzer et Vectorization Migration

.PHONY: check format lint security build test all vector-tools vector-migrate vector-benchmark vector-test

all: format lint security build test vector-tools

format:
	gofumpt -w .
	goimports -w .

deps:
	go mod tidy
	go mod verify

lint: deps
	go vet ./...
	golangci-lint run

security:
	gosec ./...

build:
	go build -o /dev/null

# Vector migration tools
vector-tools: vector-migrate vector-benchmark

vector-migrate:
	go build -o bin/vector-migration ./cmd/vector-migration

vector-benchmark:
	go build -o bin/vector-benchmark ./cmd/vector-benchmark

vector-test:
	go test ./pkg/vectorization/... -v

vector-clean:
	rm -f bin/vector-migration bin/vector-benchmark

# Run vector migration workflow
vector-run-migration:
	./bin/vector-migration -action vectorize -input ./roadmaps -collection email_sender_tasks_v1 -verbose

vector-run-validation:
	./bin/vector-migration -action validate -input ./roadmaps -collection email_sender_tasks_v1 -output reports/validation.json

vector-run-benchmark:
	./bin/vector-benchmark -vectors 1000 -iterations 100 -output reports/benchmark.json

test:
	go test ./...

check: format lint build vector-tools
