<#
.SYNOPSIS
    Tests unitaires pour la fonction Set-RoadmapBreakpoint.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Set-RoadmapBreakpoint
    qui permet de dÃ©finir des points d'arrÃªt conditionnels.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Chemin vers les fonctions Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Set-RoadmapBreakpoint.ps1"
$testConditionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Test-RoadmapBreakpointCondition.ps1"
$invokeActionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapBreakpointAction.ps1"
$writeLogPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Write-RoadmapBreakpointLog.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Set-RoadmapBreakpoint.ps1 est introuvable Ã  l'emplacement : $functionPath"
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

# Importer les fonctions
. $testConditionPath
. $invokeActionPath
. $writeLogPath
. $functionPath
Write-Host "Fonctions importÃ©es." -ForegroundColor Green

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Test 1: CrÃ©er un point d'arrÃªt avec une condition simple
$totalTests++
Write-Host "`nTest 1: CrÃ©er un point d'arrÃªt avec une condition simple" -ForegroundColor Cyan
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
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapBreakpoint -Condition $true -Action Log -Message "Test de point d'arrÃªt" -PassThru
    
    # VÃ©rifier le rÃ©sultat
    if ($breakpoint -and $breakpoint.Id -and $breakpoint.Condition -eq $true -and $breakpoint.Action -eq "Log") {
        Write-Host "  RÃ©ussi : Le point d'arrÃªt a Ã©tÃ© correctement crÃ©Ã©." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : Le point d'arrÃªt n'a pas Ã©tÃ© correctement crÃ©Ã©." -ForegroundColor Red
        Write-Host "  RÃ©sultat : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
    }
    
    # Restaurer la fonction originale
    Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 2: CrÃ©er un point d'arrÃªt avec une condition qui Ã©value Ã  false
$totalTests++
Write-Host "`nTest 2: CrÃ©er un point d'arrÃªt avec une condition qui Ã©value Ã  false" -ForegroundColor Cyan
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
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapBreakpoint -Condition $false -Action Log -Message "Test de point d'arrÃªt" -PassThru
    
    # VÃ©rifier le rÃ©sultat
    if ($breakpoint -and $breakpoint.Id -and $breakpoint.Condition -eq $false -and $breakpoint.HitCount -eq 0) {
        Write-Host "  RÃ©ussi : Le point d'arrÃªt a Ã©tÃ© correctement crÃ©Ã© mais n'a pas Ã©tÃ© dÃ©clenchÃ©." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : Le point d'arrÃªt n'a pas Ã©tÃ© correctement crÃ©Ã© ou a Ã©tÃ© dÃ©clenchÃ© alors qu'il ne devrait pas l'Ãªtre." -ForegroundColor Red
        Write-Host "  RÃ©sultat : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
    }
    
    # Restaurer la fonction originale
    Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 3: CrÃ©er un point d'arrÃªt avec une action personnalisÃ©e
$totalTests++
Write-Host "`nTest 3: CrÃ©er un point d'arrÃªt avec une action personnalisÃ©e" -ForegroundColor Cyan
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
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapBreakpoint -Condition $true -Action Custom -CustomAction { Write-Host "Action personnalisÃ©e" } -Message "Test de point d'arrÃªt" -PassThru
    
    # VÃ©rifier le rÃ©sultat
    if ($breakpoint -and $breakpoint.Id -and $breakpoint.Action -eq "Custom" -and $breakpoint.CustomAction -and $customActionCalled) {
        Write-Host "  RÃ©ussi : Le point d'arrÃªt avec action personnalisÃ©e a Ã©tÃ© correctement crÃ©Ã© et l'action a Ã©tÃ© simulÃ©e." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : Le point d'arrÃªt avec action personnalisÃ©e n'a pas Ã©tÃ© correctement crÃ©Ã© ou l'action n'a pas Ã©tÃ© simulÃ©e." -ForegroundColor Red
        Write-Host "  RÃ©sultat : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
        Write-Host "  Action personnalisÃ©e appelÃ©e : $customActionCalled" -ForegroundColor Red
    }
    
    # Restaurer la fonction originale
    Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 4: CrÃ©er un point d'arrÃªt avec un dÃ©lai d'expiration
$totalTests++
Write-Host "`nTest 4: CrÃ©er un point d'arrÃªt avec un dÃ©lai d'expiration" -ForegroundColor Cyan
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
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapBreakpoint -Condition $true -Action Log -Message "Test de point d'arrÃªt" -Timeout 60 -PassThru
    
    # VÃ©rifier le rÃ©sultat
    if ($breakpoint -and $breakpoint.Id -and $breakpoint.Timeout -eq 60 -and $breakpoint.ExpiresAt) {
        Write-Host "  RÃ©ussi : Le point d'arrÃªt avec dÃ©lai d'expiration a Ã©tÃ© correctement crÃ©Ã©." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : Le point d'arrÃªt avec dÃ©lai d'expiration n'a pas Ã©tÃ© correctement crÃ©Ã©." -ForegroundColor Red
        Write-Host "  RÃ©sultat : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
    }
    
    # Restaurer la fonction originale
    Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 5: CrÃ©er un point d'arrÃªt avec un nombre maximum de dÃ©clenchements
$totalTests++
Write-Host "`nTest 5: CrÃ©er un point d'arrÃªt avec un nombre maximum de dÃ©clenchements" -ForegroundColor Cyan
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
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapBreakpoint -Condition $true -Action Log -Message "Test de point d'arrÃªt" -MaxHits 5 -PassThru
    
    # VÃ©rifier le rÃ©sultat
    if ($breakpoint -and $breakpoint.Id -and $breakpoint.MaxHits -eq 5 -and $breakpoint.HitCount -eq 1) {
        Write-Host "  RÃ©ussi : Le point d'arrÃªt avec nombre maximum de dÃ©clenchements a Ã©tÃ© correctement crÃ©Ã©." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Ã‰chouÃ© : Le point d'arrÃªt avec nombre maximum de dÃ©clenchements n'a pas Ã©tÃ© correctement crÃ©Ã©." -ForegroundColor Red
        Write-Host "  RÃ©sultat : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
    }
    
    # Restaurer la fonction originale
    Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
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
