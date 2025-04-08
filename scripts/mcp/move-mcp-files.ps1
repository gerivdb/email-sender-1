# Script pour deplacer les fichiers MCP dans la nouvelle structure

Write-Host "=== Deplacement des fichiers MCP ===" -ForegroundColor Cyan

# Deplacer les fichiers batch MCP
$batchFiles = @(
    "mcp-standard.cmd",
    "mcp-notion.cmd",
    "gateway.exe.cmd",
    "mcp-git-ingest.cmd"
)

foreach ($file in $batchFiles) {
    if (Test-Path ".\$file") {
        Copy-Item ".\$file" ".\src\mcp\batch\$file"
        Write-Host "Fichier $file copie dans src/mcp/batch" -ForegroundColor Green
    } elseif (Test-Path ".\mcp\batch\$file") {
        Copy-Item ".\mcp\batch\$file" ".\src\mcp\batch\$file"
        Write-Host "Fichier mcp/batch/$file copie dans src/mcp/batch" -ForegroundColor Green
    } else {
        Write-Host "Fichier $file non trouve" -ForegroundColor Yellow
    }
}

# Deplacer les fichiers de configuration MCP
$configFiles = @(
    "mcp-config.json",
    "mcp-config-fixed.json",
    "gateway.yaml"
)

foreach ($file in $configFiles) {
    if (Test-Path ".\$file") {
        Copy-Item ".\$file" ".\src\mcp\config\$file"
        Write-Host "Fichier $file copie dans src/mcp/config" -ForegroundColor Green
    } elseif (Test-Path ".\mcp\config\$file") {
        Copy-Item ".\mcp\config\$file" ".\src\mcp\config\$file"
        Write-Host "Fichier mcp/config/$file copie dans src/mcp/config" -ForegroundColor Green
    } else {
        Write-Host "Fichier $file non trouve" -ForegroundColor Yellow
    }
}

# Deplacer les workflows
$workflowFiles = @(
    "test-mcp-workflow-updated.json",
    "test-mcp-git-ingest-workflow.json",
    "EMAIL_SENDER_1 (5).json"
)

foreach ($file in $workflowFiles) {
    if (Test-Path ".\$file") {
        Copy-Item ".\$file" ".\src\workflows\$file"
        Write-Host "Fichier $file copie dans src/workflows" -ForegroundColor Green
    } elseif (Test-Path ".\mcp\workflows\$file") {
        Copy-Item ".\mcp\workflows\$file" ".\src\workflows\$file"
        Write-Host "Fichier mcp/workflows/$file copie dans src/workflows" -ForegroundColor Green
    } else {
        Write-Host "Fichier $file non trouve" -ForegroundColor Yellow
    }
}

# Deplacer les scripts de configuration
$setupScripts = @(
    "configure-n8n-mcp.ps1",
    "configure-mcp-git-ingest.ps1",
    "setup-mcp.ps1",
    "setup-mcp-fixed.ps1",
    "setup-mcp-gateway.ps1",
    "setup-mcp-notion.ps1",
    "setup-environment.ps1"
)

foreach ($file in $setupScripts) {
    if (Test-Path ".\$file") {
        Copy-Item ".\$file" ".\scripts\setup\$file"
        Write-Host "Fichier $file copie dans scripts/setup" -ForegroundColor Green
    } elseif (Test-Path ".\scripts\$file") {
        Copy-Item ".\scripts\$file" ".\scripts\setup\$file"
        Write-Host "Fichier scripts/$file copie dans scripts/setup" -ForegroundColor Green
    } else {
        Write-Host "Fichier $file non trouve" -ForegroundColor Yellow
    }
}

# Deplacer les scripts de maintenance
$maintenanceScripts = @(
    "update-mcp.ps1",
    "cleanup-mcp-files.ps1",
    "organize-repo.ps1",
    "organize-repo-fixed.ps1",
    "create-folders.ps1",
    "move-mcp-files.ps1",
    "check-workflow-fixed.ps1",
    "mcp-fix.ps1"
)

foreach ($file in $maintenanceScripts) {
    if (Test-Path ".\$file") {
        Copy-Item ".\$file" ".\scripts\maintenance\$file"
        Write-Host "Fichier $file copie dans scripts/maintenance" -ForegroundColor Green
    } elseif (Test-Path ".\scripts\$file") {
        Copy-Item ".\scripts\$file" ".\scripts\maintenance\$file"
        Write-Host "Fichier scripts/$file copie dans scripts/maintenance" -ForegroundColor Green
    } else {
        Write-Host "Fichier $file non trouve" -ForegroundColor Yellow
    }
}

# Deplacer les scripts de demarrage
$startScripts = @(
    "start-n8n.cmd",
    "start-n8n-complete.cmd",
    "start-n8n-mcp.cmd"
)

foreach ($file in $startScripts) {
    if (Test-Path ".\$file") {
        Copy-Item ".\$file" ".\tools\$file"
        Write-Host "Fichier $file copie dans tools" -ForegroundColor Green
    } else {
        Write-Host "Fichier $file non trouve" -ForegroundColor Yellow
    }
}

# Deplacer la documentation
$docFiles = @(
    "GUIDE_FINAL_MCP.md",
    "GUIDE_MCP_GATEWAY.md",
    "GUIDE_MCP_GIT_INGEST.md",
    "CONFIGURATION_MCP_MISE_A_JOUR.md",
    "CONFIGURATION_MCP_GATEWAY_N8N.md",
    "GUIDE_INSTALLATION_COMPLET.md"
)

foreach ($file in $docFiles) {
    if (Test-Path ".\$file") {
        Copy-Item ".\$file" ".\docs\guides\$file"
        Write-Host "Fichier $file copie dans docs/guides" -ForegroundColor Green
    } else {
        Write-Host "Fichier $file non trouve" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Deplacement des fichiers termine ===" -ForegroundColor Cyan
Write-Host "Les fichiers ont ete copies dans la nouvelle structure."
Write-Host "Vous pouvez maintenant verifier que tout est correct avant de supprimer les fichiers originaux."
