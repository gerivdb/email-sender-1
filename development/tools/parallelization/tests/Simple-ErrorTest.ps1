# Test simple pour la fonction New-UnifiedError

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Test 1: Création d'un objet d'erreur simple
Write-Host "Test 1: Création d'un objet d'erreur simple" -ForegroundColor Cyan
$error1 = New-UnifiedError -Message "Erreur de test simple" -Source "Test-Script"
Write-Host "Id: $($error1.Id)" -ForegroundColor Yellow
Write-Host "Message: $($error1.Message)" -ForegroundColor Yellow
Write-Host "Source: $($error1.Source)" -ForegroundColor Yellow

# Test 2: Utilisation de WriteError
Write-Host "`nTest 2: Utilisation de WriteError" -ForegroundColor Cyan
try {
    $error2 = New-UnifiedError -Message "Erreur à écrire dans le flux d'erreur" -Source "Test-WriteError" -WriteError -ErrorAction SilentlyContinue
    Write-Host "Objet d'erreur retourné même avec WriteError:" -ForegroundColor Yellow
    Write-Host "Id: $($error2.Id)" -ForegroundColor Yellow
    Write-Host "Message: $($error2.Message)" -ForegroundColor Yellow
} catch {
    Write-Host "Une exception a été levée: $_" -ForegroundColor Red
}

# Test 3: Utilisation de ThrowError
Write-Host "`nTest 3: Utilisation de ThrowError" -ForegroundColor Cyan
try {
    $error3 = New-UnifiedError -Message "Erreur à lancer comme exception" -Source "Test-ThrowError" -ThrowError
    Write-Host "Ce code ne devrait pas être exécuté" -ForegroundColor Red
} catch {
    Write-Host "Exception capturée comme prévu:" -ForegroundColor Green
    Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`nTests terminés." -ForegroundColor Cyan
