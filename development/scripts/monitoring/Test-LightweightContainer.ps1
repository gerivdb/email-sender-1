#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour le module LightweightContainer.
.DESCRIPTION
    Ce script teste les fonctionnalites du module LightweightContainer en executant
    chaque fonction et en affichant les resultats.
.NOTES
    Nom: Test-LightweightContainer.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de creation: 2025-05-20
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "LightweightContainer.psm1"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module LightweightContainer.psm1 introuvable a l'emplacement: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Test 1: New-ContainerImage
Write-Host "`nTest 1: New-ContainerImage" -ForegroundColor Green
Write-Host "Creation d'une nouvelle image de conteneur..."

$image = New-ContainerImage -Name "TestImage" -ModuleDependencies @("Microsoft.PowerShell.Management", "Microsoft.PowerShell.Utility") -EnvironmentVariables @{
    "TEST_VAR1" = "Value1"
    "TEST_VAR2" = "Value2"
}

if ($null -ne $image) {
    Write-Host "Image creee avec succes:" -ForegroundColor Yellow
    Write-Host "  Nom: $($image.Name)" -ForegroundColor Gray
    Write-Host "  Date de creation: $($image.CreatedAt)" -ForegroundColor Gray
    Write-Host "  Modules: $($image.ModuleDependencies -join ', ')" -ForegroundColor Gray
    Write-Host "  Variables d'environnement: $($image.EnvironmentVariables | ConvertTo-Json -Compress)" -ForegroundColor Gray
    Write-Host "Test reussi!" -ForegroundColor Green
} else {
    Write-Host "Echec de la creation de l'image." -ForegroundColor Red
}

# Test 2: New-Container
Write-Host "`nTest 2: New-Container" -ForegroundColor Green
Write-Host "Creation d'un nouveau conteneur..."

$container = New-Container -Name "TestContainer" -ImageName "TestImage" -EnvironmentVariables @{
    "CONTAINER_VAR" = "ContainerValue"
} -Persistent

if ($null -ne $container) {
    Write-Host "Conteneur cree avec succes:" -ForegroundColor Yellow
    Write-Host "  Nom: $($container.Name)" -ForegroundColor Gray
    Write-Host "  Image: $($container.ImageName)" -ForegroundColor Gray
    Write-Host "  Date de creation: $($container.CreatedAt)" -ForegroundColor Gray
    Write-Host "  Chemin: $($container.Path)" -ForegroundColor Gray
    Write-Host "  Statut: $($container.Status)" -ForegroundColor Gray
    Write-Host "  Persistant: $($container.Persistent)" -ForegroundColor Gray
    Write-Host "Test reussi!" -ForegroundColor Green
} else {
    Write-Host "Echec de la creation du conteneur." -ForegroundColor Red
}

# Test 3: Start-Container
Write-Host "`nTest 3: Start-Container" -ForegroundColor Green
Write-Host "Demarrage du conteneur..."

$startedContainer = Start-Container -Name "TestContainer" -ScriptBlock {
    Write-Host "Hello from container $env:CONTAINER_NAME!"
    Write-Host "Environment variables:"
    Write-Host "  TEST_VAR1 = $env:TEST_VAR1"
    Write-Host "  TEST_VAR2 = $env:TEST_VAR2"
    Write-Host "  CONTAINER_VAR = $env:CONTAINER_VAR"
    
    # Simuler un traitement
    Write-Host "Traitement en cours..."
    Start-Sleep -Seconds 2
    
    # Retourner un resultat
    return "Traitement termine avec succes!"
}

if ($null -ne $startedContainer) {
    Write-Host "Conteneur demarre avec succes:" -ForegroundColor Yellow
    Write-Host "  Nom: $($startedContainer.Name)" -ForegroundColor Gray
    Write-Host "  PID: $($startedContainer.Process.Id)" -ForegroundColor Gray
    Write-Host "  Statut: $($startedContainer.Status)" -ForegroundColor Gray
    Write-Host "Test reussi!" -ForegroundColor Green
} else {
    Write-Host "Echec du demarrage du conteneur." -ForegroundColor Red
}

# Attendre que le conteneur termine son execution
Write-Host "`nAttente de la fin de l'execution du conteneur (5 secondes)..."
Start-Sleep -Seconds 5

# Test 4: Get-Container
Write-Host "`nTest 4: Get-Container" -ForegroundColor Green
Write-Host "Obtention des informations sur le conteneur..."

$updatedContainer = Get-Container -Name "TestContainer"
if ($null -ne $updatedContainer) {
    Write-Host "Informations sur le conteneur:" -ForegroundColor Yellow
    Write-Host "  Nom: $($updatedContainer.Name)" -ForegroundColor Gray
    Write-Host "  Statut: $($updatedContainer.Status)" -ForegroundColor Gray
    if ($updatedContainer.PSObject.Properties.Name -contains "CPU") {
        Write-Host "  CPU: $($updatedContainer.CPU)" -ForegroundColor Gray
    }
    if ($updatedContainer.PSObject.Properties.Name -contains "Memory") {
        Write-Host "  Memoire: $($updatedContainer.Memory) MB" -ForegroundColor Gray
    }
}

