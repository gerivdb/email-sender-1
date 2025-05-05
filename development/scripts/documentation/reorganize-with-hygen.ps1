# Script de rÃ©organisation de la documentation avec Hygen
# Ce script utilise Hygen pour rÃ©organiser la documentation

# VÃ©rifier si Hygen est installÃ©
$hygenInstalled = $null
try {
    $hygenInstalled = Get-Command hygen -ErrorAction SilentlyContinue
} catch {
    $hygenInstalled = $null
}

if ($null -eq $hygenInstalled) {
    Write-Host "Hygen n'est pas installÃ©. Installation en cours..."
    npm install -g hygen
}

# DÃ©finition des structures de dossiers
$projetStructure = @(
    @{ Category = "architecture"; Subcategories = @("decisions", "diagrams") },
    @{ Category = "documentation"; Subcategories = @("api", "technique", "workflow") },
    @{ Category = "guides"; Subcategories = @("installation", "utilisation", "integrations") },
    @{ Category = "roadmaps"; Subcategories = @("plans", "journal", "tasks") },
    @{ Category = "specifications"; Subcategories = @("fonctionnelles", "techniques") },
    @{ Category = "tutorials"; Subcategories = @("examples") }
)

$developmentStructure = @(
    @{ Category = "api"; Subcategories = @("examples", "documentation") },
    @{ Category = "communications"; Subcategories = @() },
    @{ Category = "n8n-internals"; Subcategories = @() },
    @{ Category = "roadmap"; Subcategories = @("analysis", "journal", "plans", "tasks") },
    @{ Category = "testing"; Subcategories = @("performance", "reports", "tests") },
    @{ Category = "workflows"; Subcategories = @() },
    @{ Category = "methodologies"; Subcategories = @("modes") },
    @{ Category = "tools"; Subcategories = @("scripts", "utilities") }
)

# CrÃ©ation de la structure pour le dossier projet
Write-Host "CrÃ©ation de la structure pour le dossier 'projet'..."
foreach ($category in $projetStructure) {
    Write-Host "  CrÃ©ation de la catÃ©gorie: $($category.Category)"
    hygen doc-structure new --docType "projet" --category $category.Category --subcategory ""
    
    foreach ($subcategory in $category.Subcategories) {
        Write-Host "    CrÃ©ation de la sous-catÃ©gorie: $subcategory"
        hygen doc-structure new --docType "projet" --category $category.Category --subcategory $subcategory
    }
}

# CrÃ©ation de la structure pour le dossier development
Write-Host "CrÃ©ation de la structure pour le dossier 'development'..."
foreach ($category in $developmentStructure) {
    Write-Host "  CrÃ©ation de la catÃ©gorie: $($category.Category)"
    hygen doc-structure new --docType "development" --category $category.Category --subcategory ""
    
    foreach ($subcategory in $category.Subcategories) {
        Write-Host "    CrÃ©ation de la sous-catÃ©gorie: $subcategory"
        hygen doc-structure new --docType "development" --category $category.Category --subcategory $subcategory
    }
}

# Mappings pour la migration des fichiers
$mappings = @(
    # Projet
    @{ Source = "docs\architecture"; Target = "projet\architecture"; Recursive = $true },
    @{ Source = "docs\tutorials"; Target = "projet\tutorials"; Recursive = $true },
    @{ Source = "docs\guides"; Target = "projet\guides"; Recursive = $true },
    @{ Source = "docs\development\roadmap"; Target = "projet\roadmaps"; Recursive = $true },
    
    # Development
    @{ Source = "docs\api"; Target = "development\api"; Recursive = $true },
    @{ Source = "docs\development\communications"; Target = "development\communications"; Recursive = $true },
    @{ Source = "docs\development\n8n-internals"; Target = "development\n8n-internals"; Recursive = $true },
    @{ Source = "docs\development\testing"; Target = "development\testing"; Recursive = $true },
    @{ Source = "docs\development\tests"; Target = "development\testing\tests"; Recursive = $true },
    @{ Source = "docs\development\workflows"; Target = "development\workflows"; Recursive = $true },
    @{ Source = "docs\guides\methodologies"; Target = "development\methodologies"; Recursive = $true }
)

# Migration des fichiers
Write-Host "Migration des fichiers..."
foreach ($mapping in $mappings) {
    if (Test-Path -Path $mapping.Source) {
        Write-Host "  Migration de $($mapping.Source) vers $($mapping.Target)"
        hygen doc-structure migrate --sourcePath $mapping.Source --targetPath $mapping.Target --recursive $mapping.Recursive
    } else {
        Write-Host "  Le chemin source n'existe pas: $($mapping.Source)" -ForegroundColor Yellow
    }
}

Write-Host "RÃ©organisation de la documentation terminÃ©e." -ForegroundColor Green
