<#
.SYNOPSIS
    Test simple pour la fonction Inspect-Variable.

.DESCRIPTION
    Ce script effectue un test simple pour la fonction Inspect-Variable.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Chemin vers la fonction Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Inspect-Variable.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Inspect-Variable.ps1 est introuvable Ã  l'emplacement : $functionPath"
}

# Importer la fonction
. $functionPath

Write-Host "Test simple pour la fonction Inspect-Variable" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Test 1: ChaÃ®ne simple
$string = "Hello, World!"
Write-Host "`nTest 1: ChaÃ®ne simple" -ForegroundColor Green
Write-Host "Inspect-Variable -InputObject `$string -Format 'Text'" -ForegroundColor Yellow
Inspect-Variable -InputObject $string -Format "Text"

# Test 2: Objet avec propriÃ©tÃ©s
$obj = [PSCustomObject]@{
    Name = "Test Object"
    Value = 42
    IsActive = $true
    Date = Get-Date
    _InternalValue = "Hidden"
}

Write-Host "`nTest 2: Objet avec propriÃ©tÃ©s" -ForegroundColor Green
Write-Host "Inspect-Variable -InputObject `$obj -Format 'Text'" -ForegroundColor Yellow
Inspect-Variable -InputObject $obj -Format "Text"

Write-Host "`nTest 3: Objet avec propriÃ©tÃ©s internes" -ForegroundColor Green
Write-Host "Inspect-Variable -InputObject `$obj -Format 'Text' -IncludeInternalProperties" -ForegroundColor Yellow
Inspect-Variable -InputObject $obj -Format "Text" -IncludeInternalProperties

# Test 4: RÃ©fÃ©rence circulaire
$parent = [PSCustomObject]@{
    Name = "Parent"
}
$child = [PSCustomObject]@{
    Name = "Child"
    Parent = $parent
}
$parent | Add-Member -MemberType NoteProperty -Name "Child" -Value $child

Write-Host "`nTest 4: RÃ©fÃ©rence circulaire" -ForegroundColor Green
Write-Host "Inspect-Variable -InputObject `$parent -Format 'Text'" -ForegroundColor Yellow
Inspect-Variable -InputObject $parent -Format "Text"

Write-Host "`nTests terminÃ©s" -ForegroundColor Cyan
