#Requires -Version 5.1
<#
.SYNOPSIS
    Met Ã  jour la roadmap avec les implÃ©mentations de compatibilitÃ© PowerShell.

.DESCRIPTION
    Ce script met Ã  jour la roadmap avec les implÃ©mentations de compatibilitÃ© PowerShell
    et les tests de compatibilitÃ© croisÃ©e.

.PARAMETER RoadmapPath
    Le chemin vers le fichier de roadmap Ã  mettre Ã  jour.
    Par dÃ©faut, utilise 'Roadmap/roadmap_complete.md'.

.EXAMPLE
    .\Update-Roadmap-PowerShellCompatibility.ps1 -RoadmapPath "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/Roadmap/roadmap_complete.md"

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

[CmdletBinding()]
param(
  [Parameter()]
  [string]$RoadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete.md"
)

# VÃ©rifier si le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier roadmap n'existe pas: $RoadmapPath"
    exit 1
}

# Lire le contenu de la roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# 1. Section pour la migration vers PowerShell 7
$migrationPS7Pattern = "##### C\.2\.1 Migration vers PowerShell 7\n- \[ \] Migrer vers PowerShell 7 pour une meilleure prise en charge des classes\n  - \[ \] CrÃ©er un script de dÃ©tection de version.*?\n    - \[ \] DÃ©tecter automatiquement.*?\n    - \[ \] VÃ©rifier la disponibilitÃ©.*?\n    - \[ \] Tester la compatibilitÃ©.*?\n    - \[ \] GÃ©nÃ©rer un rapport.*?\n  - \[ \] DÃ©velopper des chemins de code alternatifs.*?\n    - \[ \] ImplÃ©menter un systÃ¨me.*?\n    - \[ \] CrÃ©er des wrappers.*?\n    - \[ \] Utiliser des techniques.*?\n    - \[ \] DÃ©velopper un mÃ©canisme.*?\n  - \[ \] Documenter les diffÃ©rences.*?\n    - \[ \] CrÃ©er un guide.*?\n    - \[ \] Documenter les diffÃ©rences.*?\n    - \[ \] Fournir des exemples.*?\n    - \[ \] CrÃ©er une matrice.*?\n  - \[ \] ImplÃ©menter des tests.*?\n    - \[ \] DÃ©velopper.*?\n    - \[ \] CrÃ©er des tests.*?\n    - \[ \] Automatiser les tests.*?\n    - \[ \] GÃ©nÃ©rer des rapports.*?"

$migrationPS7Replacement = @"
##### C.2.1 Migration vers PowerShell 7
- [x] Migrer vers PowerShell 7 pour une meilleure prise en charge des classes
  - [x] CrÃ©er un script de dÃ©tection de version `Test-PowerShellCompatibility.ps1`
    - [x] DÃ©tecter automatiquement la version de PowerShell en cours d'exÃ©cution
    - [x] VÃ©rifier la disponibilitÃ© de PowerShell 7 sur le systÃ¨me
    - [x] Tester la compatibilitÃ© des modules requis avec PowerShell 7
    - [x] GÃ©nÃ©rer un rapport de compatibilitÃ© dÃ©taillÃ©
  - [x] DÃ©velopper des chemins de code alternatifs pour PowerShell 5.1 et 7
    - [x] ImplÃ©menter un systÃ¨me de sÃ©lection de code basÃ© sur la version
    - [x] CrÃ©er des wrappers de fonctions compatibles avec les deux versions
    - [x] Utiliser des techniques de rÃ©flexion pour gÃ©rer les diffÃ©rences d'API
    - [x] DÃ©velopper un mÃ©canisme de fallback automatique
  - [x] Documenter les diffÃ©rences de comportement entre les versions
    - [x] CrÃ©er un guide de migration dÃ©taillÃ© `PowerShell7-MigrationGuide.md`
    - [x] Documenter les diffÃ©rences de syntaxe et de comportement
    - [x] Fournir des exemples de code pour les deux versions
    - [x] CrÃ©er une matrice de compatibilitÃ© des fonctionnalitÃ©s
  - [x] ImplÃ©menter des tests de compatibilitÃ© croisÃ©e
    - [x] DÃ©velopper `Invoke-CrossVersionTests.ps1` pour tester sur PS 5.1 et 7
    - [x] CrÃ©er des tests spÃ©cifiques pour les fonctionnalitÃ©s divergentes
    - [x] Automatiser les tests dans des conteneurs Docker multi-versions
    - [x] GÃ©nÃ©rer des rapports de compatibilitÃ© croisÃ©e
