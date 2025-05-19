# Script de test manuel pour la fonction New-UnifiedError
# Ce script teste manuellement la fonction sans dépendre de Pester

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

# Test 1: Création d'un objet d'erreur simple
Write-Host "=== Test 1: Création d'un objet d'erreur simple ===" -ForegroundColor Cyan
$error1 = New-UnifiedError -Message "Erreur de test simple" -Source "Test-Script"
Show-ErrorInfo -Title "Objet d'erreur simple" -ErrorObject $error1

# Test 2: Création d'un objet d'erreur avec catégorie
Write-Host "=== Test 2: Création d'un objet d'erreur avec catégorie ===" -ForegroundColor Cyan
$error2 = New-UnifiedError -Message "Fichier non trouvé" -Source "Get-File" -Category ObjectNotFound
Show-ErrorInfo -Title "Objet d'erreur avec catégorie" -ErrorObject $error2

# Test 3: Création d'un objet d'erreur avec informations supplémentaires
Write-Host "=== Test 3: Création d'un objet d'erreur avec informations supplémentaires ===" -ForegroundColor Cyan
$additionalInfo = @{
    "FilePath" = "C:\temp\test.txt"
    "FileSize" = 1024
    "LastAccess" = Get-Date
}
$error3 = New-UnifiedError -Message "Erreur lors de l'accès au fichier" -Source "Read-File" -Category ReadError -AdditionalInfo $additionalInfo
Show-ErrorInfo -Title "Objet d'erreur avec informations supplémentaires" -ErrorObject $error3

# Test 4: Création d'un objet d'erreur à partir d'un ErrorRecord existant
Write-Host "=== Test 4: Création d'un objet d'erreur à partir d'un ErrorRecord existant ===" -ForegroundColor Cyan
try {
    # Générer une erreur
    Get-Item -Path "fichier_inexistant.txt" -ErrorAction Stop
} catch {
    # Créer un objet d'erreur à partir de l'ErrorRecord
    $error4 = New-UnifiedError -ErrorRecord $_ -Source "Test-ErrorRecord"
    Show-ErrorInfo -Title "Objet d'erreur à partir d'un ErrorRecord" -ErrorObject $error4
}

# Test 5: Utilisation de WriteError
Write-Host "=== Test 5: Utilisation de WriteError ===" -ForegroundColor Cyan
try {
    $error5 = New-UnifiedError -Message "Erreur à écrire dans le flux d'erreur" -Source "Test-WriteError" -WriteError -ErrorAction SilentlyContinue
    Write-Host "Objet d'erreur retourné même avec WriteError:" -ForegroundColor Yellow
    Write-Host "Id: $($error5.Id)" -ForegroundColor Yellow
    Write-Host "Message: $($error5.Message)" -ForegroundColor Yellow
} catch {
    Write-Host "Une exception a été levée: $_" -ForegroundColor Red
}

# Test 6: Utilisation de ThrowError
Write-Host "=== Test 6: Utilisation de ThrowError ===" -ForegroundColor Cyan
try {
    $error6 = New-UnifiedError -Message "Erreur à lancer comme exception" -Source "Test-ThrowError" -ThrowError
    Write-Host "Ce code ne devrait pas être exécuté" -ForegroundColor Red
} catch {
    Write-Host "Exception capturée comme prévu:" -ForegroundColor Green
    Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Type: $($_.Exception.GetType().FullName)" -ForegroundColor Yellow
}

# Test 7: Utilisation de WriteError et ThrowError ensemble
Write-Host "=== Test 7: Utilisation de WriteError et ThrowError ensemble ===" -ForegroundColor Cyan
try {
    $error7 = New-UnifiedError -Message "Erreur à écrire et à lancer" -Source "Test-WriteThrowError" -WriteError -ThrowError -ErrorAction SilentlyContinue
    Write-Host "Ce code ne devrait pas être exécuté" -ForegroundColor Red
} catch {
    Write-Host "Exception capturée comme prévu:" -ForegroundColor Green
    Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Type: $($_.Exception.GetType().FullName)" -ForegroundColor Yellow
}

Write-Host "Tests manuels terminés." -ForegroundColor Cyan
