# Test-ArchiveSearch.ps1
# Script de test pour les modules de recherche d'archives
# Version: 1.0
# Date: 2025-05-15

# Importer les modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$archiveSearchPath = Join-Path -Path $scriptPath -ChildPath "ArchiveSearch.ps1"
$metadataSearchPath = Join-Path -Path $scriptPath -ChildPath "MetadataSearch.ps1"
$cacheManagerPath = Join-Path -Path $scriptPath -ChildPath "CacheManager.ps1"

if (Test-Path -Path $archiveSearchPath) {
    . $archiveSearchPath
} else {
    Write-Error "Le fichier ArchiveSearch.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $metadataSearchPath) {
    . $metadataSearchPath
} else {
    Write-Error "Le fichier MetadataSearch.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $cacheManagerPath) {
    . $cacheManagerPath
} else {
    Write-Error "Le fichier CacheManager.ps1 est introuvable."
    exit 1
}

# Fonction pour creer des donnees de test
function New-TestArchiveData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestPath
    )

    # Creer le repertoire de test s'il n'existe pas
    if (-not (Test-Path -Path $TestPath -PathType Container)) {
        New-Item -Path $TestPath -ItemType Directory -Force | Out-Null
    }

    # Creer des sous-repertoires pour les archives
    $archive1Path = Join-Path -Path $TestPath -ChildPath "Archive1"
    $archive2Path = Join-Path -Path $TestPath -ChildPath "Archive2"
    $archive3Path = Join-Path -Path $TestPath -ChildPath "Archive3"

    New-Item -Path $archive1Path -ItemType Directory -Force | Out-Null
    New-Item -Path $archive2Path -ItemType Directory -Force | Out-Null
    New-Item -Path $archive3Path -ItemType Directory -Force | Out-Null

    # Creer des fichiers d'archive
    $archive1File = Join-Path -Path $archive1Path -ChildPath "archive1.dat"
    $archive2File = Join-Path -Path $archive2Path -ChildPath "archive2.dat"
    $archive3File = Join-Path -Path $archive3Path -ChildPath "archive3.dat"

    "Contenu de l'archive 1" | Set-Content -Path $archive1File -Force
    "Contenu de l'archive 2" | Set-Content -Path $archive2File -Force
    "Contenu de l'archive 3" | Set-Content -Path $archive3File -Force

    # Creer des fichiers d'index
    $index1 = @{
        Name        = "Index 1"
        Description = "Premier index de test"
        CreatedAt   = [DateTime]::Now.AddDays(-30).ToString("o")
        Archives    = @(
            @{
                Id          = "archive1-1"
                Name        = "Archive 1-1"
                Description = "Premiere archive de l'index 1"
                CreatedAt   = [DateTime]::Now.AddDays(-30).ToString("o")
                ModifiedAt  = [DateTime]::Now.AddDays(-25).ToString("o")
                ArchivedAt  = [DateTime]::Now.AddDays(-20).ToString("o")
                ArchivePath = $archive1File
                Type        = "Document"
                Category    = "Test"
                Tags        = @("test", "document", "important")
                Status      = "Active"
                Version     = "1.0"
                Author      = "Jean Dupont"
            },
            @{
                Id          = "archive1-2"
                Name        = "Archive 1-2"
                Description = "Deuxieme archive de l'index 1"
                CreatedAt   = [DateTime]::Now.AddDays(-28).ToString("o")
                ModifiedAt  = [DateTime]::Now.AddDays(-26).ToString("o")
                ArchivedAt  = [DateTime]::Now.AddDays(-24).ToString("o")
                ArchivePath = $archive1File
                Type        = "Image"
                Category    = "Test"
                Tags        = @("test", "image")
                Status      = "Archived"
                Version     = "1.1"
                Author      = "Marie Martin"
            }
        )
    }

    $index2 = @{
        Name        = "Index 2"
        Description = "Deuxieme index de test"
        CreatedAt   = [DateTime]::Now.AddDays(-20).ToString("o")
        Archives    = @(
            @{
                Id          = "archive2-1"
                Name        = "Archive 2-1"
                Description = "Premiere archive de l'index 2"
                CreatedAt   = [DateTime]::Now.AddDays(-20).ToString("o")
                ModifiedAt  = [DateTime]::Now.AddDays(-15).ToString("o")
                ArchivedAt  = [DateTime]::Now.AddDays(-10).ToString("o")
                ArchivePath = $archive2File
                Type        = "Document"
                Category    = "Production"
                Tags        = @("production", "document", "important")
                Status      = "Active"
                Version     = "2.0"
                Author      = "Jean Dupont"
            }
        )
    }

    $index3 = @{
        Name        = "Index 3"
        Description = "Troisieme index de test"
        CreatedAt   = [DateTime]::Now.AddDays(-10).ToString("o")
        Archives    = @(
            @{
                Id          = "archive3-1"
                Name        = "Archive 3-1"
                Description = "Premiere archive de l'index 3"
                CreatedAt   = [DateTime]::Now.AddDays(-10).ToString("o")
                ModifiedAt  = [DateTime]::Now.AddDays(-5).ToString("o")
                ArchivedAt  = [DateTime]::Now.AddDays(-1).ToString("o")
                ArchivePath = $archive3File
                Type        = "Video"
                Category    = "Production"
                Tags        = @("production", "video")
                Status      = "Active"
                Version     = "1.0"
                Author      = "Pierre Durand"
            },
            @{
                Id          = "archive3-2"
                Name        = "Archive 3-2"
                Description = "Deuxieme archive de l'index 3"
                CreatedAt   = [DateTime]::Now.AddDays(-8).ToString("o")
                ModifiedAt  = [DateTime]::Now.AddDays(-6).ToString("o")
                ArchivedAt  = [DateTime]::Now.AddDays(-4).ToString("o")
                ArchivePath = $archive3File
                Type        = "Audio"
                Category    = "Test"
                Tags        = @("test", "audio")
                Status      = "Inactive"
                Version     = "1.0"
                Author      = "Sophie Lefebvre"
            },
            @{
                Id          = "archive3-3"
                Name        = "Archive 3-3"
                Description = "Troisieme archive de l'index 3"
                CreatedAt   = [DateTime]::Now.AddDays(-5).ToString("o")
                ModifiedAt  = [DateTime]::Now.AddDays(-3).ToString("o")
                ArchivedAt  = [DateTime]::Now.AddDays(-1).ToString("o")
                ArchivePath = $archive3File
                Type        = "Document"
                Category    = "Production"
                Tags        = @("production", "document")
                Status      = "Active"
                Version     = "3.0"
                Author      = "Jean Dupont"
            }
        )
    }

    $index1 | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path -Path $archive1Path -ChildPath "index.index.json") -Force
    $index2 | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path -Path $archive2Path -ChildPath "index.index.json") -Force
    $index3 | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path -Path $archive3Path -ChildPath "index.index.json") -Force

    Write-Host "Donnees de test creees dans: $TestPath"
}

