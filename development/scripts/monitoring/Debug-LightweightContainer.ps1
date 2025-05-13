#Requires -Version 5.1
<#
.SYNOPSIS
    Script de débogage pour le module LightweightContainer.
.DESCRIPTION
    Ce script effectue des tests approfondis du module LightweightContainer
    pour identifier et corriger les problèmes potentiels.
.NOTES
    Nom: Debug-LightweightContainer.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-05-20
#>

# Activer le mode strict et les messages de débogage détaillés
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "LightweightContainer.psm1"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module LightweightContainer.psm1 introuvable à l'emplacement: $modulePath"
    exit 1
}

Import-Module $modulePath -Force -Verbose

# Fonction pour exécuter un test et capturer les résultats
function Invoke-ContainerTest {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName,

        [Parameter(Mandatory = $true)]
        [scriptblock]$TestScript
    )

    Write-Host "`n========== TEST: $TestName ==========" -ForegroundColor Cyan

    try {
        & $TestScript
        Write-Host "TEST RÉUSSI: $TestName" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "TEST ÉCHOUÉ: $TestName" -ForegroundColor Red
        Write-Host "ERREUR: $_" -ForegroundColor Red
        Write-Host "STACK TRACE:" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
        return $false
    }
}

# Fonction pour nettoyer les ressources de test
function Clear-TestResources {
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$ContainerNames = @(),

        [Parameter(Mandatory = $false)]
        [string[]]$ImageNames = @()
    )

    Write-Host "`nNettoyage des ressources de test..." -ForegroundColor Yellow

    # Supprimer les conteneurs
    foreach ($containerName in $ContainerNames) {
        try {
            $container = Get-Container -Name $containerName -ErrorAction SilentlyContinue
            if ($null -ne $container) {
                Write-Verbose "Suppression du conteneur: $containerName"
                Remove-Container -Name $containerName -Force -ErrorAction SilentlyContinue | Out-Null
            }
        } catch {
            Write-Warning "Erreur lors de la suppression du conteneur $containerName : $_"
        }
    }

    # Supprimer les images
    foreach ($imageName in $ImageNames) {
        try {
            $imagePath = Join-Path -Path "$PSScriptRoot\data\images" -ChildPath "$imageName.json"
            if (Test-Path -Path $imagePath) {
                Write-Verbose "Suppression de l'image: $imageName"
                Remove-Item -Path $imagePath -Force -ErrorAction SilentlyContinue
            }
        } catch {
            Write-Warning "Erreur lors de la suppression de l'image $imageName : $_"
        }
    }
}

# Initialiser les variables de test
$testContainers = @("DebugContainer1", "DebugContainer2", "DebugContainer3")
$testImages = @("DebugImage1", "DebugImage2")
$testResults = @{}

# Nettoyer les ressources avant de commencer
Clear-TestResources -ContainerNames $testContainers -ImageNames $testImages

# Test 1: Création d'image - Validation des paramètres
$testResults["Test1"] = Invoke-ContainerTest -TestName "Création d'image - Validation des paramètres" -TestScript {
    # Test avec des paramètres valides
    $image1 = New-ContainerImage -Name "DebugImage1" -ModuleDependencies @("Microsoft.PowerShell.Management") -EnvironmentVariables @{
        "DEBUG_VAR" = "DebugValue"
    }

    if ($null -eq $image1) {
        throw "La création de l'image a échoué"
    }

    # Vérifier que l'image a été créée correctement
    $imagePath = Join-Path -Path "$PSScriptRoot\data\images" -ChildPath "DebugImage1.json"
    if (-not (Test-Path -Path $imagePath)) {
        throw "Le fichier d'image n'a pas été créé"
    }

    # Vérifier le contenu de l'image
    $imageContent = Get-Content -Path $imagePath -Raw | ConvertFrom-Json
    if ($imageContent.Name -ne "DebugImage1") {
        throw "Le nom de l'image est incorrect"
    }

    if ($imageContent.ModuleDependencies -notcontains "Microsoft.PowerShell.Management") {
        throw "Les dépendances de modules sont incorrectes"
    }

    if ($imageContent.EnvironmentVariables.DEBUG_VAR -ne "DebugValue") {
        throw "Les variables d'environnement sont incorrectes"
    }

    # Test avec un nom d'image existant (doit échouer gracieusement)
    $image2 = New-ContainerImage -Name "DebugImage1" -ModuleDependencies @("Microsoft.PowerShell.Utility")
    if ($null -ne $image2) {
        throw "La création d'une image avec un nom existant devrait échouer"
    }

    # Test avec une image de base
    $image3 = New-ContainerImage -Name "DebugImage2" -BaseImage "DebugImage1" -EnvironmentVariables @{
        "DEBUG_VAR2" = "DebugValue2"
    }

    if ($null -eq $image3) {
        throw "La création de l'image basée sur une image existante a échoué"
    }

    # Vérifier l'héritage des propriétés
    $image3Content = Get-Content -Path (Join-Path -Path "$PSScriptRoot\data\images" -ChildPath "DebugImage2.json") -Raw | ConvertFrom-Json
    if ($image3Content.BaseImage -ne "DebugImage1") {
        throw "L'image de base n'est pas correctement référencée"
    }

    if ($image3Content.ModuleDependencies -notcontains "Microsoft.PowerShell.Management") {
        throw "Les dépendances de modules héritées sont incorrectes"
    }

    if ($image3Content.EnvironmentVariables.DEBUG_VAR -ne "DebugValue" -or $image3Content.EnvironmentVariables.DEBUG_VAR2 -ne "DebugValue2") {
        throw "Les variables d'environnement héritées sont incorrectes"
    }

    return $true
}

