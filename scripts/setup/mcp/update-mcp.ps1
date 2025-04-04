# Script pour mettre a jour les MCP

Write-Host "=== Mise a jour des MCP ===" -ForegroundColor Cyan

# Fonction pour mettre a jour un package npm
function Update-NpmPackage {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Package
    )
    
    Write-Host "Mise a jour de $Package..." -ForegroundColor Yellow
    npm update $Package
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $Package mis a jour" -ForegroundColor Green
    } else {
        Write-Host "❌ Erreur lors de la mise a jour de $Package" -ForegroundColor Red
    }
}

# Fonction pour mettre a jour un package pip
function Update-PipPackage {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Package
    )
    
    Write-Host "Mise a jour de $Package..." -ForegroundColor Yellow
    pip install --upgrade $Package
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $Package mis a jour" -ForegroundColor Green
    } else {
        Write-Host "❌ Erreur lors de la mise a jour de $Package" -ForegroundColor Red
    }
}

# Mettre a jour les packages npm
Write-Host "`n[1] Mise a jour des packages npm" -ForegroundColor Yellow
Update-NpmPackage "n8n-nodes-mcp"
Update-NpmPackage "@suekou/mcp-notion-server"
Update-NpmPackage "@modelcontextprotocol/server-openai"

# Mettre a jour les packages pip
Write-Host "`n[2] Mise a jour des packages pip" -ForegroundColor Yellow
Update-PipPackage "uvx"
Update-PipPackage "git+https://github.com/adhikasp/mcp-git-ingest"

# Verifier les mises a jour de Gateway
Write-Host "`n[3] Verification des mises a jour de Gateway" -ForegroundColor Yellow
$gatewayVersion = "v0.2.10" # Version actuelle
$gatewayLatestUrl = "https://api.github.com/repos/centralmind/gateway/releases/latest"

try {
    $latestRelease = Invoke-RestMethod -Uri $gatewayLatestUrl -ErrorAction Stop
    $latestVersion = $latestRelease.tag_name
    
    if ($latestVersion -ne $gatewayVersion) {
        Write-Host "Nouvelle version de Gateway disponible : $latestVersion (actuelle : $gatewayVersion)" -ForegroundColor Yellow
        Write-Host "Telechargez la nouvelle version depuis : https://github.com/centralmind/gateway/releases/latest" -ForegroundColor Yellow
    } else {
        Write-Host "✅ Gateway est a jour (version $gatewayVersion)" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Erreur lors de la verification des mises a jour de Gateway : $_" -ForegroundColor Red
}

Write-Host "`n=== Mise a jour terminee ===" -ForegroundColor Cyan
Write-Host "Les MCP ont ete mis a jour."
Write-Host "Redemarrez n8n pour appliquer les changements."

