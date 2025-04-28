<#
.SYNOPSIS
    Tests unitaires pour la fonction Set-RoadmapTimedBreakpoint.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Set-RoadmapTimedBreakpoint
    qui permet de dÃ©finir des points d'arrÃªt temporisÃ©s.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Chemin vers les fonctions Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Set-RoadmapTimedBreakpoint.ps1"
$invokeActionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapBreakpointAction.ps1"
$writeLogPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Write-RoadmapBreakpointLog.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Set-RoadmapTimedBreakpoint.ps1 est introuvable Ã  l'emplacement : $functionPath"
}

if (-not (Test-Path -Path $invokeActionPath)) {
    throw "Le fichier Invoke-RoadmapBreakpointAction.ps1 est introuvable Ã  l'emplacement : $invokeActionPath"
}

if (-not (Test-Path -Path $writeLogPath)) {
    throw "Le fichier Write-RoadmapBreakpointLog.ps1 est introuvable Ã  l'emplacement : $writeLogPath"
}

# Importer les fonctions
. $invokeActionPath
. $writeLogPath
. $functionPath
Write-Host "Fonctions importÃ©es." -ForegroundColor Green

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Test 1: CrÃ©er un point d'arrÃªt temporisÃ© avec un dÃ©lai en secondes
$totalTests++
Write-Host "`nTest 1: CrÃ©er un point d'arrÃªt temporisÃ© avec un dÃ©lai en secondes" -ForegroundColor Cyan
try {
    # Remplacer temporairement Invoke-RoadmapBreakpointAction pour Ã©viter l'interaction utilisateur
    $originalInvokeAction = Get-Item function:Invoke-RoadmapBreakpointAction
    
    function Invoke-RoadmapBreakpointAction {
        param (
            [Parameter(Mandatory = $true, Position = 0)]
            [PSCustomObject]$Breakpoint,

            [Parameter(Mandatory = $false)]
            [hashtable]$AdditionalInfo
        )
        
        # Ne rien faire, juste simuler l'action
        Write-Verbose "Action simulÃ©e pour le point d'arrÃªt $($Breakpoint.Id)"
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
        Write-Verbose "Attente simulÃ©e de $Seconds secondes et $Milliseconds millisecondes"
    }
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapTimedBreakpoint -Seconds 5 -Action Log -Message "Test de point d'arrÃªt temporisÃ©" -PassThru
    
    # VÃ©rifier le rÃ©sultat
    if ($breakpoint -and $breakpoint.Id -and $breakpoint.DelaySeconds -eq 5 -and $breakpoint.HitCount -eq 1) {
        Write-Host "  RÃ©ussi : Le point d'arrÃªt temporisÃ© a Ã©tÃ© correctement crÃ©Ã© et dÃ©clenchÃ©." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : Le point d'arrÃªt temporisÃ© n'a pas Ã©tÃ© correctement crÃ©Ã© ou dÃ©clenchÃ©." -ForegroundColor Red
        Write-Host "  RÃ©sultat : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
    }
    
    # Restaurer les fonctions originales
    Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
    Set-Item function:Start-Sleep -Value $originalStartSleep.ScriptBlock
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 2: CrÃ©er un point d'arrÃªt temporisÃ© avec un dÃ©lai en millisecondes
$totalTests++
Write-Host "`nTest 2: CrÃ©er un point d'arrÃªt temporisÃ© avec un dÃ©lai en millisecondes" -ForegroundColor Cyan
try {
    # Remplacer temporairement Invoke-RoadmapBreakpointAction pour Ã©viter l'interaction utilisateur
    $originalInvokeAction = Get-Item function:Invoke-RoadmapBreakpointAction
    
    function Invoke-RoadmapBreakpointAction {
        param (
            [Parameter(Mandatory = $true, Position = 0)]
            [PSCustomObject]$Breakpoint,

            [Parameter(Mandatory = $false)]
            [hashtable]$AdditionalInfo
        )
        
        # Ne rien faire, juste simuler l'action
        Write-Verbose "Action simulÃ©e pour le point d'arrÃªt $($Breakpoint.Id)"
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
        Write-Verbose "Attente simulÃ©e de $Seconds secondes et $Milliseconds millisecondes"
    }
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapTimedBreakpoint -Milliseconds 500 -Action Log -Message "Test de point d'arrÃªt temporisÃ©" -PassThru
    
    # VÃ©rifier le rÃ©sultat
    if ($breakpoint -and $breakpoint.Id -and $breakpoint.DelayMilliseconds -eq 500 -and $breakpoint.TotalDelayMilliseconds -eq 500) {
        Write-Host "  RÃ©ussi : Le point d'arrÃªt temporisÃ© avec dÃ©lai en millisecondes a Ã©tÃ© correctement crÃ©Ã©." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : Le point d'arrÃªt temporisÃ© avec dÃ©lai en millisecondes n'a pas Ã©tÃ© correctement crÃ©Ã©." -ForegroundColor Red
        Write-Host "  RÃ©sultat : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
    }
    
    # Restaurer les fonctions originales
    Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
    Set-Item function:Start-Sleep -Value $originalStartSleep.ScriptBlock
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 3: CrÃ©er un point d'arrÃªt temporisÃ© avec une action personnalisÃ©e
$totalTests++
Write-Host "`nTest 3: CrÃ©er un point d'arrÃªt temporisÃ© avec une action personnalisÃ©e" -ForegroundColor Cyan
try {
    # Remplacer temporairement Invoke-RoadmapBreakpointAction pour Ã©viter l'interaction utilisateur
    $originalInvokeAction = Get-Item function:Invoke-RoadmapBreakpointAction
    
    $customActionCalled = $false
    
    function Invoke-RoadmapBreakpointAction {
        param (
            [Parameter(Mandatory = $true, Position = 0)]
            [PSCustomObject]$Breakpoint,

            [Parameter(Mandatory = $false)]
            [hashtable]$AdditionalInfo
        )
        
        # Simuler l'exÃ©cution de l'action personnalisÃ©e
        if ($Breakpoint.Action -eq "Custom" -and $Breakpoint.CustomAction) {
            $script:customActionCalled = $true
        }
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
        Write-Verbose "Attente simulÃ©e de $Seconds secondes et $Milliseconds millisecondes"
    }
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapTimedBreakpoint -Seconds 1 -Action Custom -CustomAction { Write-Host "Action personnalisÃ©e" } -Message "Test de point d'arrÃªt temporisÃ©" -PassThru
    
    # VÃ©rifier le rÃ©sultat
    if ($breakpoint -and $breakpoint.Id -and $breakpoint.Action -eq "Custom" -and $breakpoint.CustomAction -and $customActionCalled) {
        Write-Host "  RÃ©ussi : Le point d'arrÃªt temporisÃ© avec action personnalisÃ©e a Ã©tÃ© correctement crÃ©Ã© et l'action a Ã©tÃ© simulÃ©e." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : Le point d'arrÃªt temporisÃ© avec action personnalisÃ©e n'a pas Ã©tÃ© correctement crÃ©Ã© ou l'action n'a pas Ã©tÃ© simulÃ©e." -ForegroundColor Red
        Write-Host "  RÃ©sultat : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
        Write-Host "  Action personnalisÃ©e appelÃ©e : $customActionCalled" -ForegroundColor Red
    }
    
    # Restaurer les fonctions originales
    Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
    Set-Item function:Start-Sleep -Value $originalStartSleep.ScriptBlock
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 4: CrÃ©er un point d'arrÃªt temporisÃ© avec un dÃ©lai invalide
$totalTests++
Write-Host "`nTest 4: CrÃ©er un point d'arrÃªt temporisÃ© avec un dÃ©lai invalide" -ForegroundColor Cyan
try {
    # Appeler la fonction avec un dÃ©lai invalide
    Set-RoadmapTimedBreakpoint -Seconds 0 -Milliseconds 0 -Action Log -Message "Test de point d'arrÃªt temporisÃ©"
    
    Write-Host "  Ã‰chouÃ© : La fonction n'a pas levÃ© d'exception pour un dÃ©lai invalide." -ForegroundColor Red
} catch {
    if ($_.Exception.Message -match "dÃ©lai doit Ãªtre supÃ©rieur Ã  zÃ©ro") {
        Write-Host "  RÃ©ussi : La fonction a correctement levÃ© une exception pour un dÃ©lai invalide." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : La fonction a levÃ© une exception inattendue : $_" -ForegroundColor Red
    }
}

# Test 5: CrÃ©er un point d'arrÃªt temporisÃ© avec une action personnalisÃ©e sans fournir de CustomAction
$totalTests++
Write-Host "`nTest 5: CrÃ©er un point d'arrÃªt temporisÃ© avec une action personnalisÃ©e sans fournir de CustomAction" -ForegroundColor Cyan
try {
    # Appeler la fonction avec une action personnalisÃ©e sans CustomAction
    Set-RoadmapTimedBreakpoint -Seconds 1 -Action Custom -Message "Test de point d'arrÃªt temporisÃ©"
    
    Write-Host "  Ã‰chouÃ© : La fonction n'a pas levÃ© d'exception pour une action personnalisÃ©e sans CustomAction." -ForegroundColor Red
} catch {
    if ($_.Exception.Message -match "CustomAction est requis") {
        Write-Host "  RÃ©ussi : La fonction a correctement levÃ© une exception pour une action personnalisÃ©e sans CustomAction." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : La fonction a levÃ© une exception inattendue : $_" -ForegroundColor Red
    }
}

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
