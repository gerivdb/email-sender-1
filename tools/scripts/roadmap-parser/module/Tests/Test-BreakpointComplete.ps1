<#
.SYNOPSIS
    Test d'intégration pour les fonctions de points d'arrêt.

.DESCRIPTION
    Ce script effectue un test d'intégration pour les fonctions de points d'arrêt
    du module RoadmapParser. Il vérifie que toutes les fonctions fonctionnent ensemble.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Chemin vers les fonctions à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Public"

$setBreakpointPath = Join-Path -Path $functionsPath -ChildPath "Set-RoadmapBreakpoint.ps1"
$testConditionPath = Join-Path -Path $functionsPath -ChildPath "Test-RoadmapBreakpointCondition.ps1"
$invokeActionPath = Join-Path -Path $functionsPath -ChildPath "Invoke-RoadmapBreakpointAction.ps1"
$writeLogPath = Join-Path -Path $functionsPath -ChildPath "Write-RoadmapBreakpointLog.ps1"
$setTimedBreakpointPath = Join-Path -Path $functionsPath -ChildPath "Set-RoadmapTimedBreakpoint.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $setBreakpointPath)) {
    throw "Le fichier Set-RoadmapBreakpoint.ps1 est introuvable à l'emplacement : $setBreakpointPath"
}

if (-not (Test-Path -Path $testConditionPath)) {
    throw "Le fichier Test-RoadmapBreakpointCondition.ps1 est introuvable à l'emplacement : $testConditionPath"
}

if (-not (Test-Path -Path $invokeActionPath)) {
    throw "Le fichier Invoke-RoadmapBreakpointAction.ps1 est introuvable à l'emplacement : $invokeActionPath"
}

if (-not (Test-Path -Path $writeLogPath)) {
    throw "Le fichier Write-RoadmapBreakpointLog.ps1 est introuvable à l'emplacement : $writeLogPath"
}

if (-not (Test-Path -Path $setTimedBreakpointPath)) {
    throw "Le fichier Set-RoadmapTimedBreakpoint.ps1 est introuvable à l'emplacement : $setTimedBreakpointPath"
}

# Importer les fonctions
. $testConditionPath
. $writeLogPath
. $invokeActionPath
. $setBreakpointPath
. $setTimedBreakpointPath
Write-Host "Fonctions importées." -ForegroundColor Green

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Remplacer temporairement Invoke-RoadmapBreakpointAction pour éviter l'interaction utilisateur
$originalInvokeAction = Get-Item function:Invoke-RoadmapBreakpointAction
$actionCalled = $false
$actionBreakpoint = $null

function Invoke-RoadmapBreakpointAction {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSCustomObject]$Breakpoint,

        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalInfo
    )
    
    # Simuler l'exécution de l'action
    $script:actionCalled = $true
    $script:actionBreakpoint = $Breakpoint
    
    Write-Host "  Action simulée pour le point d'arrêt $($Breakpoint.Id)" -ForegroundColor Gray
    Write-Host "  Message : $($Breakpoint.Message)" -ForegroundColor Gray
    Write-Host "  Action : $($Breakpoint.Action)" -ForegroundColor Gray
}

# Remplacer temporairement Start-Sleep pour accélérer le test
$originalStartSleep = Get-Item function:Start-Sleep

function Start-Sleep {
    param (
        [Parameter(Mandatory = $false)]
        [int]$Seconds,
        
        [Parameter(Mandatory = $false)]
        [int]$Milliseconds
    )
    
    # Ne rien faire, juste simuler l'attente
    Write-Host "  Attente simulée de $Seconds secondes et $Milliseconds millisecondes" -ForegroundColor Gray
}

