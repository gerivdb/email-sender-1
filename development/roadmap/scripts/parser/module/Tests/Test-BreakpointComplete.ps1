<#
.SYNOPSIS
    Test d'intÃ©gration pour les fonctions de points d'arrÃªt.

.DESCRIPTION
    Ce script effectue un test d'intÃ©gration pour les fonctions de points d'arrÃªt
    du module RoadmapParser. Il vÃ©rifie que toutes les fonctions fonctionnent ensemble.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Chemin vers les fonctions Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Public"

$setBreakpointPath = Join-Path -Path $functionsPath -ChildPath "Set-RoadmapBreakpoint.ps1"
$testConditionPath = Join-Path -Path $functionsPath -ChildPath "Test-RoadmapBreakpointCondition.ps1"
$invokeActionPath = Join-Path -Path $functionsPath -ChildPath "Invoke-RoadmapBreakpointAction.ps1"
$writeLogPath = Join-Path -Path $functionsPath -ChildPath "Write-RoadmapBreakpointLog.ps1"
$setTimedBreakpointPath = Join-Path -Path $functionsPath -ChildPath "Set-RoadmapTimedBreakpoint.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $setBreakpointPath)) {
    throw "Le fichier Set-RoadmapBreakpoint.ps1 est introuvable Ã  l'emplacement : $setBreakpointPath"
}

if (-not (Test-Path -Path $testConditionPath)) {
    throw "Le fichier Test-RoadmapBreakpointCondition.ps1 est introuvable Ã  l'emplacement : $testConditionPath"
}

if (-not (Test-Path -Path $invokeActionPath)) {
    throw "Le fichier Invoke-RoadmapBreakpointAction.ps1 est introuvable Ã  l'emplacement : $invokeActionPath"
}

if (-not (Test-Path -Path $writeLogPath)) {
    throw "Le fichier Write-RoadmapBreakpointLog.ps1 est introuvable Ã  l'emplacement : $writeLogPath"
}

if (-not (Test-Path -Path $setTimedBreakpointPath)) {
    throw "Le fichier Set-RoadmapTimedBreakpoint.ps1 est introuvable Ã  l'emplacement : $setTimedBreakpointPath"
}

# Importer les fonctions
. $testConditionPath
. $writeLogPath
. $invokeActionPath
. $setBreakpointPath
. $setTimedBreakpointPath
Write-Host "Fonctions importÃ©es." -ForegroundColor Green

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Remplacer temporairement Invoke-RoadmapBreakpointAction pour Ã©viter l'interaction utilisateur
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
    
    # Simuler l'exÃ©cution de l'action
    $script:actionCalled = $true
    $script:actionBreakpoint = $Breakpoint
    
    Write-Host "  Action simulÃ©e pour le point d'arrÃªt $($Breakpoint.Id)" -ForegroundColor Gray
    Write-Host "  Message : $($Breakpoint.Message)" -ForegroundColor Gray
    Write-Host "  Action : $($Breakpoint.Action)" -ForegroundColor Gray
}

# Remplacer temporairement Start-Sleep pour accÃ©lÃ©rer le test
$originalStartSleep = Get-Item function:Start-Sleep

function Start-Sleep {
    param (
        [Parameter(Mandatory = $false)]
        [int]$Seconds,
        
        [Parameter(Mandatory = $false)]
        [int]$Milliseconds
    )
    
    # Ne rien faire, juste simuler l'attente
    Write-Host "  Attente simulÃ©e de $Seconds secondes et $Milliseconds millisecondes" -ForegroundColor Gray
}