# Fonction pour executer les tests
function Test-ArchiveSearchFunctions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestPath
    )

    Write-Host "Test des fonctions de recherche d'archives..." -ForegroundColor Cyan

    # Test 1: Recherche d'index d'archives
    Write-Host "`nTest 1: Recherche d'index d'archives" -ForegroundColor Yellow
    $indexes = Find-ArchiveIndex -ArchivePath $TestPath
    Write-Host "Nombre d'index trouves: $($indexes.Count)"
    foreach ($index in $indexes) {
        Write-Host "  - $($index.Name): $($index.Description) ($($index.Archives.Count) archives)"
    }

    # Test 2: Recherche d'index d'archives avec filtre de date
    Write-Host "`nTest 2: Recherche d'index d'archives avec filtre de date" -ForegroundColor Yellow
    $startDate = [DateTime]::Now.AddDays(-25)
    $endDate = [DateTime]::Now.AddDays(-5)
    $indexes = Find-ArchiveIndex -ArchivePath $TestPath -StartDate $startDate -EndDate $endDate
    Write-Host "Nombre d'index trouves entre $($startDate.ToString('yyyy-MM-dd')) et $($endDate.ToString('yyyy-MM-dd')): $($indexes.Count)"
    foreach ($index in $indexes) {
        Write-Host "  - $($index.Name): $($index.Description) ($($index.Archives.Count) archives)"
    }

    # Test 3: Recherche d'archives par date
    Write-Host "`nTest 3: Recherche d'archives par date" -ForegroundColor Yellow
    $startDate = [DateTime]::Now.AddDays(-15)
    $archives = Get-ArchivesByDate -ArchivePath $TestPath -StartDate $startDate -DateField "ArchivedAt"
    Write-Host "Nombre d'archives archivees apres $($startDate.ToString('yyyy-MM-dd')): $($archives.Count)"
    foreach ($archive in $archives) {
        Write-Host "  - $($archive.Name): $($archive.Description) (Archivee le: $($archive.ArchivedAt))"
    }

    # Test 4: Recherche d'archives par metadonnees
    Write-Host "`nTest 4: Recherche d'archives par metadonnees" -ForegroundColor Yellow
    $metadata = @{
        Author = "Jean Dupont"
        Type   = "Document"
    }
    $archives = Find-ArchiveByMetadata -ArchivePath $TestPath -Metadata $metadata
    Write-Host "Nombre d'archives de type Document creees par Jean Dupont: $($archives.Count)"
    foreach ($archive in $archives) {
        Write-Host "  - $($archive.Name): $($archive.Description) (Type: $($archive.Type), Auteur: $($archive.Author))"
    }

    # Test 5: Extraction des metadonnees uniques
    Write-Host "`nTest 5: Extraction des metadonnees uniques" -ForegroundColor Yellow
    $uniqueMetadata = Get-UniqueArchiveMetadata -ArchivePath $TestPath -Properties @("Type", "Category", "Author") -IncludeCount
    Write-Host "Metadonnees uniques:"
    foreach ($property in $uniqueMetadata.Keys) {
        Write-Host "  Property: $property"
        foreach ($value in $uniqueMetadata[$property]) {
            Write-Host "    - $($value.Value): $($value.Count) occurrences"
        }
    }

    # Test 6: Test du cache
    Write-Host "`nTest 6: Test du cache" -ForegroundColor Yellow
    $cacheKey = "test-cache-key"
    $cacheData = @{
        Name      = "Test Cache"
        Value     = "Test Value"
        Timestamp = [DateTime]::Now.ToString("o")
    }

    # Initialiser le cache
    Initialize-ArchiveCache

    # Sauvegarder des donnees dans le cache
    $result = Save-ArchiveCache -Key $cacheKey -Data $cacheData
    Write-Host "Sauvegarde des donnees dans le cache: $result"

    # Recuperer des donnees du cache
    $cachedData = Get-ArchiveCache -Key $cacheKey
    Write-Host "Donnees recuperees du cache: $($cachedData.Name) - $($cachedData.Value)"

    # Nettoyer le cache
    $result = Clear-ArchiveCache -RemoveExpiredOnly
    Write-Host "Nettoyage du cache: $result"

    Write-Host "`nTous les tests sont termines." -ForegroundColor Green
}

# Executer les tests
$testPath = Join-Path -Path $env:TEMP -ChildPath "ArchiveSearchTest"
New-TestArchiveData -TestPath $testPath
Test-ArchiveSearchFunctions -TestPath $testPath

# Nettoyer les donnees de test
Remove-Item -Path $testPath -Recurse -Force