"@

# 2. Section pour la restructuration du code pour la compatibilitÃ©
$restructurationPattern = "##### C\.2\.2 Restructuration du code pour la compatibilitÃ©\n- \[ \] Restructurer le code pour amÃ©liorer la compatibilitÃ©\n  - \[ \] Remplacer les classes complexes.*?\n    - \[ \] Refactoriser.*?\n    - \[ \] Remplacer l'hÃ©ritage.*?\n    - \[ \] Convertir les mÃ©thodes.*?\n    - \[ \] ImplÃ©menter un systÃ¨me.*?\n  - \[ \] CrÃ©er un module.*?\n    - \[ \] DÃ©velopper une version.*?\n    - \[ \] Utiliser des hashtables.*?\n    - \[ \] ImplÃ©menter des fonctions.*?\n    - \[ \] Assurer la compatibilitÃ©.*?\n  - \[ \] DÃ©velopper des tests.*?\n    - \[ \] CrÃ©er.*?\n    - \[ \] Mesurer les diffÃ©rences.*?\n    - \[ \] Tester avec diffÃ©rentes.*?\n    - \[ \] GÃ©nÃ©rer des graphiques.*?\n  - \[ \] Documenter les meilleures.*?\n    - \[ \] CrÃ©er un guide.*?\n    - \[ \] Documenter les patterns.*?\n    - \[ \] Fournir des exemples.*?\n    - \[ \] CrÃ©er une liste.*?"

$restructurationReplacement = @"
##### C.2.2 Restructuration du code pour la compatibilitÃ©
- [x] Restructurer le code pour amÃ©liorer la compatibilitÃ©
  - [x] Remplacer les classes complexes par des objets personnalisÃ©s et des fonctions
    - [x] Refactoriser `FileContentIndexer` en utilisant des factory functions
    - [x] Remplacer l'hÃ©ritage de classe par la composition d'objets
    - [x] Convertir les mÃ©thodes de classe en fonctions autonomes
    - [x] ImplÃ©menter un systÃ¨me de validation des propriÃ©tÃ©s sans classes
  - [x] CrÃ©er un module `SimpleFileContentIndexer.psm1` compatible avec PowerShell 5.1
    - [x] DÃ©velopper une version simplifiÃ©e avec les mÃªmes fonctionnalitÃ©s
    - [x] Utiliser des hashtables et des objets PSCustomObject au lieu de classes
    - [x] ImplÃ©menter des fonctions d'aide pour la manipulation d'objets
    - [x] Assurer la compatibilitÃ© avec les pipelines PowerShell
  - [x] DÃ©velopper des tests de performance comparatifs entre les implÃ©mentations
    - [x] CrÃ©er `Compare-ImplementationPerformance.ps1` pour benchmarking
    - [x] Mesurer les diffÃ©rences de performance entre les approches
    - [x] Tester avec diffÃ©rentes tailles de fichiers et charges de travail
    - [x] GÃ©nÃ©rer des graphiques comparatifs de performance
  - [x] Documenter les meilleures pratiques pour la compatibilitÃ© PowerShell
    - [x] CrÃ©er un guide `PowerShell-CompatibilityBestPractices.md`
    - [x] Documenter les patterns de conception compatibles
    - [x] Fournir des exemples de code pour les cas courants
    - [x] CrÃ©er une liste de vÃ©rification de compatibilitÃ©
"@

# Mettre Ã  jour le contenu de la roadmap
$updatedContent = $roadmapContent

# Remplacer les sections
$updatedContent = [regex]::Replace($updatedContent, $migrationPS7Pattern, $migrationPS7Replacement, [System.Text.RegularExpressions.RegexOptions]::Singleline)
$updatedContent = [regex]::Replace($updatedContent, $restructurationPattern, $restructurationReplacement, [System.Text.RegularExpressions.RegexOptions]::Singleline)

# Enregistrer le contenu mis Ã  jour
$updatedContent | Out-File -FilePath $RoadmapPath -Encoding utf8

Write-Host "Roadmap mise Ã  jour : $RoadmapPath" -ForegroundColor Green
Write-Host "Les sections suivantes ont Ã©tÃ© mises Ã  jour :" -ForegroundColor Green
Write-Host "- Migration vers PowerShell 7" -ForegroundColor Green
Write-Host "- Restructuration du code pour la compatibilitÃ©" -ForegroundColor Green
