<#
.SYNOPSIS
    Tests unitaires pour la fonction Set-RoadmapTimedBreakpoint.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Set-RoadmapTimedBreakpoint
    qui permet de définir des points d'arrêt temporisés.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Chemin vers les fonctions à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Set-RoadmapTimedBreakpoint.ps1"
$invokeActionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapBreakpointAction.ps1"
$writeLogPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Write-RoadmapBreakpointLog.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Set-RoadmapTimedBreakpoint.ps1 est introuvable à l'emplacement : $functionPath"
}

if (-not (Test-Path -Path $invokeActionPath)) {
    throw "Le fichier Invoke-RoadmapBreakpointAction.ps1 est introuvable à l'emplacement : $invokeActionPath"
}

if (-not (Test-Path -Path $writeLogPath)) {
    throw "Le fichier Write-RoadmapBreakpointLog.ps1 est introuvable à l'emplacement : $writeLogPath"
}

# Importer les fonctions
. $invokeActionPath
. $writeLogPath
. $functionPath
Write-Host "Fonctions importées." -ForegroundColor Green

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Test 1: Créer un point d'arrêt temporisé avec un délai en secondes
$totalTests++
Write-Host "`nTest 1: Créer un point d'arrêt temporisé avec un délai en secondes" -ForegroundColor Cyan
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
        Write-Verbose "Attente simulée de $Seconds secondes et $Milliseconds millisecondes"
    }
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapTimedBreakpoint -Seconds 5 -Action Log -Message "Test de point d'arrêt temporisé" -PassThru
    
    # Vérifier le résultat
    if ($breakpoint -and $breakpoint.Id -and $breakpoint.DelaySeconds -eq 5 -and $breakpoint.HitCount -eq 1) {
        Write-Host "  Réussi : Le point d'arrêt temporisé a été correctement créé et déclenché." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : Le point d'arrêt temporisé n'a pas été correctement créé ou déclenché." -ForegroundColor Red
        Write-Host "  Résultat : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
    }
    
    # Restaurer les fonctions originales
    Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
    Set-Item function:Start-Sleep -Value $originalStartSleep.ScriptBlock
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 2: Créer un point d'arrêt temporisé avec un délai en millisecondes
$totalTests++
Write-Host "`nTest 2: Créer un point d'arrêt temporisé avec un délai en millisecondes" -ForegroundColor Cyan
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
        Write-Verbose "Attente simulée de $Seconds secondes et $Milliseconds millisecondes"
    }
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapTimedBreakpoint -Milliseconds 500 -Action Log -Message "Test de point d'arrêt temporisé" -PassThru
    
    # Vérifier le résultat
    if ($breakpoint -and $breakpoint.Id -and $breakpoint.DelayMilliseconds -eq 500 -and $breakpoint.TotalDelayMilliseconds -eq 500) {
        Write-Host "  Réussi : Le point d'arrêt temporisé avec délai en millisecondes a été correctement créé." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : Le point d'arrêt temporisé avec délai en millisecondes n'a pas été correctement créé." -ForegroundColor Red
        Write-Host "  Résultat : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
    }
    
    # Restaurer les fonctions originales
    Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
    Set-Item function:Start-Sleep -Value $originalStartSleep.ScriptBlock
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 3: Créer un point d'arrêt temporisé avec une action personnalisée
$totalTests++
Write-Host "`nTest 3: Créer un point d'arrêt temporisé avec une action personnalisée" -ForegroundColor Cyan
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
        Write-Verbose "Attente simulée de $Seconds secondes et $Milliseconds millisecondes"
    }
    
    # Appeler la fonction
    $breakpoint = Set-RoadmapTimedBreakpoint -Seconds 1 -Action Custom -CustomAction { Write-Host "Action personnalisée" } -Message "Test de point d'arrêt temporisé" -PassThru
    
    # Vérifier le résultat
    if ($breakpoint -and $breakpoint.Id -and $breakpoint.Action -eq "Custom" -and $breakpoint.CustomAction -and $customActionCalled) {
        Write-Host "  Réussi : Le point d'arrêt temporisé avec action personnalisée a été correctement créé et l'action a été simulée." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : Le point d'arrêt temporisé avec action personnalisée n'a pas été correctement créé ou l'action n'a pas été simulée." -ForegroundColor Red
        Write-Host "  Résultat : $($breakpoint | ConvertTo-Json)" -ForegroundColor Red
        Write-Host "  Action personnalisée appelée : $customActionCalled" -ForegroundColor Red
    }
    
    # Restaurer les fonctions originales
    Set-Item function:Invoke-RoadmapBreakpointAction -Value $originalInvokeAction.ScriptBlock
    Set-Item function:Start-Sleep -Value $originalStartSleep.ScriptBlock
} catch {
    Write-Host "  Erreur : $_" -ForegroundColor Red
}

# Test 4: Créer un point d'arrêt temporisé avec un délai invalide
$totalTests++
Write-Host "`nTest 4: Créer un point d'arrêt temporisé avec un délai invalide" -ForegroundColor Cyan
try {
    # Appeler la fonction avec un délai invalide
    Set-RoadmapTimedBreakpoint -Seconds 0 -Milliseconds 0 -Action Log -Message "Test de point d'arrêt temporisé"
    
    Write-Host "  Échoué : La fonction n'a pas levé d'exception pour un délai invalide." -ForegroundColor Red
} catch {
    if ($_.Exception.Message -match "délai doit être supérieur à zéro") {
        Write-Host "  Réussi : La fonction a correctement levé une exception pour un délai invalide." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : La fonction a levé une exception inattendue : $_" -ForegroundColor Red
    }
}

# Test 5: Créer un point d'arrêt temporisé avec une action personnalisée sans fournir de CustomAction
$totalTests++
Write-Host "`nTest 5: Créer un point d'arrêt temporisé avec une action personnalisée sans fournir de CustomAction" -ForegroundColor Cyan
try {
    # Appeler la fonction avec une action personnalisée sans CustomAction
    Set-RoadmapTimedBreakpoint -Seconds 1 -Action Custom -Message "Test de point d'arrêt temporisé"
    
    Write-Host "  Échoué : La fonction n'a pas levé d'exception pour une action personnalisée sans CustomAction." -ForegroundColor Red
} catch {
    if ($_.Exception.Message -match "CustomAction est requis") {
        Write-Host "  Réussi : La fonction a correctement levé une exception pour une action personnalisée sans CustomAction." -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  Échoué : La fonction a levé une exception inattendue : $_" -ForegroundColor Red
    }
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