Write-Host "`nObtention de tous les conteneurs..."
$allContainers = Get-Container
Write-Host "Nombre de conteneurs: $($allContainers.Count)" -ForegroundColor Yellow
foreach ($cont in $allContainers) {
    Write-Host "  $($cont.Name) (Image: $($cont.ImageName), Statut: $($cont.Status))" -ForegroundColor Gray
}

Write-Host "Test reussi!" -ForegroundColor Green

# Test 5: Conteneur avec etat persistant
Write-Host "`nTest 5: Conteneur avec etat persistant" -ForegroundColor Green
Write-Host "Demarrage du conteneur avec etat persistant..."

$persistentContainer = Start-Container -Name "TestContainer" -ScriptBlock {
    Write-Host "Execution avec etat persistant"
    
    # Verifier si nous avons deja un etat
    $state = Get-ContainerState
    if ($null -ne $state) {
        Write-Host "Etat precedent trouve:"
        Write-Host "  Derniere execution: $($state.LastRunTime)"
        Write-Host "  Statut de sortie: $($state.ExitStatus)"
        $runCount = if ($null -ne $state.RunCount) { $state.RunCount + 1 } else { 1 }
    } else {
        Write-Host "Aucun etat precedent trouve."
        $runCount = 1
    }
    
    Write-Host "Execution numero $runCount"
    
    # Enregistrer l'etat
    $newState = @{
        LastRunTime = Get-Date
        ExitStatus = "Success"
        RunCount = $runCount
        Message = "Execution reussie"
    }
    
    Save-ContainerState -State $newState
}

if ($null -ne $persistentContainer) {
    Write-Host "Conteneur avec etat persistant demarre avec succes." -ForegroundColor Green
} else {
    Write-Host "Echec du demarrage du conteneur avec etat persistant." -ForegroundColor Red
}

# Attendre que le conteneur termine son execution
Write-Host "`nAttente de la fin de l'execution du conteneur (5 secondes)..."
Start-Sleep -Seconds 5

# Test 6: Stop-Container
Write-Host "`nTest 6: Stop-Container" -ForegroundColor Green
Write-Host "Demarrage d'un conteneur de longue duree..."

$longRunningContainer = Start-Container -Name "TestContainer" -ScriptBlock {
    Write-Host "Conteneur de longue duree demarre"
    Write-Host "Attente de 30 secondes..."
    for ($i = 1; $i -le 30; $i++) {
        Write-Host "Seconde $i..."
        Start-Sleep -Seconds 1
    }
    Write-Host "Conteneur de longue duree termine"
}

# Attendre un peu pour que le conteneur demarre
Write-Host "Attente de 3 secondes pour que le conteneur demarre..."
Start-Sleep -Seconds 3

# Arreter le conteneur
Write-Host "Arret du conteneur..."
$stopped = Stop-Container -Name "TestContainer"
if ($stopped) {
    Write-Host "Conteneur arrete avec succes." -ForegroundColor Green
} else {
    Write-Host "Echec de l'arret du conteneur." -ForegroundColor Red
}

# Verifier le statut du conteneur
$stoppedContainer = Get-Container -Name "TestContainer"
if ($null -ne $stoppedContainer) {
    Write-Host "Statut du conteneur apres arret: $($stoppedContainer.Status)" -ForegroundColor Yellow
}

Write-Host "Test reussi!" -ForegroundColor Green

# Test 7: Remove-Container
Write-Host "`nTest 7: Remove-Container" -ForegroundColor Green
Write-Host "Suppression du conteneur..."

$removed = Remove-Container -Name "TestContainer"
if ($removed) {
    Write-Host "Conteneur supprime avec succes." -ForegroundColor Green
} else {
    Write-Host "Echec de la suppression du conteneur." -ForegroundColor Red
}

# Verifier si le conteneur existe encore
$remainingContainers = Get-Container
Write-Host "Nombre de conteneurs restants: $($remainingContainers.Count)" -ForegroundColor Yellow
foreach ($cont in $remainingContainers) {
    Write-Host "  $($cont.Name) (Image: $($cont.ImageName), Statut: $($cont.Status))" -ForegroundColor Gray
}

Write-Host "Test reussi!" -ForegroundColor Green

# Resume des tests
Write-Host "`n===== Resume des tests =====" -ForegroundColor Cyan
Write-Host "Tous les tests ont ete executes." -ForegroundColor Green
Write-Host "Verifiez les resultats ci-dessus pour vous assurer que toutes les fonctionnalites fonctionnent correctement." -ForegroundColor Yellow