# Test 1: ScÃ©nario d'intÃ©gration - Point d'arrÃªt conditionnel
$totalTests++
Write-Host "`nTest 1: ScÃ©nario d'intÃ©gration - Point d'arrÃªt conditionnel" -ForegroundColor Cyan
try {
    # RÃ©initialiser les variables de suivi
    $script:actionCalled = $false
    $script:actionBreakpoint = $null
    
    # CrÃ©er une variable pour la condition
    $testVar = 5
    
    # Appeler la fonction avec une condition qui Ã©value Ã  true
    $breakpoint = Set-RoadmapBreakpoint -Condition { $testVar -gt 3 } -Action Log -Message "La variable est supÃ©rieure Ã  3" -Category "TestIntegration" -PassThru
    
    # VÃ©rifier le rÃ©sultat
    if ($breakpoint -and $breakpoint.Id -and $script:actionCalled -and $script:actionBreakpoint.Id -eq $breakpoint.Id) {
        Write-Host "  RÃ©ussi : Le point d'arrÃªt conditionnel a Ã©tÃ© correctement crÃ©Ã© et l'action a Ã©tÃ© exÃ©cutÃ©e." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : Le point d'arrÃªt conditionnel n'a pas Ã©tÃ© correctement crÃ©Ã© ou l'action n'a pas Ã©tÃ© exÃ©cutÃ©e." -ForegroundColor Red
        Write-Host "  Breakpoint : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
        Write-Host "  Action appelÃ©e : $actionCalled" -ForegroundColor Red
        if ($script:actionBreakpoint) {
            Write-Host "  Action breakpoint ID : $($script:actionBreakpoint.Id)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 2: ScÃ©nario d'intÃ©gration - Point d'arrÃªt temporisÃ©
$totalTests++
Write-Host "`nTest 2: ScÃ©nario d'intÃ©gration - Point d'arrÃªt temporisÃ©" -ForegroundColor Cyan
try {
    # RÃ©initialiser les variables de suivi
    $script:actionCalled = $false
    $script:actionBreakpoint = $null
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapTimedBreakpoint -Seconds 2 -Action Log -Message "2 secondes se sont Ã©coulÃ©es" -Category "TestIntegration" -PassThru
    
    # VÃ©rifier le rÃ©sultat
    if ($breakpoint -and $breakpoint.Id -and $script:actionCalled -and $script:actionBreakpoint.Id -eq $breakpoint.Id) {
        Write-Host "  RÃ©ussi : Le point d'arrÃªt temporisÃ© a Ã©tÃ© correctement crÃ©Ã© et l'action a Ã©tÃ© exÃ©cutÃ©e." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : Le point d'arrÃªt temporisÃ© n'a pas Ã©tÃ© correctement crÃ©Ã© ou l'action n'a pas Ã©tÃ© exÃ©cutÃ©e." -ForegroundColor Red
        Write-Host "  Breakpoint : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
        Write-Host "  Action appelÃ©e : $actionCalled" -ForegroundColor Red
        if ($script:actionBreakpoint) {
            Write-Host "  Action breakpoint ID : $($script:actionBreakpoint.Id)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 3: ScÃ©nario d'intÃ©gration - Ã‰valuation de condition avec variables
$totalTests++
Write-Host "`nTest 3: ScÃ©nario d'intÃ©gration - Ã‰valuation de condition avec variables" -ForegroundColor Cyan
try {
    # DÃ©finir des variables pour le test
    $vars = @{
        "count" = 10
        "threshold" = 5
    }
    
    # Ã‰valuer la condition
    $result = Test-RoadmapBreakpointCondition -Condition '$count -gt $threshold' -Variables $vars
    
    # VÃ©rifier le rÃ©sultat
    if ($result -eq $true) {
        Write-Host "  RÃ©ussi : La condition a Ã©tÃ© correctement Ã©valuÃ©e avec les variables fournies." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : La condition n'a pas Ã©tÃ© correctement Ã©valuÃ©e avec les variables fournies." -ForegroundColor Red
        Write-Host "  RÃ©sultat : $result" -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 4: ScÃ©nario d'intÃ©gration - Point d'arrÃªt avec action personnalisÃ©e
$totalTests++
Write-Host "`nTest 4: ScÃ©nario d'intÃ©gration - Point d'arrÃªt avec action personnalisÃ©e" -ForegroundColor Cyan
try {
    # RÃ©initialiser les variables de suivi
    $script:actionCalled = $false
    $script:actionBreakpoint = $null
    
    # Variable pour suivre l'exÃ©cution de l'action personnalisÃ©e
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
        
        # Simuler l'exÃ©cution de l'action
        $script:actionCalled = $true
        $script:actionBreakpoint = $Breakpoint
        
        # ExÃ©cuter l'action personnalisÃ©e si c'est le cas
        if ($Breakpoint.Action -eq "Custom" -and $Breakpoint.CustomAction) {
            try {
                & $Breakpoint.CustomAction -Breakpoint $Breakpoint -AdditionalInfo $AdditionalInfo
            } catch {
                Write-Host "  Erreur lors de l'exÃ©cution de l'action personnalisÃ©e : $_" -ForegroundColor Red
            }
        }
    }
    
    # Appeler la fonction avec une action personnalisÃ©e
    $breakpoint = Set-RoadmapBreakpoint -Condition $true -Action Custom -CustomAction {
        param($Breakpoint, $AdditionalInfo)
        $script:customActionExecuted = $true
    } -Message "Action personnalisÃ©e" -Category "TestIntegration" -PassThru
    
    # VÃ©rifier le rÃ©sultat
    if ($breakpoint -and $breakpoint.Id -and $script:actionCalled -and $script:actionBreakpoint.Id -eq $breakpoint.Id -and $customActionExecuted) {
        Write-Host "  RÃ©ussi : Le point d'arrÃªt avec action personnalisÃ©e a Ã©tÃ© correctement crÃ©Ã© et l'action a Ã©tÃ© exÃ©cutÃ©e." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : Le point d'arrÃªt avec action personnalisÃ©e n'a pas Ã©tÃ© correctement crÃ©Ã© ou l'action n'a pas Ã©tÃ© exÃ©cutÃ©e." -ForegroundColor Red
        Write-Host "  Breakpoint : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
        Write-Host "  Action appelÃ©e : $actionCalled" -ForegroundColor Red
        Write-Host "  Action personnalisÃ©e exÃ©cutÃ©e : $customActionExecuted" -ForegroundColor Red
    }
    
    # Restaurer la fonction modifiÃ©e pour les autres tests
    function Invoke-RoadmapBreakpointAction {
        param (
            [Parameter(Mandatory = $true, Position = 0)]
            [PSCustomObject]$Breakpoint,

            [Parameter(Mandatory = $false)]
            [hashtable]$AdditionalInfo
        )
        
        # Simuler l'exÃ©cution de l'action
        $script:actionCalled = $true
        $script:actionBreakpoint = $Breakpoint
        
        Write-Host "  Action simulÃ©e pour le point d'arrÃªt $($Breakpoint.Id)" -ForegroundColor Gray
        Write-Host "  Message : $($Breakpoint.Message)" -ForegroundColor Gray
        Write-Host "  Action : $($Breakpoint.Action)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Restaurer les fonctions originales
Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
Set-Item function:Start-Sleep -Value $originalStartSleep.ScriptBlock

# Afficher le rÃ©sumÃ© des tests
Write-Host "`nRÃ©sumÃ© des tests :" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s : $totalTests" -ForegroundColor Cyan
Write-Host "  Tests rÃ©ussis : $passedTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })
Write-Host "  Tests Ã©chouÃ©s : $($totalTests - $passedTests)" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })

# Retourner le rÃ©sultat global
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont rÃ©ussi !" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