# Test 2: Création de conteneur - Validation des paramètres
$testResults["Test2"] = Invoke-ContainerTest -TestName "Création de conteneur - Validation des paramètres" -TestScript {
    # Test avec des paramètres valides
    $container1 = New-Container -Name "DebugContainer1" -ImageName "DebugImage1" -EnvironmentVariables @{
        "CONTAINER_VAR" = "ContainerValue"
    } -Persistent

    if ($null -eq $container1) {
        throw "La création du conteneur a échoué"
    }

    # Vérifier que le conteneur a été créé correctement
    $containerPath = Join-Path -Path "$PSScriptRoot\data\containers" -ChildPath "DebugContainer1"
    if (-not (Test-Path -Path $containerPath)) {
        throw "Le dossier du conteneur n'a pas été créé"
    }

    # Vérifier le script d'initialisation
    $initScriptPath = Join-Path -Path $containerPath -ChildPath "init.ps1"
    if (-not (Test-Path -Path $initScriptPath)) {
        throw "Le script d'initialisation n'a pas été créé"
    }

    # Vérifier les propriétés du conteneur
    if ($container1.Name -ne "DebugContainer1") {
        throw "Le nom du conteneur est incorrect"
    }

    if ($container1.ImageName -ne "DebugImage1") {
        throw "Le nom de l'image est incorrect"
    }

    if (-not $container1.Persistent) {
        throw "La persistance du conteneur est incorrecte"
    }

    if ($container1.Status -ne "Created") {
        throw "Le statut initial du conteneur est incorrect"
    }

    # Test avec un nom de conteneur existant (doit échouer gracieusement)
    $container2 = New-Container -Name "DebugContainer1" -ImageName "DebugImage1"
    if ($null -ne $container2) {
        throw "La création d'un conteneur avec un nom existant devrait échouer"
    }

    # Test avec une image inexistante (doit échouer gracieusement)
    $container3 = New-Container -Name "DebugContainer2" -ImageName "NonExistentImage"
    if ($null -ne $container3) {
        throw "La création d'un conteneur avec une image inexistante devrait échouer"
    }

    return $true
}

# Test 3: Démarrage et arrêt de conteneur
$testResults["Test3"] = Invoke-ContainerTest -TestName "Démarrage et arrêt de conteneur" -TestScript {
    # Créer un conteneur pour le test
    $container = New-Container -Name "DebugContainer2" -ImageName "DebugImage1"
    if ($null -eq $container) {
        throw "La création du conteneur a échoué"
    }

    # Démarrer le conteneur
    $startedContainer = Start-Container -Name "DebugContainer2" -ScriptBlock {
        Write-Output "Conteneur démarré avec succès"
        Start-Sleep -Seconds 5
        Write-Output "Conteneur terminé"
    }

    if ($null -eq $startedContainer) {
        throw "Le démarrage du conteneur a échoué"
    }

    if ($startedContainer.Status -ne "Running") {
        throw "Le statut du conteneur après démarrage est incorrect: $($startedContainer.Status)"
    }

    if ($null -eq $startedContainer.Process -or $startedContainer.Process.HasExited) {
        throw "Le processus du conteneur n'est pas en cours d'exécution"
    }

    # Vérifier l'état du conteneur
    $runningContainer = Get-Container -Name "DebugContainer2"
    if ($null -eq $runningContainer) {
        throw "Impossible de récupérer le conteneur en cours d'exécution"
    }

    if ($runningContainer.Status -ne "Running" -and $runningContainer.Status -ne "Stopped") {
        throw "Le statut du conteneur récupéré est incorrect: $($runningContainer.Status)"
    }

    # Arrêter le conteneur
    $stopped = Stop-Container -Name "DebugContainer2"
    if (-not $stopped) {
        throw "L'arrêt du conteneur a échoué"
    }

    # Vérifier l'état du conteneur après arrêt
    $stoppedContainer = Get-Container -Name "DebugContainer2"
    if ($null -eq $stoppedContainer) {
        throw "Impossible de récupérer le conteneur arrêté"
    }

    if ($stoppedContainer.Status -ne "Stopped") {
        throw "Le statut du conteneur après arrêt est incorrect: $($stoppedContainer.Status)"
    }

    return $true
}

