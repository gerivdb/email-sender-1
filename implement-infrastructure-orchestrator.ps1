# Script to create feature branch and commit the infrastructure orchestrator implementation
Write-Host "Creating and setting up infrastructure orchestrator implementation..."

# Change to the repository root directory
Set-Location "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

# Check current branch
$currentBranch = git rev-parse --abbrev-ref HEAD
Write-Host "Current branch: $currentBranch"

# Create the feature branch if it doesn't exist
try {
    # Check if branch exists
    $branchExists = git show-ref --verify --quiet refs/heads/feature/advanced-autonomy-manager
    
    if (-not $branchExists) {
        Write-Host "Creating feature/advanced-autonomy-manager branch..."
        git checkout -b feature/advanced-autonomy-manager
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create feature branch"
        }
    } else {
        Write-Host "Branch feature/advanced-autonomy-manager already exists, checking it out..."
        git checkout feature/advanced-autonomy-manager
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to checkout feature branch"
        }
    }
} catch {
    Write-Host "Error handling branches: $_"
    exit 1
}

# Add the new files
Write-Host "Adding new files to git staging..."
git add development/managers/advanced-autonomy-manager/internal/infrastructure/infrastructure_orchestrator.go
git add development/managers/advanced-autonomy-manager/internal/infrastructure/service_dependency_graph.go
git add development/managers/advanced-autonomy-manager/internal/infrastructure/health_monitoring.go
git add development/managers/advanced-autonomy-manager/internal/infrastructure/startup_sequencer.go

# Commit the changes
Write-Host "Committing changes..."
git commit -m "Implement InfrastructureOrchestrator for automated stack startup (Plan-dev-v54)"

# Optional: Create the infrastructure startup feature branch
Write-Host "Creating feature/infrastructure-startup branch..."
git checkout -b feature/infrastructure-startup

Write-Host "Implementation complete!"
