@echo off
setlocal enabledelayedexpansion

echo 🚀 Setting up Contextual Memory Manager Development Environment

:: Check if Docker is installed
docker --version >nul 2>&1
if !errorlevel! neq 0 (
    echo ❌ Docker is not installed. Please install Docker Desktop first.
    pause
    exit /b 1
)

docker-compose --version >nul 2>&1
if !errorlevel! neq 0 (
    echo ❌ Docker Compose is not installed. Please install Docker Compose first.
    pause
    exit /b 1
)

echo ✅ Docker and Docker Compose are available

:: Start services
echo 🐳 Starting services with Docker Compose...
docker-compose up -d

:: Wait for services to be ready
echo ⏳ Waiting for services to be ready...
timeout /t 15 /nobreak >nul

:: Check PostgreSQL
echo 🔍 Checking PostgreSQL connection...
docker-compose exec -T postgres pg_isready -U contextual_user -d contextual_memory >nul 2>&1
if !errorlevel! equ 0 (
    echo ✅ PostgreSQL is ready
) else (
    echo ❌ PostgreSQL is not ready
    pause
    exit /b 1
)

:: Check Qdrant
echo 🔍 Checking Qdrant connection...
curl -f http://localhost:6333/health >nul 2>&1
if !errorlevel! equ 0 (
    echo ✅ Qdrant is ready
) else (
    echo ❌ Qdrant is not ready - this is optional for basic functionality
)

:: Check Redis
echo 🔍 Checking Redis connection...
docker-compose exec -T redis redis-cli ping | findstr PONG >nul 2>&1
if !errorlevel! equ 0 (
    echo ✅ Redis is ready
) else (
    echo ❌ Redis is not ready - this is optional for basic functionality
)

:: Copy environment configuration
echo 📝 Setting up environment configuration...
if not exist ".env" (
    copy config\.env.example .env >nul
    echo ✅ Created .env file from template
) else (
    echo ✅ .env file already exists
)

:: Build the application
echo 🔨 Building the application...
go build -o contextual-memory-manager.exe .\development\
if !errorlevel! equ 0 (
    echo ✅ Build completed
) else (
    echo ❌ Build failed
    pause
    exit /b 1
)

:: Run basic performance test
echo 🧪 Running basic performance test...
go test .\tests -run TestPerformanceStoreAction -timeout 30s
if !errorlevel! equ 0 (
    echo ✅ Basic tests passed
) else (
    echo ⚠️ Some tests failed, but setup is complete
)

echo.
echo 🎉 Development environment setup complete!
echo.
echo 📋 Services running:
echo    - PostgreSQL: localhost:5432
echo    - Qdrant: localhost:6333
echo    - Redis: localhost:6379
echo.
echo 🚀 Next steps:
echo    1. Review the .env file and adjust settings if needed
echo    2. Run the integration example: .\example_demo.exe
echo    3. Run all tests: go test .\tests\...
echo    4. Start developing with the Contextual Memory Manager!
echo.
echo 🛑 To stop services: docker-compose down
echo 🗑️ To reset data: docker-compose down -v

pause