# Test 4: Persistance des états
$testResults["Test4"] = Invoke-ContainerTest -TestName "Persistance des états" -TestScript {
    # Créer un conteneur persistant
    $container = New-Container -Name "DebugContainer3" -ImageName "DebugImage1" -Persistent
    if ($null -eq $container) {
        throw "La création du conteneur persistant a échoué"
    }

    # Démarrer le conteneur avec un état initial
    $startedContainer = Start-Container -Name "DebugContainer3" -ScriptBlock {
        # Vérifier que la fonction Save-ContainerState existe
        if (-not (Get-Command -Name Save-ContainerState -ErrorAction SilentlyContinue)) {
            Write-Error "La fonction Save-ContainerState n'existe pas dans ce contexte"
            return
        }

        # Enregistrer un état
        try {
            $state = @{
                Counter = 1
                LastRun = Get-Date
                Message = "Premier démarrage"
            }

            # Afficher l'état avant de l'enregistrer
            Write-Host "État à enregistrer:" -ForegroundColor Yellow
            $state.GetEnumerator() | ForEach-Object {
                Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Gray
            }

            Save-ContainerState -State $state
            Write-Output "État initial enregistré: Counter = 1"
        } catch {
            Write-Error "Erreur lors de l'enregistrement de l'état: $_"
        }
    }

    if ($null -eq $startedContainer) {
        throw "Le démarrage du conteneur persistant a échoué"
    }

    # Attendre que le conteneur termine son exécution
    Start-Sleep -Seconds 5

    # Vérifier que le fichier d'état a été créé
    $statePath = Join-Path -Path "$PSScriptRoot\data\containers\DebugContainer3" -ChildPath "state.json"
    if (-not (Test-Path -Path $statePath)) {
        throw "Le fichier d'état n'a pas été créé"
    }

    # Afficher le contenu brut du fichier d'état pour le débogage
    Write-Host "Contenu du fichier d'état:" -ForegroundColor Yellow
    $rawContent = Get-Content -Path $statePath -Raw
    Write-Host $rawContent -ForegroundColor Gray

    # Vérifier si le contenu est valide JSON
    try {
        $stateContent = $rawContent | ConvertFrom-Json
    } catch {
        throw "Le contenu du fichier d'état n'est pas un JSON valide: $_"
    }

    # Afficher les propriétés disponibles
    Write-Host "Propriétés disponibles:" -ForegroundColor Yellow
    $stateContent.PSObject.Properties | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Value)" -ForegroundColor Gray
    }

    # Vérifier si la propriété Counter existe
    if (-not ($stateContent.PSObject.Properties.Name -contains "Counter")) {
        throw "La propriété Counter n'existe pas dans l'état"
    }

    # Vérifier la valeur de Counter
    if ($stateContent.Counter -ne 1) {
        throw "L'état initial n'a pas été correctement enregistré (Counter = $($stateContent.Counter))"
    }

    # Démarrer le conteneur une seconde fois pour vérifier la persistance
    $startedContainer2 = Start-Container -Name "DebugContainer3" -ScriptBlock {
        # Récupérer l'état précédent
        $previousState = Get-ContainerState
        if ($null -eq $previousState) {
            throw "Impossible de récupérer l'état précédent"
        }

        # Afficher l'état précédent pour le débogage
        Write-Host "État précédent récupéré:" -ForegroundColor Yellow
        $previousState.GetEnumerator() | ForEach-Object {
            Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Gray
        }

        # Incrémenter le compteur
        $newCounter = $previousState["Counter"] + 1

        # Enregistrer le nouvel état
        $newState = @{
            Counter     = $newCounter
            LastRun     = Get-Date
            Message     = "Deuxième démarrage"
            PreviousRun = $previousState["LastRun"]
        }

        Save-ContainerState -State $newState
        Write-Output "État mis à jour: Counter = $newCounter"
    }

    # Attendre que le conteneur termine son exécution
    Start-Sleep -Seconds 5

    # Vérifier le contenu mis à jour du fichier d'état
    $updatedRawContent = Get-Content -Path $statePath -Raw
    Write-Host "Contenu mis à jour du fichier d'état:" -ForegroundColor Yellow
    Write-Host $updatedRawContent -ForegroundColor Gray

    $updatedStateContent = $updatedRawContent | ConvertFrom-Json

    # Afficher les propriétés disponibles
    Write-Host "Propriétés mises à jour:" -ForegroundColor Yellow
    $updatedStateContent.PSObject.Properties | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Value)" -ForegroundColor Gray
    }

    # Vérifier si la propriété Counter existe
    if (-not ($updatedStateContent.PSObject.Properties.Name -contains "Counter")) {
        throw "La propriété Counter n'existe pas dans l'état mis à jour"
    }

    # Vérifier la valeur de Counter
    if ($updatedStateContent.Counter -ne 2) {
        throw "L'état n'a pas été correctement mis à jour (Counter = $($updatedStateContent.Counter))"
    }

    # Vérifier la valeur de Message
    if ($updatedStateContent.Message -ne "Deuxième démarrage") {
        throw "Le message d'état n'a pas été correctement mis à jour (Message = $($updatedStateContent.Message))"
    }

    return $true
}

