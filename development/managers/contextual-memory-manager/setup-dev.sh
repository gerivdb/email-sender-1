#!/bin/bash

# Local Development Setup Script for Contextual Memory Manager
# This script sets up the local development environment with PostgreSQL, Qdrant, and Redis

set -e

echo "🚀 Setting up Contextual Memory Manager Development Environment"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Docker and Docker Compose are available"

# Start services
echo "🐳 Starting services with Docker Compose..."
docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check PostgreSQL
echo "🔍 Checking PostgreSQL connection..."
if docker-compose exec -T postgres pg_isready -U contextual_user -d contextual_memory; then
    echo "✅ PostgreSQL is ready"
else
    echo "❌ PostgreSQL is not ready"
    exit 1
fi

# Check Qdrant
echo "🔍 Checking Qdrant connection..."
if curl -f http://localhost:6333/health &> /dev/null; then
    echo "✅ Qdrant is ready"
else
    echo "❌ Qdrant is not ready"
    exit 1
fi

# Check Redis
echo "🔍 Checking Redis connection..."
if docker-compose exec -T redis redis-cli ping | grep -q PONG; then
    echo "✅ Redis is ready"
else
    echo "❌ Redis is not ready"
    exit 1
fi

# Run database migrations
echo "📊 Running database migrations..."
if command -v migrate &> /dev/null; then
    migrate -path ./migrations -database "postgres://contextual_user:contextual_pass@localhost:5432/contextual_memory?sslmode=disable" up
    echo "✅ Migrations completed"
else
    echo "⚠️  'migrate' tool not found. Please install golang-migrate to run migrations automatically."
    echo "   You can install it with: go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest"
    echo "   Then run: migrate -path ./migrations -database \"postgres://contextual_user:contextual_pass@localhost:5432/contextual_memory?sslmode=disable\" up"
fi

# Copy environment configuration
echo "📝 Setting up environment configuration..."
if [ ! -f ".env" ]; then
    cp config/.env.example .env
    echo "✅ Created .env file from template"
else
    echo "✅ .env file already exists"
fi

# Build the application
echo "🔨 Building the application..."
go build -o contextual-memory-manager ./development/

echo "✅ Build completed"

# Run basic tests
echo "🧪 Running basic tests..."
if go test ./tests -run TestPerformanceStoreAction -timeout 30s; then
    echo "✅ Basic tests passed"
else
    echo "⚠️  Some tests failed, but setup is complete"
fi

echo ""
echo "🎉 Development environment setup complete!"
echo ""
echo "📋 Services running:"
echo "   - PostgreSQL: localhost:5432"
echo "   - Qdrant: localhost:6333"
echo "   - Redis: localhost:6379"
echo ""
echo "🚀 Next steps:"
echo "   1. Review the .env file and adjust settings if needed"
echo "   2. Run the integration example: ./example_demo"
echo "   3. Run all tests: go test ./tests/..."
echo "   4. Start developing with the Contextual Memory Manager!"
echo ""
echo "🛑 To stop services: docker-compose down"
echo "🗑️  To reset data: docker-compose down -v"
