# 🐳 RAG System - Multi-stage Docker Build
# Optimized for production with security best practices

# Build stage
FROM golang:1.23-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Create non-root user
RUN adduser -D -g '' rag

# Set working directory
WORKDIR /build

# Copy dependency files and local modules first
COPY go.mod go.sum ./
COPY development/managers/tools ./development/managers/tools/

# Download dependencies
RUN go mod download && go mod verify

# Copy the rest of the source code
COPY . .

# Ensure config directory exists
RUN mkdir -p /build/config

# Build the RAG applications
ARG VERSION=dev
ARG BUILD_DATE
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s -extldflags '-static' -X main.Version=${VERSION} -X main.BuildDate=${BUILD_DATE}" \
    -o rag-server ./cmd/server

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s -extldflags '-static' -X main.Version=${VERSION}" \
    -o rag-cli ./cmd/cli

# Runtime stage
FROM alpine:3.18 AS runtime

# Create the same rag user in the runtime image
RUN adduser -D -g '' rag

# Install minimal runtime dependencies
RUN apk add --no-cache ca-certificates tzdata && \
    mkdir -p /logs /data /app /config && \
    chown -R rag:rag /logs /data /app /config

# Copy built binaries
COPY --from=builder /build/rag-server /app/rag-server
COPY --from=builder /build/rag-cli /app/rag-cli

# Copy API specification
COPY --from=builder /build/api/openapi.yaml /api/openapi.yaml
# In the build stage, we will create a dummy config directory if it doesn't exist

# Use non-root user
USER rag

# Create working directory
WORKDIR /app

# Set environment variables
ENV PATH="/app:${PATH}"
ENV LOG_LEVEL="info"

# Expose ports (HTTP API and Metrics)
EXPOSE 8080 9090

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ["/app/rag-cli", "health"] || exit 1

# Default command
ENTRYPOINT ["/app/rag-server"]
CMD ["serve"]
