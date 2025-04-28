# Script de réorganisation de la documentation
# Ce script déplace les fichiers de documentation de l'ancienne structure vers la nouvelle

# Définition des chemins
$docsPath = ".\docs"
$projetPath = ".\projet"
$developmentPath = ".\development"

# Création des dossiers principaux s'ils n'existent pas déjà
if (-not (Test-Path -Path $projetPath)) {
    New-Item -Path $projetPath -ItemType Directory -Force
}

if (-not (Test-Path -Path $developmentPath)) {
    New-Item -Path $developmentPath -ItemType Directory -Force
}

# Création de la structure de base pour le dossier projet
$projetCategories = @(
    "architecture",
    "documentation",
    "guides",
    "roadmaps",
    "specifications",
    "tutorials"
)

foreach ($category in $projetCategories) {
    $path = Join-Path -Path $projetPath -ChildPath $category
    if (-not (Test-Path -Path $path)) {
        New-Item -Path $path -ItemType Directory -Force
        # Création du fichier README.md
        $readmePath = Join-Path -Path $path -ChildPath "README.md"
        $readmeContent = @"
# $(($category.charAt(0).ToString().ToUpper() + $category.Substring(1)))

Cette documentation fait partie de la section Projet.

## Contenu

Cette section contient la documentation relative à $category.

## Structure

```
projet/$category/
├── README.md (ce fichier)
└── ...
```
"@
        Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
    }
}

# Création de la structure de base pour le dossier development
$developmentCategories = @(
    "api",
    "communications",
    "n8n-internals",
    "roadmap",
    "testing",
    "workflows",
    "methodologies",
    "tools"
)

foreach ($category in $developmentCategories) {
    $path = Join-Path -Path $developmentPath -ChildPath $category
    if (-not (Test-Path -Path $path)) {
        New-Item -Path $path -ItemType Directory -Force
        # Création du fichier README.md
        $readmePath = Join-Path -Path $path -ChildPath "README.md"
        $readmeContent = @"
# $(($category.charAt(0).ToString().ToUpper() + $category.Substring(1)))

Cette documentation fait partie de la section Development.

## Contenu

Cette section contient la documentation relative à $category.

## Structure

```
development/$category/
├── README.md (ce fichier)
└── ...
```
"@
        Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
    }
}

# Fonction pour déplacer les fichiers d'un dossier source vers un dossier cible
function Move-DocumentationFiles {
    param (
        [string]$sourcePath,
        [string]$targetPath,
        [switch]$recurse
    )

    if (-not (Test-Path -Path $sourcePath)) {
        Write-Warning "Le chemin source n'existe pas: $sourcePath"
        return
    }

    if (-not (Test-Path -Path $targetPath)) {
        New-Item -Path $targetPath -ItemType Directory -Force
    }

    # Déplacer les fichiers
    $files = Get-ChildItem -Path $sourcePath -File
    foreach ($file in $files) {
        $targetFile = Join-Path -Path $targetPath -ChildPath $file.Name
        if (-not (Test-Path -Path $targetFile)) {
            Move-Item -Path $file.FullName -Destination $targetPath -Force
            Write-Host "Déplacé: $($file.FullName) -> $targetPath"
        }
        else {
            Write-Warning "Le fichier existe déjà dans la cible: $targetFile"
        }
    }

    # Déplacer les sous-dossiers si récursif
    if ($recurse) {
        $directories = Get-ChildItem -Path $sourcePath -Directory
        foreach ($dir in $directories) {
            $targetDir = Join-Path -Path $targetPath -ChildPath $dir.Name
            Move-DocumentationFiles -sourcePath $dir.FullName -targetPath $targetDir -recurse
        }
    }
}

# Mappings pour déplacer les fichiers
$mappings = @(
    # Projet
    @{
        Source = "$docsPath\architecture"
        Target = "$projetPath\architecture"
        Recurse = $true
    },
    @{
        Source = "$docsPath\tutorials"
        Target = "$projetPath\tutorials"
        Recurse = $true
    },
    @{
        Source = "$docsPath\guides"
        Target = "$projetPath\guides"
        Recurse = $true
    },
    @{
        Source = "$docsPath\development\roadmap"
        Target = "$projetPath\roadmaps"
        Recurse = $true
    },
    
    # Development
    @{
        Source = "$docsPath\api"
        Target = "$developmentPath\api"
        Recurse = $true
    },
    @{
        Source = "$docsPath\development\communications"
        Target = "$developmentPath\communications"
        Recurse = $true
    },
    @{
        Source = "$docsPath\development\n8n-internals"
        Target = "$developmentPath\n8n-internals"
        Recurse = $true
    },
    @{
        Source = "$docsPath\development\testing"
        Target = "$developmentPath\testing"
        Recurse = $true
    },
    @{
        Source = "$docsPath\development\tests"
        Target = "$developmentPath\testing\tests"
        Recurse = $true
    },
    @{
        Source = "$docsPath\development\workflows"
        Target = "$developmentPath\workflows"
        Recurse = $true
    },
    @{
        Source = "$docsPath\guides\methodologies"
        Target = "$developmentPath\methodologies"
        Recurse = $true
    }
)

# Exécuter les mappings
foreach ($mapping in $mappings) {
    Write-Host "Traitement du mapping: $($mapping.Source) -> $($mapping.Target)"
    Move-DocumentationFiles -sourcePath $mapping.Source -targetPath $mapping.Target -recurse:$mapping.Recurse
}

Write-Host "Réorganisation de la documentation terminée."
