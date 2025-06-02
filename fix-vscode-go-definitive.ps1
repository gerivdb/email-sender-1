#!/usr/bin/env pwsh

# Script de résolution définitive des erreurs Go Toolchain dans VS Code
Write-Host "🔧 Résolution définitive des erreurs Go Toolchain VS Code..." -ForegroundColor Yellow

# 1. Arrêter tous les processus VS Code
Write-Host "`n📱 Arrêt de tous les processus VS Code..." -ForegroundColor Cyan
try {
    Get-Process "Code" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    Write-Host "   ✅ Processus VS Code arrêtés" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Aucun processus VS Code à arrêter" -ForegroundColor Yellow
}

# 2. Nettoyer le cache Go de VS Code
Write-Host "`n🧹 Nettoyage du cache Go VS Code..." -ForegroundColor Cyan
$vscodeGoCache = "$env:USERPROFILE\.vscode\extensions\golang.go-*"
if (Test-Path $vscodeGoCache) {
    Remove-Item $vscodeGoCache -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "   ✅ Cache Go VS Code nettoyé" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Pas de cache Go VS Code trouvé" -ForegroundColor Yellow
}

# 3. Forcer les variables d'environnement système
Write-Host "`n🌍 Configuration des variables d'environnement système..." -ForegroundColor Cyan
$properGoRoot = "$env:USERPROFILE\sdk\go1.23.9"
$properGoPath = "$env:USERPROFILE\go"

# Définir les variables d'environnement machine
[Environment]::SetEnvironmentVariable("GOROOT", $properGoRoot, "User")
[Environment]::SetEnvironmentVariable("GOPATH", $properGoPath, "User")
Write-Host "   ✅ Variables d'environnement système configurées" -ForegroundColor Green

# 4. Mettre à jour les paramètres VS Code workspace
Write-Host "`n⚙️  Mise à jour des paramètres VS Code workspace..." -ForegroundColor Cyan
$settingsPath = ".vscode\settings.json"

if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath | ConvertFrom-Json
} else {
    New-Item -Path ".vscode" -ItemType Directory -Force | Out-Null
    $settings = @{}
}

# Forcer les paramètres Go
$settings."go.goroot" = $properGoRoot.Replace('\', '\\')
$settings."go.gopath" = $properGoPath.Replace('\', '\\')
$settings."go.toolsGopath" = $properGoPath.Replace('\', '\\')
$settings."go.alternateTools" = @{
    "go" = "$properGoRoot\bin\go.exe".Replace('\', '\\')
}
$settings."go.useLanguageServer" = $true
$settings."gopls" = @{
    "build.env" = @{
        "GOROOT" = $properGoRoot.Replace('\', '\\')
        "GOPATH" = $properGoPath.Replace('\', '\\')
    }
}

$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
Write-Host "   ✅ Paramètres VS Code workspace mis à jour" -ForegroundColor Green

# 5. Nettoyer le cache Go module corrompu
Write-Host "`n🗑️  Nettoyage du cache Go module corrompu..." -ForegroundColor Cyan
try {
    $corruptedToolchain = "$env:USERPROFILE\go\pkg\mod\golang.org\toolchain@v0.0.1-go1.23.9.windows-amd64"
    if (Test-Path $corruptedToolchain) {
        # Prendre possession du dossier
        takeown /f $corruptedToolchain /r /d y 2>$null | Out-Null
        icacls $corruptedToolchain /grant "$env:USERNAME:(F)" /t 2>$null | Out-Null
        Remove-Item $corruptedToolchain -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "   ✅ Cache Go module corrompu supprimé" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Pas de cache corrompu trouvé" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠️  Impossible de supprimer le cache corrompu (peut nécessiter des droits admin)" -ForegroundColor Yellow
}

# 6. Vérifier l'installation Go
Write-Host "`n🧪 Vérification de l'installation Go..." -ForegroundColor Cyan
& "$properGoRoot\bin\go.exe" version
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Installation Go valide" -ForegroundColor Green
} else {
    Write-Host "   ❌ Problème avec l'installation Go" -ForegroundColor Red
}

# 7. Tester la compilation
Write-Host "`n🔨 Test de compilation..." -ForegroundColor Cyan
Push-Location "cmd\roadmap-cli"
try {
    & "$properGoRoot\bin\go.exe" build -o test-build.exe
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Compilation réussie" -ForegroundColor Green
        Remove-Item "test-build.exe" -ErrorAction SilentlyContinue
    } else {
        Write-Host "   ❌ Échec de compilation" -ForegroundColor Red
    }
} finally {
    Pop-Location
}

Write-Host "`n🎯 Instructions finales:" -ForegroundColor Yellow
Write-Host "   1. Redémarrez complètement VS Code" -ForegroundColor Cyan
Write-Host "   2. Ouvrez le Command Palette (Ctrl+Shift+P)" -ForegroundColor Cyan
Write-Host "   3. Exécutez: 'Go: Restart Language Server'" -ForegroundColor Cyan
Write-Host "   4. Si nécessaire: 'Developer: Reload Window'" -ForegroundColor Cyan

Write-Host "`n✅ Script de résolution définitive terminé!" -ForegroundColor Green
Write-Host "Les erreurs Go Toolchain devraient être résolues après redémarrage de VS Code." -ForegroundColor Green
