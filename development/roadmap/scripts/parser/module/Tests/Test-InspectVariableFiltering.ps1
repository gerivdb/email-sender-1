<#
.SYNOPSIS
    Tests pour le filtrage des propriÃ©tÃ©s dans la fonction Inspect-Variable.

.DESCRIPTION
    Ce script contient des tests spÃ©cifiques pour le filtrage des propriÃ©tÃ©s
    dans la fonction Inspect-Variable.

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

Write-Host "Tests de filtrage pour Inspect-Variable" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Test 1: Filtrage par nom de propriÃ©tÃ©
Write-Host "`nTest 1: Filtrage par nom de propriÃ©tÃ©" -ForegroundColor Green
$obj = [PSCustomObject]@{
    Name = "Test Object"
    ID = 12345
    Description = "This is a test object"
    CreatedDate = Get-Date
    IsActive = $true
    _InternalID = "INT-12345"
    _LastModified = Get-Date
}

Write-Host "Sans filtrage:" -ForegroundColor Yellow
Inspect-Variable -InputObject $obj -Format "Text"

Write-Host "Avec PropertyFilter (^[NI]):" -ForegroundColor Yellow
Inspect-Variable -InputObject $obj -Format "Text" -PropertyFilter "^[NI]"

Write-Host "Avec PropertyFilter (Date$):" -ForegroundColor Yellow
Inspect-Variable -InputObject $obj -Format "Text" -PropertyFilter "Date$"

# Test 2: Filtrage par type de propriÃ©tÃ©
Write-Host "`nTest 2: Filtrage par type de propriÃ©tÃ©" -ForegroundColor Green
$obj = [PSCustomObject]@{
    Name = "Test Object"
    ID = 12345
    IsActive = $true
    CreatedDate = Get-Date
    UpdatedDate = Get-Date
    Tags = @("tag1", "tag2", "tag3")
}

Write-Host "Sans filtrage:" -ForegroundColor Yellow
Inspect-Variable -InputObject $obj -Format "Text"

Write-Host "Avec TypeFilter (DateTime):" -ForegroundColor Yellow
Inspect-Variable -InputObject $obj -Format "Text" -TypeFilter "DateTime"

Write-Host "Avec TypeFilter (Int|Boolean):" -ForegroundColor Yellow
Inspect-Variable -InputObject $obj -Format "Text" -TypeFilter "Int|Boolean"

# Test 3: Filtrage des propriÃ©tÃ©s internes
Write-Host "`nTest 3: Filtrage des propriÃ©tÃ©s internes" -ForegroundColor Green
$obj = [PSCustomObject]@{
    Name = "Test Object"
    ID = 12345
    _InternalID = "INT-12345"
    _LastModified = Get-Date
    _PrivateData = @{
        Key = "Secret"
    }
}

Write-Host "Sans IncludeInternalProperties:" -ForegroundColor Yellow
Inspect-Variable -InputObject $obj -Format "Text"

Write-Host "Avec IncludeInternalProperties:" -ForegroundColor Yellow
Inspect-Variable -InputObject $obj -Format "Text" -IncludeInternalProperties

# Test 4: Combinaison de filtres
Write-Host "`nTest 4: Combinaison de filtres" -ForegroundColor Green
$obj = [PSCustomObject]@{
    Name = "Test Object"
    ID = 12345
    Description = "This is a test object"
    CreatedDate = Get-Date
    IsActive = $true
    _InternalID = "INT-12345"
    _LastModified = Get-Date
}

Write-Host "PropertyFilter (^[NI]) + TypeFilter (String):" -ForegroundColor Yellow
Inspect-Variable -InputObject $obj -Format "Text" -PropertyFilter "^[NI]" -TypeFilter "String"

Write-Host "PropertyFilter (Date$) + IncludeInternalProperties:" -ForegroundColor Yellow
Inspect-Variable -InputObject $obj -Format "Text" -PropertyFilter "Date$" -IncludeInternalProperties

Write-Host "`nTests terminÃ©s" -ForegroundColor Cyan
