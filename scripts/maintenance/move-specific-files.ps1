# Script pour déplacer les fichiers spécifiques qui peuvent être rangés
# Ce script déplace JOURNAL_DE_BORD.md, commit-docs.cmd et commit-final-docs.cmd dans leurs dossiers respectifs

Write-Host "=== Déplacement des fichiers spécifiques ===" -ForegroundColor Cyan

# Obtenir le chemin racine du projet
$projectRoot = (Get-Location).Path
Set-Location $projectRoot

# 1. Déplacement de JOURNAL_DE_BORD.md vers le dossier md
Write-Host "`n1. Déplacement de JOURNAL_DE_BORD.md vers le dossier md..." -ForegroundColor Yellow

$mdFile = "JOURNAL_DE_BORD.md"
$mdFolder = "md"

# Vérifier si le fichier existe
if (Test-Path $mdFile) {
    # Vérifier si le dossier de destination existe
    if (-not (Test-Path $mdFolder)) {
        New-Item -ItemType Directory -Path $mdFolder -Force | Out-Null
        Write-Host "  Dossier $mdFolder créé" -ForegroundColor Green
    }
    
    # Déplacer le fichier
    $destFile = Join-Path $mdFolder $mdFile
    if (Test-Path $destFile) {
        # Le fichier existe déjà dans la destination
        $sourceFile = Get-Item $mdFile
        $existingFile = Get-Item $destFile
        
        if ($sourceFile.LastWriteTime -gt $existingFile.LastWriteTime) {
            # Le fichier source est plus récent
            Move-Item -Path $mdFile -Destination $destFile -Force
            Write-Host "  Fichier $mdFile remplacé (plus récent)" -ForegroundColor Blue
        } else {
            Write-Host "  Fichier $mdFile ignoré (plus ancien ou identique)" -ForegroundColor Gray
        }
    } else {
        # Le fichier n'existe pas dans la destination
        Move-Item -Path $mdFile -Destination $destFile
        Write-Host "  Fichier $mdFile déplacé vers $mdFolder" -ForegroundColor Green
    }
} else {
    Write-Host "  Fichier $mdFile non trouvé" -ForegroundColor Yellow
}

# 2. Déplacement des fichiers commit-docs.cmd et commit-final-docs.cmd vers le dossier cmd
Write-Host "`n2. Déplacement des fichiers commit-*.cmd vers le dossier cmd..." -ForegroundColor Yellow

$cmdFiles = @("commit-docs.cmd", "commit-final-docs.cmd")
$cmdFolder = "cmd"

# Vérifier si le dossier de destination existe
if (-not (Test-Path $cmdFolder)) {
    New-Item -ItemType Directory -Path $cmdFolder -Force | Out-Null
    Write-Host "  Dossier $cmdFolder créé" -ForegroundColor Green
}

foreach ($cmdFile in $cmdFiles) {
    # Vérifier si le fichier existe
    if (Test-Path $cmdFile) {
        # Déplacer le fichier
        $destFile = Join-Path $cmdFolder $cmdFile
        if (Test-Path $destFile) {
            # Le fichier existe déjà dans la destination
            $sourceFile = Get-Item $cmdFile
            $existingFile = Get-Item $destFile
            
            if ($sourceFile.LastWriteTime -gt $existingFile.LastWriteTime) {
                # Le fichier source est plus récent
                Move-Item -Path $cmdFile -Destination $destFile -Force
                Write-Host "  Fichier $cmdFile remplacé (plus récent)" -ForegroundColor Blue
            } else {
                Write-Host "  Fichier $cmdFile ignoré (plus ancien ou identique)" -ForegroundColor Gray
            }
        } else {
            # Le fichier n'existe pas dans la destination
            Move-Item -Path $cmdFile -Destination $destFile
            Write-Host "  Fichier $cmdFile déplacé vers $cmdFolder" -ForegroundColor Green
        }
    } else {
        Write-Host "  Fichier $cmdFile non trouvé" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Déplacement terminé ===" -ForegroundColor Cyan
