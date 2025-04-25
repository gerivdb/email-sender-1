<#
.SYNOPSIS
    Tests unitaires pour la fonction Set-RoadmapBreakpoint.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Set-RoadmapBreakpoint
    qui permet de définir des points d'arrêt conditionnels.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Chemin vers les fonctions à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Set-RoadmapBreakpoint.ps1"
$testConditionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Test-RoadmapBreakpointCondition.ps1"
$invokeActionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapBreakpointAction.ps1"
$writeLogPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Write-RoadmapBreakpointLog.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Set-RoadmapBreakpoint.ps1 est introuvable à l'emplacement : $functionPath"
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

# Importer les fonctions
. $testConditionPath
. $invokeActionPath
. $writeLogPath
. $functionPath
Write-Host "Fonctions importées." -ForegroundColor Green

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Test 1: Créer un point d'arrêt avec une condition simple
$totalTests++
Write-Host "`nTest 1: Créer un point d'arrêt avec une condition simple" -ForegroundColor Cyan
try {
    # Remplacer temporairement Invoke-RoadmapBreakpointAction pour éviter l'interaction utilisateur
    $originalInvokeAction = Get-Item function:Invoke-RoadmapBreakpointAction
    
    function Invoke-RoadmapBreakpointAction {
        param (
            [Parameter(Mandatory = $true, Position = 0)]
            [PSCustomObject]$Breakpoint,

            [Parameter(Mandatory = $false)]
            [hashtable]$AdditionalInfo
        )
        
        # Ne rien faire, juste simuler l'action
        Write-Verbose "Action simulée pour le point d'arrêt $($Breakpoint.Id)"
    }
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapBreakpoint -Condition $true -Action Log -Message "Test de point d'arrêt" -PassThru
    
    # Vérifier le résultat
    if ($breakpoint -and $breakpoint.Id -and $breakpoint.Condition -eq $true -and $breakpoint.Action -eq "Log") {
        Write-Host "  Réussi : Le point d'arrêt a été correctement créé." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : Le point d'arrêt n'a pas été correctement créé." -ForegroundColor Red
        Write-Host "  Résultat : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
    }
    
    # Restaurer la fonction originale
    Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 2: Créer un point d'arrêt avec une condition qui évalue à false
$totalTests++
Write-Host "`nTest 2: Créer un point d'arrêt avec une condition qui évalue à false" -ForegroundColor Cyan
try {
    # Remplacer temporairement Invoke-RoadmapBreakpointAction pour éviter l'interaction utilisateur
    $originalInvokeAction = Get-Item function:Invoke-RoadmapBreakpointAction
    
    function Invoke-RoadmapBreakpointAction {
        param (
            [Parameter(Mandatory = $true, Position = 0)]
            [PSCustomObject]$Breakpoint,

            [Parameter(Mandatory = $false)]
            [hashtable]$AdditionalInfo
        )
        
        # Ne rien faire, juste simuler l'action
        Write-Verbose "Action simulée pour le point d'arrêt $($Breakpoint.Id)"
    }
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapBreakpoint -Condition $false -Action Log -Message "Test de point d'arrêt" -PassThru
    
    # Vérifier le résultat
    if ($breakpoint -and $breakpoint.Id -and $breakpoint.Condition -eq $false -and $breakpoint.HitCount -eq 0) {
        Write-Host "  Réussi : Le point d'arrêt a été correctement créé mais n'a pas été déclenché." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : Le point d'arrêt n'a pas été correctement créé ou a été déclenché alors qu'il ne devrait pas l'être." -ForegroundColor Red
        Write-Host "  Résultat : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
    }
    
    # Restaurer la fonction originale
    Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 3: Créer un point d'arrêt avec une action personnalisée
$totalTests++
Write-Host "`nTest 3: Créer un point d'arrêt avec une action personnalisée" -ForegroundColor Cyan
try {
    # Remplacer temporairement Invoke-RoadmapBreakpointAction pour éviter l'interaction utilisateur
    $originalInvokeAction = Get-Item function:Invoke-RoadmapBreakpointAction
    
    $customActionCalled = $false
    
    function Invoke-RoadmapBreakpointAction {
        param (
            [Parameter(Mandatory = $true, Position = 0)]
            [PSCustomObject]$Breakpoint,

            [Parameter(Mandatory = $false)]
            [hashtable]$AdditionalInfo
        )
        
        # Simuler l'exécution de l'action personnalisée
        if ($Breakpoint.Action -eq "Custom" -and $Breakpoint.CustomAction) {
            $script:customActionCalled = $true
        }
    }
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapBreakpoint -Condition $true -Action Custom -CustomAction { Write-Host "Action personnalisée" } -Message "Test de point d'arrêt" -PassThru
    
    # Vérifier le résultat
    if ($breakpoint -and $breakpoint.Id -and $breakpoint.Action -eq "Custom" -and $breakpoint.CustomAction -and $customActionCalled) {
        Write-Host "  Réussi : Le point d'arrêt avec action personnalisée a été correctement créé et l'action a été simulée." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : Le point d'arrêt avec action personnalisée n'a pas été correctement créé ou l'action n'a pas été simulée." -ForegroundColor Red
        Write-Host "  Résultat : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
        Write-Host "  Action personnalisée appelée : $customActionCalled" -ForegroundColor Red
    }
    
    # Restaurer la fonction originale
    Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 4: Créer un point d'arrêt avec un délai d'expiration
$totalTests++
Write-Host "`nTest 4: Créer un point d'arrêt avec un délai d'expiration" -ForegroundColor Cyan
try {
    # Remplacer temporairement Invoke-RoadmapBreakpointAction pour éviter l'interaction utilisateur
    $originalInvokeAction = Get-Item function:Invoke-RoadmapBreakpointAction
    
    function Invoke-RoadmapBreakpointAction {
        param (
            [Parameter(Mandatory = $true, Position = 0)]
            [PSCustomObject]$Breakpoint,

            [Parameter(Mandatory = $false)]
            [hashtable]$AdditionalInfo
        )
        
        # Ne rien faire, juste simuler l'action
        Write-Verbose "Action simulée pour le point d'arrêt $($Breakpoint.Id)"
    }
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapBreakpoint -Condition $true -Action Log -Message "Test de point d'arrêt" -Timeout 60 -PassThru
    
    # Vérifier le résultat
    if ($breakpoint -and $breakpoint.Id -and $breakpoint.Timeout -eq 60 -and $breakpoint.ExpiresAt) {
        Write-Host "  Réussi : Le point d'arrêt avec délai d'expiration a été correctement créé." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : Le point d'arrêt avec délai d'expiration n'a pas été correctement créé." -ForegroundColor Red
        Write-Host "  Résultat : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
    }
    
    # Restaurer la fonction originale
    Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 5: Créer un point d'arrêt avec un nombre maximum de déclenchements
$totalTests++
Write-Host "`nTest 5: Créer un point d'arrêt avec un nombre maximum de déclenchements" -ForegroundColor Cyan
try {
    # Remplacer temporairement Invoke-RoadmapBreakpointAction pour éviter l'interaction utilisateur
    $originalInvokeAction = Get-Item function:Invoke-RoadmapBreakpointAction
    
    function Invoke-RoadmapBreakpointAction {
        param (
            [Parameter(Mandatory = $true, Position = 0)]
            [PSCustomObject]$Breakpoint,

            [Parameter(Mandatory = $false)]
            [hashtable]$AdditionalInfo
        )
        
        # Ne rien faire, juste simuler l'action
        Write-Verbose "Action simulée pour le point d'arrêt $($Breakpoint.Id)"
    }
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapBreakpoint -Condition $true -Action Log -Message "Test de point d'arrêt" -MaxHits 5 -PassThru
    
    # Vérifier le résultat
    if ($breakpoint -and $breakpoint.Id -and $breakpoint.MaxHits -eq 5 -and $breakpoint.HitCount -eq 1) {
        Write-Host "  Réussi : Le point d'arrêt avec nombre maximum de déclenchements a été correctement créé." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : Le point d'arrêt avec nombre maximum de déclenchements n'a pas été correctement créé." -ForegroundColor Red
        Write-Host "  Résultat : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
    }
    
    # Restaurer la fonction originale
    Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

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
