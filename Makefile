# Makefile pour Error Pattern Analyzer

.PHONY: check format lint security build test all

all: format lint security build test

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

test:
	go test ./...

check: format lint build
