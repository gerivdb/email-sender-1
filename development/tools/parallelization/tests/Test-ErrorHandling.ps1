# Script de test manuel pour la gestion des erreurs
# Ce script teste manuellement la gestion des erreurs dans le module UnifiedParallel

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Fonction pour afficher les informations d'un objet d'erreur
function Show-ErrorInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ErrorObject
    )
    
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host "Id: $($ErrorObject.Id)" -ForegroundColor Yellow
    Write-Host "Message: $($ErrorObject.Message)" -ForegroundColor Yellow
    Write-Host "Source: $($ErrorObject.Source)" -ForegroundColor Yellow
    Write-Host "Timestamp: $($ErrorObject.Timestamp)" -ForegroundColor Yellow
    Write-Host "PSVersion: $($ErrorObject.PSVersion)" -ForegroundColor Yellow
    Write-Host "Category: $($ErrorObject.Category)" -ForegroundColor Yellow
    Write-Host "Exception Type: $($ErrorObject.Exception.GetType().FullName)" -ForegroundColor Yellow
    Write-Host "Exception Message: $($ErrorObject.Exception.Message)" -ForegroundColor Yellow
    Write-Host "ErrorRecord: $($ErrorObject.ErrorRecord)" -ForegroundColor Yellow
    Write-Host "CorrelationId: $($ErrorObject.CorrelationId)" -ForegroundColor Yellow
    
    if ($ErrorObject.AdditionalInfo.Count -gt 0) {
        Write-Host "AdditionalInfo:" -ForegroundColor Yellow
        foreach ($key in $ErrorObject.AdditionalInfo.Keys) {
            Write-Host "  $key : $($ErrorObject.AdditionalInfo[$key])" -ForegroundColor Yellow
        }
    }
    
    Write-Host "CallStack:" -ForegroundColor Yellow
    foreach ($frame in $ErrorObject.CallStack) {
        Write-Host "  $($frame.FunctionName) - $($frame.ScriptName):$($frame.ScriptLineNumber)" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# Test 1: Initialisation du module avec un chemin de log invalide
Write-Host "=== Test 1: Initialisation du module avec un chemin de log invalide ===" -ForegroundColor Cyan
try {
    # Créer un chemin invalide (contenant des caractères interdits)
    $invalidPath = "Z:\*?<>|"
    
    # Initialiser le module avec ce chemin
    Initialize-UnifiedParallel -LogPath $invalidPath -ErrorAction SilentlyContinue
    
    Write-Host "Aucune erreur n'a été levée, ce qui est inattendu." -ForegroundColor Red
} catch {
    Write-Host "Erreur capturée comme prévu:" -ForegroundColor Green
    Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test 2: Exécution parallèle avec un script block qui génère une erreur
Write-Host "=== Test 2: Exécution parallèle avec un script block qui génère une erreur ===" -ForegroundColor Cyan
try {
    # Définir un script block qui génère une erreur
    $scriptBlock = {
        param($item)
        if ($item % 2 -eq 0) {
            throw "Erreur pour l'élément $item (nombre pair)"
        }
        return "Succès pour l'élément $item (nombre impair)"
    }
    
    # Exécuter le script block en parallèle avec IgnoreErrors
    $results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject (1..5) -IgnoreErrors
    
    Write-Host "Résultats obtenus avec IgnoreErrors:" -ForegroundColor Green
    foreach ($result in $results) {
        if ($result.Success) {
            Write-Host "  Succès: $($result.Value)" -ForegroundColor Green
        } else {
            Write-Host "  Erreur: $($result.Error.Exception.Message)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "Erreur inattendue: $_" -ForegroundColor Red
}

# Test 3: Exécution parallèle sans IgnoreErrors
Write-Host "=== Test 3: Exécution parallèle sans IgnoreErrors ===" -ForegroundColor Cyan
try {
    # Définir un script block qui génère une erreur
    $scriptBlock = {
        param($item)
        if ($item % 2 -eq 0) {
            throw "Erreur pour l'élément $item (nombre pair)"
        }
        return "Succès pour l'élément $item (nombre impair)"
    }
    
    # Exécuter le script block en parallèle sans IgnoreErrors
    $results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject (1..5)
    
    Write-Host "Aucune erreur n'a été levée, ce qui est inattendu." -ForegroundColor Red
} catch {
    Write-Host "Erreur capturée comme prévu:" -ForegroundColor Green
    Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test 4: Utilisation directe de New-UnifiedError
Write-Host "=== Test 4: Utilisation directe de New-UnifiedError ===" -ForegroundColor Cyan
try {
    # Créer un objet d'erreur
    $errorObject = New-UnifiedError -Message "Erreur de test" -Source "Test-ErrorHandling" -Category OperationStopped -AdditionalInfo @{
        "TestName" = "Test 4"
        "TestType" = "Direct"
    }
    
    # Afficher les informations de l'objet d'erreur
    Show-ErrorInfo -Title "Objet d'erreur créé directement" -ErrorObject $errorObject
} catch {
    Write-Host "Erreur inattendue: $_" -ForegroundColor Red
}

# Test 5: Utilisation de New-UnifiedError avec WriteError
Write-Host "=== Test 5: Utilisation de New-UnifiedError avec WriteError ===" -ForegroundColor Cyan
try {
    # Créer un objet d'erreur et l'écrire dans le flux d'erreur
    $errorObject = New-UnifiedError -Message "Erreur à écrire dans le flux d'erreur" -Source "Test-ErrorHandling" -Category InvalidOperation -WriteError -ErrorAction SilentlyContinue
    
    # Afficher les informations de l'objet d'erreur
    Show-ErrorInfo -Title "Objet d'erreur écrit dans le flux d'erreur" -ErrorObject $errorObject
} catch {
    Write-Host "Erreur inattendue: $_" -ForegroundColor Red
}

# Test 6: Utilisation de New-UnifiedError avec ThrowError
Write-Host "=== Test 6: Utilisation de New-UnifiedError avec ThrowError ===" -ForegroundColor Cyan
try {
    # Créer un objet d'erreur et le lancer comme exception
    $errorObject = New-UnifiedError -Message "Erreur à lancer comme exception" -Source "Test-ErrorHandling" -Category NotImplemented -ThrowError
    
    Write-Host "Aucune erreur n'a été levée, ce qui est inattendu." -ForegroundColor Red
} catch {
    Write-Host "Erreur capturée comme prévu:" -ForegroundColor Green
    Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "Tests manuels terminés." -ForegroundColor Cyan
