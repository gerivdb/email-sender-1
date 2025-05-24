# Script pour vÃ©rifier l'Ã©tat de la migration de la documentation
# Ce script vÃ©rifie si tous les fichiers ont Ã©tÃ© migrÃ©s correctement

# DÃ©finition des mappings de chemins
$pathMappings = @(
    @{ Old = "docs\architecture"; New = "projet\architecture" },
    @{ Old = "docs\tutorials"; New = "projet\tutorials" },
    @{ Old = "docs\guides"; New = "projet\guides" },
    @{ Old = "docs\development\roadmap"; New = "projet\roadmaps" },
    @{ Old = "docs\api"; New = "development\api" },
    @{ Old = "docs\development\communications"; New = "development\communications" },
    @{ Old = "docs\development\n8n-internals"; New = "development\n8n-internals" },
    @{ Old = "docs\development\testing"; New = "development\testing" },
    @{ Old = "docs\development\tests"; New = "development\testing\tests" },
    @{ Old = "docs\development\workflows"; New = "development\workflows" },
    @{ Old = "docs\guides\methodologies"; New = "development\methodologies" }
)

# Fonction pour vÃ©rifier si un dossier existe
function Test-DirectoryExists {
    param (
        [string]$path
    )

    if (Test-Path -Path $path -PathType Container) {
        return $true
    } else {
        return $false
    }
}

# Fonction pour compter les fichiers dans un dossier
function Measure-Files {
    param (
        [string]$path
    )

    if (-not (Test-Path -Path $path)) {
        return 0
    }

    $files = Get-ChildItem -Path $path -Recurse -File
    return $files.Count
}

# VÃ©rification des dossiers
Write-Host "VÃ©rification des dossiers..." -ForegroundColor Cyan

$results = @()

foreach ($mapping in $pathMappings) {
    $oldExists = Test-DirectoryExists -path $mapping.Old
    $newExists = Test-DirectoryExists -path $mapping.New
    $oldFileCount = Measure-Files -path $mapping.Old
    $newFileCount = Measure-Files -path $mapping.New

    $status = if ($oldExists -and $newExists -and $newFileCount -gt 0) {
        "MigrÃ©"
    } elseif ($oldExists -and -not $newExists) {
        "Non migrÃ©"
    } elseif (-not $oldExists -and $newExists) {
        "Nouveau"
    } else {
        "N/A"
    }

    $results += [PSCustomObject]@{
        "Ancien chemin" = $mapping.Old
        "Nouveau chemin" = $mapping.New
        "Ancien existe" = $oldExists
        "Nouveau existe" = $newExists
        "Fichiers (ancien)" = $oldFileCount
        "Fichiers (nouveau)" = $newFileCount
        "Statut" = $status
    }
}

# Affichage des rÃ©sultats
$results | Format-Table -AutoSize

# VÃ©rification des fichiers de rÃ©fÃ©rence
Write-Host "VÃ©rification des rÃ©fÃ©rences..." -ForegroundColor Cyan

$referencesFound = 0
$files = Get-ChildItem -Path . -Recurse -Include *.md, *.txt, *.ps1, *.py, *.js, *.html, *.css, *.json, *.yaml, *.yml -File

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    $foundReference = $false

    foreach ($mapping in $pathMappings) {
        if ($content -match [regex]::Escape($mapping.Old)) {
            $foundReference = $true
            $referencesFound++
            Write-Host "RÃ©fÃ©rence trouvÃ©e dans: $($file.FullName)" -ForegroundColor Yellow
            Write-Host "  Ancien chemin: $($mapping.Old)" -ForegroundColor Yellow
            Write-Host "  Nouveau chemin: $($mapping.New)" -ForegroundColor Yellow
            break
        }
    }

    if ($foundReference) {
        break
    }
}

if ($referencesFound -eq 0) {
    Write-Host "Aucune rÃ©fÃ©rence Ã  l'ancienne structure trouvÃ©e." -ForegroundColor Green
} else {
    Write-Host "$referencesFound rÃ©fÃ©rences Ã  l'ancienne structure trouvÃ©es." -ForegroundColor Yellow
}

# RÃ©sumÃ©
Write-Host "RÃ©sumÃ© de la migration:" -ForegroundColor Cyan
$migratedCount = ($results | Where-Object { $_.Statut -eq "MigrÃ©" }).Count
$notMigratedCount = ($results | Where-Object { $_.Statut -eq "Non migrÃ©" }).Count
$newCount = ($results | Where-Object { $_.Statut -eq "Nouveau" }).Count

Write-Host "Dossiers migrÃ©s: $migratedCount" -ForegroundColor Green
Write-Host "Dossiers non migrÃ©s: $notMigratedCount" -ForegroundColor Yellow
Write-Host "Nouveaux dossiers: $newCount" -ForegroundColor Cyan
Write-Host "RÃ©fÃ©rences Ã  mettre Ã  jour: $referencesFound" -ForegroundColor Yellow

