# Simple-Dependency-Test.ps1
# Script de test simplifié pour l'extraction des dépendances
# Version: 1.0
# Date: 2025-05-15

# Contenu de test
$testContent = @'
# Test de dépendances

## Section 1

- [ ] **1.1** Tâche 1.1
- [ ] **1.2** Tâche 1.2 #blockedBy:1.1
- [ ] **1.3** Tâche 1.3 dépend de: 1.1, 1.2
- [ ] **1.4** Tâche 1.4 requis pour: 1.5, 1.6
- [ ] **1.5** Tâche 1.5 #dependsOn:1.4
- [ ] **1.6** Tâche 1.6 #required_for:2.1
- [ ] **1.7** Tâche 1.7 #customTag:1.1,1.2 #priority:high

## Section 2

- [ ] **2.1** Tâche 2.1 référence à 1.1 et 1.3
- [ ] **2.2** Tâche 2.2 bloqué par: 2.1
- [ ] **2.3** Tâche 2.3 #depends_on:2.2 #blocked_by:1.7
- [ ] **2.4** Tâche 2.4 #relatedTo:2.3,2.5 #milestone:true
- [ ] **2.5** Tâche 2.5
'@

# Charger le script d'extraction des dépendances
$scriptPath = $PSScriptRoot
$dependencyScriptPath = Join-Path -Path $scriptPath -ChildPath "Extract-DependencyAttributes.ps1"

if (-not (Test-Path -Path $dependencyScriptPath)) {
    Write-Error "Le script d'extraction des dépendances n'existe pas: $dependencyScriptPath"
    exit 1
}

# Charger le script dans la portée actuelle
. $dependencyScriptPath

# Afficher le contenu de test
Write-Host "=== TEST D'EXTRACTION DES DÉPENDANCES ===" -ForegroundColor Magenta
Write-Host "`nContenu de test:" -ForegroundColor Cyan
Write-Host "Longueur: $($testContent.Length) caractères" -ForegroundColor Cyan
Write-Host "Début du contenu:" -ForegroundColor Cyan
Write-Host ($testContent.Substring(0, [Math]::Min(100, $testContent.Length)))

# Exécuter la fonction d'extraction des dépendances
Write-Host "`nExécution de la fonction d'extraction des dépendances..." -ForegroundColor Cyan
$result = Get-DependencyAttributes -Content $testContent -OutputFormat "Markdown"

# Afficher les résultats
Write-Host "`nRésultats:" -ForegroundColor Green
Write-Host $result

Write-Host "`n=== TEST TERMINÉ ===" -ForegroundColor Magenta