# Test 5: Suppression de conteneur
$testResults["Test5"] = Invoke-ContainerTest -TestName "Suppression de conteneur" -TestScript {
    # Supprimer un conteneur
    $removed = Remove-Container -Name "DebugContainer1"
    if (-not $removed) {
        throw "La suppression du conteneur a échoué"
    }

    # Vérifier que le conteneur a été supprimé
    $container = Get-Container -Name "DebugContainer1"
    if ($null -ne $container) {
        throw "Le conteneur n'a pas été correctement supprimé"
    }

    # Vérifier que le dossier du conteneur a été supprimé
    $containerPath = Join-Path -Path "$PSScriptRoot\data\containers" -ChildPath "DebugContainer1"
    if (Test-Path -Path $containerPath) {
        throw "Le dossier du conteneur n'a pas été supprimé"
    }

    # Supprimer un conteneur en cours d'exécution
    $container = New-Container -Name "DebugContainer1" -ImageName "DebugImage1"
    $startedContainer = Start-Container -Name "DebugContainer1" -ScriptBlock {
        Write-Output "Conteneur démarré"
        Start-Sleep -Seconds 30
        Write-Output "Conteneur terminé"
    }

    # Supprimer le conteneur en cours d'exécution avec force
    $removed = Remove-Container -Name "DebugContainer1" -Force
    if (-not $removed) {
        throw "La suppression forcée du conteneur a échoué"
    }

    # Vérifier que le conteneur a été supprimé
    $container = Get-Container -Name "DebugContainer1"
    if ($null -ne $container) {
        throw "Le conteneur n'a pas été correctement supprimé après suppression forcée"
    }

    return $true
}

# Afficher le résumé des tests
Write-Host "`n========== RÉSUMÉ DES TESTS ==========" -ForegroundColor Cyan
$totalTests = $testResults.Count
$passedTests = ($testResults.Values | Where-Object { $_ -eq $true }).Count
$failedTests = $totalTests - $passedTests

Write-Host "Tests exécutés: $totalTests" -ForegroundColor White
Write-Host "Tests réussis: $passedTests" -ForegroundColor Green
Write-Host "Tests échoués: $failedTests" -ForegroundColor Red

if ($failedTests -gt 0) {
    Write-Host "`nTests échoués:" -ForegroundColor Red
    foreach ($test in $testResults.Keys) {
        if (-not $testResults[$test]) {
            Write-Host "  - $test" -ForegroundColor Red
        }
    }
}

# Nettoyer les ressources après les tests
Clear-TestResources -ContainerNames $testContainers -ImageNames $testImages

# Retourner le résultat global
if ($failedTests -eq 0) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué!" -ForegroundColor Red
    exit 1
}
