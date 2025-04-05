# Script de verification avant push
# Version simplifiee pour eviter les problemes de syntaxe

param (
    [switch]$Force
)

# Obtenir le chemin racine du projet
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Set-Location $projectRoot

# Verifier si nous sommes dans un depot Git
if (-not (Test-Path "$projectRoot\.git")) {
    Write-Host "Ce dossier n'est pas un depot Git" -ForegroundColor "Red"
    exit 1
}

Write-Host "Execution des verifications avant push..." -ForegroundColor "Cyan"

# Verifier les conflits non resolus
$conflictFiles = git diff --name-only --diff-filter=U
if (-not [string]::IsNullOrEmpty($conflictFiles)) {
    Write-Host "Des conflits non resolus ont ete detectes dans les fichiers suivants:" -ForegroundColor "Red"
    $conflictFiles | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor "Red"
    }
    if (-not $Force) {
        Write-Host "Corrigez les conflits avant de proceder au push." -ForegroundColor "Red"
        exit 1
    }
}

# Verifier les fichiers volumineux
$largeFiles = @()
git status --porcelain | Where-Object { $_ -match '^\s*[AM]' } | ForEach-Object {
    $file = $_.Substring(3)
    $fileInfo = Get-Item $file -ErrorAction SilentlyContinue
    if ($fileInfo -and $fileInfo.Length -gt 5MB) {
        $largeFiles += @{
            Path = $file
            Size = [math]::Round($fileInfo.Length / 1MB, 2)
        }
    }
}

if ($largeFiles) {
    Write-Host "Des fichiers volumineux ont ete detectes:" -ForegroundColor "Yellow"
    $largeFiles | ForEach-Object {
        Write-Host "  - $($_.Path) ($($_.Size) MB)" -ForegroundColor "Yellow"
    }
    Write-Host "Considerez l'utilisation de Git LFS pour les fichiers volumineux" -ForegroundColor "Yellow"
    
    if (-not $Force) {
        $confirmation = Read-Host "Voulez-vous continuer malgre les fichiers volumineux? (O/N)"
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            exit 1
        }
    }
}

# Verifier les fins de ligne
$mixedLineEndings = git grep -l $'\r' -- "*.ps1" "*.py" "*.md" "*.json"
if (-not [string]::IsNullOrEmpty($mixedLineEndings)) {
    Write-Host "Des fichiers avec des fins de ligne mixtes ont ete detectes:" -ForegroundColor "Yellow"
    $mixedLineEndings -split "`n" | ForEach-Object {
        if (-not [string]::IsNullOrEmpty($_)) {
            Write-Host "  - $_" -ForegroundColor "Yellow"
        }
    }
    Write-Host "Considerez l'utilisation de 'git config --global core.autocrlf true' pour standardiser les fins de ligne" -ForegroundColor "Yellow"
}

# Afficher un resume des changements
Write-Host "`nResume des changements:" -ForegroundColor "Cyan"
git diff --staged --stat

# Demander confirmation pour le push
$doPush = Read-Host "`nVoulez-vous effectuer le push maintenant? (O/N)"
if ($doPush -eq "O" -or $doPush -eq "o") {
    git push
    Write-Host "Push effectue avec succes" -ForegroundColor "Green"
}
else {
    Write-Host "Push annule par l'utilisateur" -ForegroundColor "Yellow"
}

# Afficher l'aide si demande
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Write-Host "`nUtilisation: .\git-pre-push-check.ps1 [options]" -ForegroundColor "Cyan"
    Write-Host "`nOptions:" -ForegroundColor "Cyan"
    Write-Host "  -Force    Ignorer les echecs de verification et continuer" -ForegroundColor "Cyan"
    Write-Host "`nExemples:" -ForegroundColor "Cyan"
    Write-Host "  .\git-pre-push-check.ps1" -ForegroundColor "Cyan"
    Write-Host "  .\git-pre-push-check.ps1 -Force" -ForegroundColor "Cyan"
}
