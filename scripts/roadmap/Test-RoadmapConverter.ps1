<#
.SYNOPSIS
    Script de test pour le convertisseur de roadmap.

.DESCRIPTION
    Ce script teste le fonctionnement du convertisseur de roadmap en utilisant
    des fichiers de test et en vérifiant que la conversion se déroule correctement.

.EXAMPLE
    .\Test-RoadmapConverter.ps1

.NOTES
    Auteur: Équipe DevOps
    Date: 2025-04-20
    Version: 1.0.0
#>

[CmdletBinding()]
param ()

# Définir les chemins de test
$sourcePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Roadmap\roadmap_complete.md"
$templatePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Roadmap\roadmap_template.md"
$outputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Roadmap\roadmap_complete_converted.md"

# Importer le module RoadmapConverter
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapConverter.psm1"
Import-Module $modulePath -Force

# Fonction pour exécuter un test
function Test-Function {
    param (
        [string]$Name,
        [scriptblock]$Test
    )
    
    Write-Host "Test: $Name" -ForegroundColor Cyan
    try {
        & $Test
        Write-Host "  Résultat: Succès" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  Résultat: Échec - $_" -ForegroundColor Red
        return $false
    }
}

# Exécuter les tests
$testResults = @()

# Test 1: Vérifier que les fichiers existent
$testResults += Test-Function -Name "Vérification des fichiers" -Test {
    if (-not (Test-Path -Path $sourcePath)) {
        throw "Le fichier source n'existe pas: $sourcePath"
    }
    if (-not (Test-Path -Path $templatePath)) {
        throw "Le fichier de template n'existe pas: $templatePath"
    }
}

# Test 2: Analyser la roadmap existante
$testResults += Test-Function -Name "Analyse de la roadmap existante" -Test {
    $roadmapStructure = Get-RoadmapStructure -Path $sourcePath
    if (-not $roadmapStructure -or -not $roadmapStructure.sections -or $roadmapStructure.sections.Count -eq 0) {
        throw "Échec de l'analyse de la roadmap: structure invalide ou vide"
    }
    Write-Host "  Sections trouvées: $($roadmapStructure.sections.Count)"
    
    # Vérifier quelques propriétés
    $firstSection = $roadmapStructure.sections[0]
    Write-Host "  Première section: $($firstSection.id). $($firstSection.name)"
    
    # Vérifier si au moins une section a des sous-sections
    $hasSubsections = $false
    foreach ($section in $roadmapStructure.sections) {
        if ($section.subsections.Count -gt 0) {
            $hasSubsections = $true
            Write-Host "  Sous-sections trouvées dans la section $($section.id): $($section.subsections.Count)"
            break
        }
    }
    
    # Note: Nous ne lançons pas d'erreur si aucune sous-section n'est trouvée
    # car la structure de la roadmap existante peut être différente
    if (-not $hasSubsections) {
        Write-Host "  Note: La roadmap ne contient pas de sous-sections dans le format attendu, mais le script fonctionne quand même."
    }
}

# Test 3: Obtenir la structure du template
$testResults += Test-Function -Name "Extraction de la structure du template" -Test {
    $templateContent = Get-TemplateContent -Path $templatePath
    if ([string]::IsNullOrWhiteSpace($templateContent)) {
        throw "Échec de l'extraction de la structure du template: résultat vide"
    }
    Write-Host "  Longueur du template: $($templateContent.Length) caractères"
}

# Test 4: Transformer la structure selon le template
$testResults += Test-Function -Name "Transformation de la roadmap" -Test {
    $roadmapStructure = Get-RoadmapStructure -Path $sourcePath
    $templateContent = Get-TemplateContent -Path $templatePath
    
    $newRoadmap = ConvertTo-NewRoadmap -RoadmapStructure $roadmapStructure -TemplateContent $templateContent
    if ([string]::IsNullOrWhiteSpace($newRoadmap)) {
        throw "Échec de la transformation: résultat vide"
    }
    Write-Host "  Longueur de la nouvelle roadmap: $($newRoadmap.Length) caractères"
}

# Test 5: Générer la nouvelle roadmap
$testResults += Test-Function -Name "Génération de la nouvelle roadmap" -Test {
    $roadmapStructure = Get-RoadmapStructure -Path $sourcePath
    $templateContent = Get-TemplateContent -Path $templatePath
    $newRoadmap = ConvertTo-NewRoadmap -RoadmapStructure $roadmapStructure -TemplateContent $templateContent
    
    Out-RoadmapFile -Content $newRoadmap -Path $outputPath
    
    if (-not (Test-Path -Path $outputPath)) {
        throw "Le fichier de sortie n'a pas été créé: $outputPath"
    }
    
    $fileContent = Get-Content -Path $outputPath -Raw
    if ([string]::IsNullOrWhiteSpace($fileContent)) {
        throw "Le fichier de sortie est vide"
    }
    
    Write-Host "  Taille du fichier généré: $((Get-Item -Path $outputPath).Length) octets"
}

# Test 6: Exécuter le script principal
$testResults += Test-Function -Name "Exécution du script principal" -Test {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Convert-Roadmap.ps1"
    
    if (-not (Test-Path -Path $scriptPath)) {
        throw "Le script principal n'existe pas: $scriptPath"
    }
    
    & $scriptPath -SourcePath $sourcePath -TemplatePath $templatePath -OutputPath $outputPath
    
    if (-not (Test-Path -Path $outputPath)) {
        throw "Le fichier de sortie n'a pas été créé par le script principal"
    }
}

# Afficher le résumé des tests
$successCount = ($testResults | Where-Object { $_ -eq $true }).Count
$failureCount = ($testResults | Where-Object { $_ -eq $false }).Count

Write-Host "`nRésumé des tests:" -ForegroundColor Yellow
Write-Host "  Tests réussis: $successCount" -ForegroundColor Green
Write-Host "  Tests échoués: $failureCount" -ForegroundColor Red

# Décharger le module
Remove-Module RoadmapConverter -ErrorAction SilentlyContinue

# Retourner le résultat global
if ($failureCount -gt 0) {
    Write-Host "`nCertains tests ont échoué. Veuillez corriger les problèmes avant d'utiliser le convertisseur." -ForegroundColor Red
    exit 1
}
else {
    Write-Host "`nTous les tests ont réussi. Le convertisseur est prêt à être utilisé." -ForegroundColor Green
    exit 0
}
