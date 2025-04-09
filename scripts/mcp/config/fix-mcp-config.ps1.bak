# Script pour corriger l'emplacement des fichiers de configuration MCP

Write-Host "=== Correction de l'emplacement des fichiers de configuration MCP ===" -ForegroundColor Cyan

# Deplacer les fichiers de configuration MCP
$configFiles = @(
    "mcp-config.json",
    "mcp-config-fixed.json"
)

foreach ($file in $configFiles) {
    # Verifier si le fichier existe dans src/workflows
    if (Test-Path ".\src\workflows\$file") {
        # Verifier si le dossier src/mcp/config existe
        if (-not (Test-Path ".\src\mcp\config")) {
            New-Item -ItemType Directory -Path ".\src\mcp\config" -Force | Out-Null
            Write-Host "Dossier src/mcp/config cree" -ForegroundColor Green
        }
        
        # Deplacer le fichier
        Move-Item -Path ".\src\workflows\$file" -Destination ".\src\mcp\config\$file" -Force
        Write-Host "Fichier $file deplace de src/workflows vers src/mcp/config" -ForegroundColor Green
    } else {
        Write-Host "Fichier $file non trouve dans src/workflows" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Correction terminee ===" -ForegroundColor Cyan
