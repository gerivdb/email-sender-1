# Multi-stage Dockerfile for Go EMAIL_SENDER ecosystem
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Set working directory
WORKDIR /app

# Copy go mod files
COPY development/managers/go.mod development/managers/go.sum ./
COPY development/managers/api-gateway/go.mod development/managers/api-gateway/go.sum ./api-gateway/
COPY development/managers/vectorization-go/go.mod development/managers/vectorization-go/go.sum ./vectorization-go/
COPY development/managers/integration_tests/go.mod development/managers/integration_tests/go.sum ./integration_tests/

# Download dependencies
RUN cd api-gateway && go mod download
RUN cd vectorization-go && go mod download
RUN cd integration_tests && go mod download
RUN go mod download

# Copy source code
COPY development/managers/ ./

# Build the main application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o email-sender-main .

# Build API Gateway
RUN cd api-gateway && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o api-gateway .

# Build vector client
RUN cd vectorization-go && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o vector-client .

# Production stage
FROM alpine:latest

# Install runtime dependencies
RUN apk --no-cache add ca-certificates tzdata curl

# Create non-root user
RUN addgroup -g 1001 -S emailsender && \
   adduser -u 1001 -S emailsender -G emailsender

# Create directories
RUN mkdir -p /app/bin /app/config /app/logs /app/data
RUN chown -R emailsender:emailsender /app

# Copy binaries from builder
COPY --from=builder /app/email-sender-main /app/bin/
COPY --from=builder /app/api-gateway/api-gateway /app/bin/
COPY --from=builder /app/vectorization-go/vector-client /app/bin/

# Copy configuration files
COPY deployment/config/ /app/config/

# Set permissions
RUN chmod +x /app/bin/*

# Switch to non-root user
USER emailsender

# Set working directory
WORKDIR /app

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
   CMD curl -f http://localhost:8080/health || exit 1

# Expose ports
EXPOSE 8080 8081 8082

# Environment variables
ENV GO_ENV=production
ENV API_PORT=8080
ENV METRICS_PORT=8081
ENV VECTOR_PORT=8082
ENV LOG_LEVEL=info

# Default command
CMD ["/app/bin/email-sender-main"]
