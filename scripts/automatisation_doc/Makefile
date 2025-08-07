# Makefile SOTA 2025 pour automatisation Go plugins

.PHONY: generate test build clean

generate:
	go generate ./...

test: generate
	go test -v -race -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

build: generate test
	go build -trimpath ./...

clean:
	go clean -testcache
	rm -f coverage.out coverage.html
