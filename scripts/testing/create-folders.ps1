# Script pour creer la structure de dossiers

Write-Host "=== Creation de la structure de dossiers ===" -ForegroundColor Cyan

# Structure de dossiers a creer
$folders = @(
    "src",
    "src/workflows",
    "src/mcp",
    "src/mcp/batch",
    "src/mcp/config",
    "scripts",
    "scripts/setup",
    "scripts/maintenance",
    "config",
    "logs",
    "docs",
    "docs/guides",
    "docs/api",
    "tests",
    "tools",
    "assets"
)

# Creer les dossiers
foreach ($folder in $folders) {
    if (-not (Test-Path ".\$folder")) {
        New-Item -ItemType Directory -Path ".\$folder" | Out-Null
        Write-Host "Dossier $folder cree" -ForegroundColor Green
    } else {
        Write-Host "Dossier $folder existe deja" -ForegroundColor Green
    }
}

Write-Host "`n=== Structure de dossiers creee ===" -ForegroundColor Cyan
