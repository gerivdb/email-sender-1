# 🐳 RAG System - Multi-stage Docker Build
# Optimized for production with security best practices

# Build stage
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Create non-root user
RUN adduser -D -g '' rag

# Set working directory
WORKDIR /build

# Copy dependency files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download && go mod verify

# Copy source code
COPY . .

# Build the RAG applications
ARG VERSION=dev
ARG BUILD_DATE
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s -extldflags '-static' -X main.Version=${VERSION} -X main.BuildDate=${BUILD_DATE}" \
    -o rag-server ./cmd/server/

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s -extldflags '-static' -X main.Version=${VERSION}" \
    -o rag-cli ./cmd/cli/

# Runtime stage
FROM scratch

# Import certificates and timezone data
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Import user
COPY --from=builder /etc/passwd /etc/passwd

# Copy built binaries
COPY --from=builder /build/rag-server /rag-server
COPY --from=builder /build/rag-cli /rag-cli

# Copy API specification
COPY --from=builder /build/api/openapi.yaml /api/openapi.yaml

# Use non-root user
USER rag

# Expose ports (HTTP API and Metrics)
EXPOSE 8080 9090

# Default command
ENTRYPOINT ["/rag-server"]
