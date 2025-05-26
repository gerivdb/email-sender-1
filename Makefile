# Makefile pour Error Pattern Analyzer

build:
	go build -o ./cmd/analyzer/analyzer ./cmd/analyzer/main.go

test:
	go test ./... -cover

lint:
	golangci-lint run ./...