# Test 1: Scénario d'intégration - Point d'arrêt conditionnel
$totalTests++
Write-Host "`nTest 1: Scénario d'intégration - Point d'arrêt conditionnel" -ForegroundColor Cyan
try {
    # Réinitialiser les variables de suivi
    $script:actionCalled = $false
    $script:actionBreakpoint = $null
    
    # Créer une variable pour la condition
    $testVar = 5
    
    # Appeler la fonction avec une condition qui évalue à true
    $breakpoint = Set-RoadmapBreakpoint -Condition { $testVar -gt 3 } -Action Log -Message "La variable est supérieure à 3" -Category "TestIntegration" -PassThru
    
    # Vérifier le résultat
    if ($breakpoint -and $breakpoint.Id -and $script:actionCalled -and $script:actionBreakpoint.Id -eq $breakpoint.Id) {
        Write-Host "  Réussi : Le point d'arrêt conditionnel a été correctement créé et l'action a été exécutée." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : Le point d'arrêt conditionnel n'a pas été correctement créé ou l'action n'a pas été exécutée." -ForegroundColor Red
        Write-Host "  Breakpoint : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
        Write-Host "  Action appelée : $actionCalled" -ForegroundColor Red
        if ($script:actionBreakpoint) {
            Write-Host "  Action breakpoint ID : $($script:actionBreakpoint.Id)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 2: Scénario d'intégration - Point d'arrêt temporisé
$totalTests++
Write-Host "`nTest 2: Scénario d'intégration - Point d'arrêt temporisé" -ForegroundColor Cyan
try {
    # Réinitialiser les variables de suivi
    $script:actionCalled = $false
    $script:actionBreakpoint = $null
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapTimedBreakpoint -Seconds 2 -Action Log -Message "2 secondes se sont écoulées" -Category "TestIntegration" -PassThru
    
    # Vérifier le résultat
    if ($breakpoint -and $breakpoint.Id -and $script:actionCalled -and $script:actionBreakpoint.Id -eq $breakpoint.Id) {
        Write-Host "  Réussi : Le point d'arrêt temporisé a été correctement créé et l'action a été exécutée." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : Le point d'arrêt temporisé n'a pas été correctement créé ou l'action n'a pas été exécutée." -ForegroundColor Red
        Write-Host "  Breakpoint : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
        Write-Host "  Action appelée : $actionCalled" -ForegroundColor Red
        if ($script:actionBreakpoint) {
            Write-Host "  Action breakpoint ID : $($script:actionBreakpoint.Id)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 3: Scénario d'intégration - Évaluation de condition avec variables
$totalTests++
Write-Host "`nTest 3: Scénario d'intégration - Évaluation de condition avec variables" -ForegroundColor Cyan
try {
    # Définir des variables pour le test
    $vars = @{
        "count" = 10
        "threshold" = 5
    }
    
    # Évaluer la condition
    $result = Test-RoadmapBreakpointCondition -Condition '$count -gt $threshold' -Variables $vars
    
    # Vérifier le résultat
    if ($result -eq $true) {
        Write-Host "  Réussi : La condition a été correctement évaluée avec les variables fournies." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : La condition n'a pas été correctement évaluée avec les variables fournies." -ForegroundColor Red
        Write-Host "  Résultat : $result" -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 4: Scénario d'intégration - Point d'arrêt avec action personnalisée
$totalTests++
Write-Host "`nTest 4: Scénario d'intégration - Point d'arrêt avec action personnalisée" -ForegroundColor Cyan
try {
    # Réinitialiser les variables de suivi
    $script:actionCalled = $false
    $script:actionBreakpoint = $null
    
    # Variable pour suivre l'exécution de l'action personnalisée
    $customActionExecuted = $false
    
    # Restaurer temporairement la fonction originale pour ce test
    Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
    
    # Remplacer temporairement la fonction pour ce test
    function Invoke-RoadmapBreakpointAction {
        param (
            [Parameter(Mandatory = $true, Position = 0)]
            [PSCustomObject]$Breakpoint,

            [Parameter(Mandatory = $false)]
            [hashtable]$AdditionalInfo
        )
        
        # Simuler l'exécution de l'action
        $script:actionCalled = $true
        $script:actionBreakpoint = $Breakpoint
        
        # Exécuter l'action personnalisée si c'est le cas
        if ($Breakpoint.Action -eq "Custom" -and $Breakpoint.CustomAction) {
            try {
                & $Breakpoint.CustomAction -Breakpoint $Breakpoint -AdditionalInfo $AdditionalInfo
            } catch {
                Write-Host "  Erreur lors de l'exécution de l'action personnalisée : $_" -ForegroundColor Red
            }
        }
    }
    
    # Appeler la fonction avec une action personnalisée
    $breakpoint = Set-RoadmapBreakpoint -Condition $true -Action Custom -CustomAction {
        param($Breakpoint, $AdditionalInfo)
        $script:customActionExecuted = $true
    } -Message "Action personnalisée" -Category "TestIntegration" -PassThru
    
    # Vérifier le résultat
    if ($breakpoint -and $breakpoint.Id -and $script:actionCalled -and $script:actionBreakpoint.Id -eq $breakpoint.Id -and $customActionExecuted) {
        Write-Host "  Réussi : Le point d'arrêt avec action personnalisée a été correctement créé et l'action a été exécutée." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : Le point d'arrêt avec action personnalisée n'a pas été correctement créé ou l'action n'a pas été exécutée." -ForegroundColor Red
        Write-Host "  Breakpoint : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
        Write-Host "  Action appelée : $actionCalled" -ForegroundColor Red
        Write-Host "  Action personnalisée exécutée : $customActionExecuted" -ForegroundColor Red
    }
    
    # Restaurer la fonction modifiée pour les autres tests
    function Invoke-RoadmapBreakpointAction {
        param (
            [Parameter(Mandatory = $true, Position = 0)]
            [PSCustomObject]$Breakpoint,

            [Parameter(Mandatory = $false)]
            [hashtable]$AdditionalInfo
        )
        
        # Simuler l'exécution de l'action
        $script:actionCalled = $true
        $script:actionBreakpoint = $Breakpoint
        
        Write-Host "  Action simulée pour le point d'arrêt $($Breakpoint.Id)" -ForegroundColor Gray
        Write-Host "  Message : $($Breakpoint.Message)" -ForegroundColor Gray
        Write-Host "  Action : $($Breakpoint.Action)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Restaurer les fonctions originales
Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
Set-Item function:Start-Sleep -Value $originalStartSleep.ScriptBlock

# Afficher le résumé des tests
Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
Write-Host "  Tests exécutés : $totalTests" -ForegroundColor Cyan
Write-Host "  Tests réussis : $passedTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })
Write-Host "  Tests échoués : $($totalTests - $passedTests)" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })

# Retourner le résultat global
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont réussi !" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
