# Ultra-Advanced 8-Level Branching Framework - Production Dockerfile
# ================================================================
# Multi-stage build for optimal performance and security
FROM golang:1.21-alpine AS builder

# Set working directory
WORKDIR /app

# Install build dependencies and tools
RUN apk add --no-cache \
   git \
   make \
   ca-certificates \
   tzdata \
   gcc \
   musl-dev

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN make build

# Final stage
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache \
   ca-certificates \
   git \
   curl \
   tzdata

# Create non-root user
RUN addgroup -g 1001 -S branching && \
   adduser -u 1001 -S branching -G branching

# Set working directory
WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /app/bin/branching-manager .

# Copy configuration
COPY --from=builder /app/config ./config

# Create necessary directories
RUN mkdir -p /app/data /app/logs && \
   chown -R branching:branching /app

# Switch to non-root user
USER branching

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
   CMD curl -f http://localhost:8080/health || exit 1

# Run the application
CMD ["./branching-manager", "-config", "./config/branching_config.yaml"]
