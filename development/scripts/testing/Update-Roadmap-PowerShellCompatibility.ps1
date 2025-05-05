#Requires -Version 5.1
<#
.SYNOPSIS
    Met ÃƒÂ  jour la roadmap avec les implÃƒÂ©mentations de compatibilitÃƒÂ© PowerShell.

.DESCRIPTION
    Ce script met ÃƒÂ  jour la roadmap avec les implÃƒÂ©mentations de compatibilitÃƒÂ© PowerShell
    et les tests de compatibilitÃƒÂ© croisÃƒÂ©e.

.PARAMETER RoadmapPath
    Le chemin vers le fichier de roadmap ÃƒÂ  mettre ÃƒÂ  jour.
    Par dÃƒÂ©faut, utilise 'Roadmap/roadmap_complete.md'.

.EXAMPLE
    .\Update-Roadmap-PowerShellCompatibility.ps1 -RoadmapPath "D:/DO/WEB/N8N_development/testing/tests/PROJETS/EMAIL_SENDER_1/Roadmap/roadmap_complete.md"

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

# VÃƒÂ©rifier si le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier roadmap n'existe pas: $RoadmapPath"
    exit 1
}

# Lire le contenu de la roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# 1. Section pour la migration vers PowerShell 7
$migrationPS7Pattern = "##### C\.2\.1 Migration vers PowerShell 7\n- \[ \] Migrer vers PowerShell 7 pour une meilleure prise en charge des classes\n  - \[ \] CrÃƒÂ©er un script de dÃƒÂ©tection de version.*?\n    - \[ \] DÃƒÂ©tecter automatiquement.*?\n    - \[ \] VÃƒÂ©rifier la disponibilitÃƒÂ©.*?\n    - \[ \] Tester la compatibilitÃƒÂ©.*?\n    - \[ \] GÃƒÂ©nÃƒÂ©rer un rapport.*?\n  - \[ \] DÃƒÂ©velopper des chemins de code alternatifs.*?\n    - \[ \] ImplÃƒÂ©menter un systÃƒÂ¨me.*?\n    - \[ \] CrÃƒÂ©er des wrappers.*?\n    - \[ \] Utiliser des techniques.*?\n    - \[ \] DÃƒÂ©velopper un mÃƒÂ©canisme.*?\n  - \[ \] Documenter les diffÃƒÂ©rences.*?\n    - \[ \] CrÃƒÂ©er un guide.*?\n    - \[ \] Documenter les diffÃƒÂ©rences.*?\n    - \[ \] Fournir des exemples.*?\n    - \[ \] CrÃƒÂ©er une matrice.*?\n  - \[ \] ImplÃƒÂ©menter des tests.*?\n    - \[ \] DÃƒÂ©velopper.*?\n    - \[ \] CrÃƒÂ©er des tests.*?\n    - \[ \] Automatiser les tests.*?\n    - \[ \] GÃƒÂ©nÃƒÂ©rer des rapports.*?"

$migrationPS7Replacement = @"
##### C.2.1 Migration vers PowerShell 7
- [x] Migrer vers PowerShell 7 pour une meilleure prise en charge des classes
  - [x] CrÃƒÂ©er un script de dÃƒÂ©tection de version `Test-PowerShellCompatibility.ps1`
    - [x] DÃƒÂ©tecter automatiquement la version de PowerShell en cours d'exÃƒÂ©cution
    - [x] VÃƒÂ©rifier la disponibilitÃƒÂ© de PowerShell 7 sur le systÃƒÂ¨me
    - [x] Tester la compatibilitÃƒÂ© des modules requis avec PowerShell 7
    - [x] GÃƒÂ©nÃƒÂ©rer un rapport de compatibilitÃƒÂ© dÃƒÂ©taillÃƒÂ©
  - [x] DÃƒÂ©velopper des chemins de code alternatifs pour PowerShell 5.1 et 7
    - [x] ImplÃƒÂ©menter un systÃƒÂ¨me de sÃƒÂ©lection de code basÃƒÂ© sur la version
    - [x] CrÃƒÂ©er des wrappers de fonctions compatibles avec les deux versions
    - [x] Utiliser des techniques de rÃƒÂ©flexion pour gÃƒÂ©rer les diffÃƒÂ©rences d'API
    - [x] DÃƒÂ©velopper un mÃƒÂ©canisme de fallback automatique
  - [x] Documenter les diffÃƒÂ©rences de comportement entre les versions
    - [x] CrÃƒÂ©er un guide de migration dÃƒÂ©taillÃƒÂ© `PowerShell7-MigrationGuide.md`
    - [x] Documenter les diffÃƒÂ©rences de syntaxe et de comportement
    - [x] Fournir des exemples de code pour les deux versions
    - [x] CrÃƒÂ©er une matrice de compatibilitÃƒÂ© des fonctionnalitÃƒÂ©s
  - [x] ImplÃƒÂ©menter des tests de compatibilitÃƒÂ© croisÃƒÂ©e
    - [x] DÃƒÂ©velopper `Invoke-CrossVersionTests.ps1` pour tester sur PS 5.1 et 7
    - [x] CrÃƒÂ©er des tests spÃƒÂ©cifiques pour les fonctionnalitÃƒÂ©s divergentes
    - [x] Automatiser les tests dans des conteneurs Docker multi-versions
    - [x] GÃƒÂ©nÃƒÂ©rer des rapports de compatibilitÃƒÂ© croisÃƒÂ©e
