# Create base folders
New-Item -Path ".\projet" -ItemType Directory -Force
New-Item -Path ".\development" -ItemType Directory -Force

# Project structure
$projectFolders = @(
    ".\projet\architecture\decisions",
    ".\projet\architecture\diagrams",
    ".\projet\documentation\api",
    ".\projet\documentation\technique",
    ".\projet\documentation\workflow",
    ".\projet\guides\installation",
    ".\projet\guides\utilisation",
    ".\projet\guides\integrations",
    ".\projet\roadmaps\plans",
    ".\projet\roadmaps\journal",
    ".\projet\roadmaps\tasks",
    ".\projet\specifications\fonctionnelles",
    ".\projet\specifications\techniques",
    ".\projet\tutorials\examples"
)

# Development structure
$developmentFolders = @(
    ".\development\api\examples",
    ".\development\api\documentation",
    ".\development\communications",
    ".\development\n8n-internals",
    ".\development\roadmap\analysis",
    ".\development\roadmap\journal",
    ".\development\roadmap\plans",
    ".\development\roadmap\tasks",
    ".\development\testing\performance",
    ".\development\testing\reports",
    ".\development\testing\tests",
    ".\development\workflows",
    ".\development\methodologies\modes",
    ".\development\tools\scripts",
    ".\development\tools\utilities"
)

# Create project folders
foreach ($folder in $projectFolders) {
    New-Item -Path $folder -ItemType Directory -Force
    Write-Host "Created: $folder" -ForegroundColor Green
}

# Create development folders
foreach ($folder in $developmentFolders) {
    New-Item -Path $folder -ItemType Directory -Force
    Write-Host "Created: $folder" -ForegroundColor Green
}

Write-Host "Folder structure created successfully!" -ForegroundColor Green
