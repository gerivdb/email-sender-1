# Script pour vérifier l'état de la migration de la documentation
# Ce script vérifie si tous les fichiers ont été migrés correctement

# Définition des mappings de chemins
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

# Fonction pour vérifier si un dossier existe
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
function Count-Files {
    param (
        [string]$path
    )

    if (-not (Test-Path -Path $path)) {
        return 0
    }

    $files = Get-ChildItem -Path $path -Recurse -File
    return $files.Count
}

# Vérification des dossiers
Write-Host "Vérification des dossiers..." -ForegroundColor Cyan

$results = @()

foreach ($mapping in $pathMappings) {
    $oldExists = Test-DirectoryExists -path $mapping.Old
    $newExists = Test-DirectoryExists -path $mapping.New
    $oldFileCount = Count-Files -path $mapping.Old
    $newFileCount = Count-Files -path $mapping.New

    $status = if ($oldExists -and $newExists -and $newFileCount -gt 0) {
        "Migré"
    } elseif ($oldExists -and -not $newExists) {
        "Non migré"
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

# Affichage des résultats
$results | Format-Table -AutoSize

# Vérification des fichiers de référence
Write-Host "Vérification des références..." -ForegroundColor Cyan

$referencesFound = 0
$files = Get-ChildItem -Path . -Recurse -Include *.md, *.txt, *.ps1, *.py, *.js, *.html, *.css, *.json, *.yaml, *.yml -File

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    $foundReference = $false

    foreach ($mapping in $pathMappings) {
        if ($content -match [regex]::Escape($mapping.Old)) {
            $foundReference = $true
            $referencesFound++
            Write-Host "Référence trouvée dans: $($file.FullName)" -ForegroundColor Yellow
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
    Write-Host "Aucune référence à l'ancienne structure trouvée." -ForegroundColor Green
} else {
    Write-Host "$referencesFound références à l'ancienne structure trouvées." -ForegroundColor Yellow
}

# Résumé
Write-Host "Résumé de la migration:" -ForegroundColor Cyan
$migratedCount = ($results | Where-Object { $_.Statut -eq "Migré" }).Count
$notMigratedCount = ($results | Where-Object { $_.Statut -eq "Non migré" }).Count
$newCount = ($results | Where-Object { $_.Statut -eq "Nouveau" }).Count

Write-Host "Dossiers migrés: $migratedCount" -ForegroundColor Green
Write-Host "Dossiers non migrés: $notMigratedCount" -ForegroundColor Yellow
Write-Host "Nouveaux dossiers: $newCount" -ForegroundColor Cyan
Write-Host "Références à mettre à jour: $referencesFound" -ForegroundColor Yellow