"@

# 2. Section pour la restructuration du code pour la compatibilitÃƒÂ©
$restructurationPattern = "##### C\.2\.2 Restructuration du code pour la compatibilitÃƒÂ©\n- \[ \] Restructurer le code pour amÃƒÂ©liorer la compatibilitÃƒÂ©\n  - \[ \] Remplacer les classes complexes.*?\n    - \[ \] Refactoriser.*?\n    - \[ \] Remplacer l'hÃƒÂ©ritage.*?\n    - \[ \] Convertir les mÃƒÂ©thodes.*?\n    - \[ \] ImplÃƒÂ©menter un systÃƒÂ¨me.*?\n  - \[ \] CrÃƒÂ©er un module.*?\n    - \[ \] DÃƒÂ©velopper une version.*?\n    - \[ \] Utiliser des hashtables.*?\n    - \[ \] ImplÃƒÂ©menter des fonctions.*?\n    - \[ \] Assurer la compatibilitÃƒÂ©.*?\n  - \[ \] DÃƒÂ©velopper des tests.*?\n    - \[ \] CrÃƒÂ©er.*?\n    - \[ \] Mesurer les diffÃƒÂ©rences.*?\n    - \[ \] Tester avec diffÃƒÂ©rentes.*?\n    - \[ \] GÃƒÂ©nÃƒÂ©rer des graphiques.*?\n  - \[ \] Documenter les meilleures.*?\n    - \[ \] CrÃƒÂ©er un guide.*?\n    - \[ \] Documenter les patterns.*?\n    - \[ \] Fournir des exemples.*?\n    - \[ \] CrÃƒÂ©er une liste.*?"

$restructurationReplacement = @"
##### C.2.2 Restructuration du code pour la compatibilitÃƒÂ©
- [x] Restructurer le code pour amÃƒÂ©liorer la compatibilitÃƒÂ©
  - [x] Remplacer les classes complexes par des objets personnalisÃƒÂ©s et des fonctions
    - [x] Refactoriser `FileContentIndexer` en utilisant des factory functions
    - [x] Remplacer l'hÃƒÂ©ritage de classe par la composition d'objets
    - [x] Convertir les mÃƒÂ©thodes de classe en fonctions autonomes
    - [x] ImplÃƒÂ©menter un systÃƒÂ¨me de validation des propriÃƒÂ©tÃƒÂ©s sans classes
  - [x] CrÃƒÂ©er un module `SimpleFileContentIndexer.psm1` compatible avec PowerShell 5.1
    - [x] DÃƒÂ©velopper une version simplifiÃƒÂ©e avec les mÃƒÂªmes fonctionnalitÃƒÂ©s
    - [x] Utiliser des hashtables et des objets PSCustomObject au lieu de classes
    - [x] ImplÃƒÂ©menter des fonctions d'aide pour la manipulation d'objets
    - [x] Assurer la compatibilitÃƒÂ© avec les pipelines PowerShell
  - [x] DÃƒÂ©velopper des tests de performance comparatifs entre les implÃƒÂ©mentations
    - [x] CrÃƒÂ©er `Compare-ImplementationPerformance.ps1` pour benchmarking
    - [x] Mesurer les diffÃƒÂ©rences de performance entre les approches
    - [x] Tester avec diffÃƒÂ©rentes tailles de fichiers et charges de travail
    - [x] GÃƒÂ©nÃƒÂ©rer des graphiques comparatifs de performance
  - [x] Documenter les meilleures pratiques pour la compatibilitÃƒÂ© PowerShell
    - [x] CrÃƒÂ©er un guide `PowerShell-CompatibilityBestPractices.md`
    - [x] Documenter les patterns de conception compatibles
    - [x] Fournir des exemples de code pour les cas courants
    - [x] CrÃƒÂ©er une liste de vÃƒÂ©rification de compatibilitÃƒÂ©
"@

# Mettre ÃƒÂ  jour le contenu de la roadmap
$updatedContent = $roadmapContent

# Remplacer les sections
$updatedContent = [regex]::Replace($updatedContent, $migrationPS7Pattern, $migrationPS7Replacement, [System.Text.RegularExpressions.RegexOptions]::Singleline)
$updatedContent = [regex]::Replace($updatedContent, $restructurationPattern, $restructurationReplacement, [System.Text.RegularExpressions.RegexOptions]::Singleline)

# Enregistrer le contenu mis ÃƒÂ  jour
$updatedContent | Out-File -FilePath $RoadmapPath -Encoding utf8

Write-Host "Roadmap mise ÃƒÂ  jour : $RoadmapPath" -ForegroundColor Green
Write-Host "Les sections suivantes ont ÃƒÂ©tÃƒÂ© mises ÃƒÂ  jour :" -ForegroundColor Green
Write-Host "- Migration vers PowerShell 7" -ForegroundColor Green
Write-Host "- Restructuration du code pour la compatibilitÃƒÂ©" -ForegroundColor Green
