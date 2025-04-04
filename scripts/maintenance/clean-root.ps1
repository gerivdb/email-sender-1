# Script pour nettoyer les fichiers restants a la racine

Write-Host "=== Nettoyage des fichiers restants a la racine ===" -ForegroundColor Cyan

# Fichiers a conserver a la racine
$keepFiles = @(
    "README.md",
    ".gitignore"
)

# Obtenir la liste des fichiers a la racine
$rootFiles = Get-ChildItem -Path "." -File | Where-Object { $keepFiles -notcontains $_.Name }

if ($rootFiles -eq $null -or $rootFiles.Count -eq 0) {
    Write-Host "Aucun fichier a nettoyer a la racine" -ForegroundColor Green
    exit
}

Write-Host "$($rootFiles.Count) fichiers a nettoyer a la racine:" -ForegroundColor Yellow
foreach ($file in $rootFiles) {
    Write-Host "- $($file.Name)" -ForegroundColor Yellow
}

Write-Host "`nComment souhaitez-vous proceder ?" -ForegroundColor Cyan
Write-Host "1. Deplacer les fichiers vers les dossiers appropries" -ForegroundColor Yellow
Write-Host "2. Archiver les fichiers dans un dossier 'archive'" -ForegroundColor Yellow
Write-Host "3. Supprimer les fichiers" -ForegroundColor Yellow
Write-Host "4. Annuler" -ForegroundColor Yellow

$choice = Read-Host "Votre choix (1-4)"

switch ($choice) {
    "1" {
        # Deplacer les fichiers
        Write-Host "`nDeplacement des fichiers..." -ForegroundColor Cyan
        
        # Regles de deplacement
        $moveRules = @(
            @{Pattern = "*.json"; Destination = "src\workflows"; Description = "Workflows n8n"},
            @{Pattern = "*.json.bak"; Destination = "src\workflows\backup"; Description = "Backups de workflows"},
            @{Pattern = "*.md"; Destination = "docs"; Description = "Documentation"},
            @{Pattern = "GUIDE_*.md"; Destination = "docs\guides"; Description = "Guides d'utilisation"},
            @{Pattern = "README_*.md"; Destination = "docs"; Description = "Documentation README"},
            @{Pattern = "*.cmd"; Destination = "tools"; Description = "Scripts batch"},
            @{Pattern = "mcp-*.cmd"; Destination = "src\mcp\batch"; Description = "Fichiers batch MCP"},
            @{Pattern = "*.ps1"; Destination = "scripts"; Description = "Scripts PowerShell"},
            @{Pattern = "*.py"; Destination = "src"; Description = "Scripts Python"},
            @{Pattern = "*.txt"; Destination = "config"; Description = "Fichiers texte"},
            @{Pattern = "*.env*"; Destination = "config"; Description = "Fichiers d'environnement"}
        )
        
        foreach ($rule in $moveRules) {
            $matchingFiles = $rootFiles | Where-Object { $_.Name -like $rule.Pattern }
            
            if ($matchingFiles -ne $null -and $matchingFiles.Count -gt 0) {
                # Verifier si le dossier de destination existe
                if (-not (Test-Path $rule.Destination)) {
                    New-Item -ItemType Directory -Path $rule.Destination -Force | Out-Null
                    Write-Host "Dossier $($rule.Destination) cree" -ForegroundColor Green
                }
                
                foreach ($file in $matchingFiles) {
                    Move-Item -Path $file.FullName -Destination "$($rule.Destination)\$($file.Name)" -Force
                    Write-Host "Fichier $($file.Name) deplace vers $($rule.Destination)" -ForegroundColor Green
                }
            }
        }
        
        # Verifier s'il reste des fichiers non deplaces
        $remainingFiles = Get-ChildItem -Path "." -File | Where-Object { $keepFiles -notcontains $_.Name }
        
        if ($remainingFiles -ne $null -and $remainingFiles.Count -gt 0) {
            Write-Host "`nIl reste $($remainingFiles.Count) fichiers non deplaces:" -ForegroundColor Yellow
            foreach ($file in $remainingFiles) {
                Write-Host "- $($file.Name)" -ForegroundColor Yellow
            }
            
            Write-Host "`nVoulez-vous archiver ces fichiers ? (O/N)" -ForegroundColor Yellow
            $archiveRemaining = Read-Host
            
            if ($archiveRemaining -eq "O" -or $archiveRemaining -eq "o") {
                # Creer le dossier archive
                if (-not (Test-Path "archive")) {
                    New-Item -ItemType Directory -Path "archive" -Force | Out-Null
                    Write-Host "Dossier archive cree" -ForegroundColor Green
                }
                
                foreach ($file in $remainingFiles) {
                    Move-Item -Path $file.FullName -Destination "archive\$($file.Name)" -Force
                    Write-Host "Fichier $($file.Name) archive" -ForegroundColor Green
                }
            }
        }
    }
    "2" {
        # Archiver les fichiers
        Write-Host "`nArchivage des fichiers..." -ForegroundColor Cyan
        
        # Creer le dossier archive
        if (-not (Test-Path "archive")) {
            New-Item -ItemType Directory -Path "archive" -Force | Out-Null
            Write-Host "Dossier archive cree" -ForegroundColor Green
        }
        
        foreach ($file in $rootFiles) {
            Move-Item -Path $file.FullName -Destination "archive\$($file.Name)" -Force
            Write-Host "Fichier $($file.Name) archive" -ForegroundColor Green
        }
    }
    "3" {
        # Supprimer les fichiers
        Write-Host "`nAttention: Cette action va supprimer definitivement les fichiers!" -ForegroundColor Red
        Write-Host "Etes-vous sur de vouloir continuer ? (O/N)" -ForegroundColor Red
        $confirmDelete = Read-Host
        
        if ($confirmDelete -eq "O" -or $confirmDelete -eq "o") {
            foreach ($file in $rootFiles) {
                Remove-Item -Path $file.FullName -Force
                Write-Host "Fichier $($file.Name) supprime" -ForegroundColor Green
            }
        } else {
            Write-Host "Suppression annulee" -ForegroundColor Yellow
        }
    }
    "4" {
        Write-Host "Operation annulee" -ForegroundColor Yellow
        exit
    }
    default {
        Write-Host "Choix invalide" -ForegroundColor Red
        exit
    }
}

Write-Host "`n=== Nettoyage termine ===" -ForegroundColor Cyan
