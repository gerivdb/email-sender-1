<#
.SYNOPSIS
    Tests pour les références circulaires dans la fonction Inspect-Variable.

.DESCRIPTION
    Ce script contient des tests spécifiques pour la détection et la gestion des références circulaires
    dans la fonction Inspect-Variable.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Chemin vers la fonction à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Inspect-Variable.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Inspect-Variable.ps1 est introuvable à l'emplacement : $functionPath"
}

# Importer la fonction
. $functionPath

Write-Host "Tests de références circulaires pour Inspect-Variable" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

# Test 1: Référence circulaire simple
Write-Host "`nTest 1: Référence circulaire simple" -ForegroundColor Green
$parent = [PSCustomObject]@{
    Name = "Parent"
}
$child = [PSCustomObject]@{
    Name = "Child"
    Parent = $parent
}
$parent | Add-Member -MemberType NoteProperty -Name "Child" -Value $child

Write-Host "CircularReferenceHandling=Mark:" -ForegroundColor Yellow
Inspect-Variable -InputObject $parent -Format "Text" -CircularReferenceHandling "Mark"

Write-Host "CircularReferenceHandling=Ignore:" -ForegroundColor Yellow
Inspect-Variable -InputObject $parent -Format "Text" -CircularReferenceHandling "Ignore"

Write-Host "DetectCircularReferences=`$false:" -ForegroundColor Yellow
Inspect-Variable -InputObject $parent -Format "Text" -DetectCircularReferences $false

# Test 2: Références circulaires complexes
Write-Host "`nTest 2: Références circulaires complexes" -ForegroundColor Green
$company = [PSCustomObject]@{
    Name = "ACME Corp"
    Departments = @()
}

$hr = [PSCustomObject]@{
    Name = "Human Resources"
    Company = $company
    Employees = @()
}

$it = [PSCustomObject]@{
    Name = "IT Department"
    Company = $company
    Employees = @()
}

$company.Departments = @($hr, $it)

$employee1 = [PSCustomObject]@{
    Name = "John Doe"
    Department = $hr
    Manager = $null
}

$employee2 = [PSCustomObject]@{
    Name = "Jane Smith"
    Department = $hr
    Manager = $employee1
}

$employee3 = [PSCustomObject]@{
    Name = "Bob Johnson"
    Department = $it
    Manager = $null
}

$hr.Employees = @($employee1, $employee2)
$it.Employees = @($employee3)
$employee1 | Add-Member -MemberType NoteProperty -Name "Subordinates" -Value @($employee2)

Write-Host "CircularReferenceHandling=Mark:" -ForegroundColor Yellow
Inspect-Variable -InputObject $company -Format "Text" -CircularReferenceHandling "Mark" -MaxDepth 5

Write-Host "CircularReferenceHandling=Ignore:" -ForegroundColor Yellow
Inspect-Variable -InputObject $company -Format "Text" -CircularReferenceHandling "Ignore" -MaxDepth 5

# Test 3: Référence circulaire avec filtrage
Write-Host "`nTest 3: Référence circulaire avec filtrage" -ForegroundColor Green
Write-Host "PropertyFilter='Name|Employees' et CircularReferenceHandling=Mark:" -ForegroundColor Yellow
Inspect-Variable -InputObject $company -Format "Text" -PropertyFilter "Name|Employees" -CircularReferenceHandling "Mark" -MaxDepth 5

# Test 4: Référence circulaire avec exception
Write-Host "`nTest 4: Référence circulaire avec exception" -ForegroundColor Green
Write-Host "CircularReferenceHandling=Throw:" -ForegroundColor Yellow
try {
    Inspect-Variable -InputObject $company -Format "Text" -CircularReferenceHandling "Throw" -MaxDepth 5
    Write-Host "ERREUR: L'exception n'a pas été levée!" -ForegroundColor Red
} catch {
    Write-Host "Exception levée comme prévu: $_" -ForegroundColor Green
}

Write-Host "`nTests terminés" -ForegroundColor Cyan
