# Script de test manuel pour la fonction Inspect-Variable

# Importer la fonction
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Inspect-Variable.ps1"

# Verifier si le fichier existe
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Inspect-Variable.ps1 est introuvable a l'emplacement : $functionPath"
}

# Importer la fonction
. $functionPath

Write-Host "Test de la fonction Inspect-Variable" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Test 1: Chaine simple
Write-Host "`nTest 1: Chaine simple" -ForegroundColor Green
$string = "Ceci est une chaine de test"
Write-Host "Variable: `$string = '$string'"
Write-Host "Resultat:"
Inspect-Variable -InputObject $string

# Test 2: Nombre
Write-Host "`nTest 2: Nombre" -ForegroundColor Green
$number = 42
Write-Host "Variable: `$number = $number"
Write-Host "Resultat:"
Inspect-Variable -InputObject $number

# Test 3: Tableau
Write-Host "`nTest 3: Tableau" -ForegroundColor Green
$array = @(1, 2, 3, "quatre", $true, (Get-Date))
Write-Host "Variable: `$array = @(1, 2, 3, 'quatre', `$true, (Get-Date))"
Write-Host "Resultat:"
Inspect-Variable -InputObject $array

# Test 4: Hashtable
Write-Host "`nTest 4: Hashtable" -ForegroundColor Green
$hash = @{
    Nom      = "Test"
    Valeur   = 42
    EstActif = $true
    Date     = Get-Date
    Tableau  = @(1, 2, 3)
}
Write-Host "Variable: `$hash = @{ Nom = 'Test'; Valeur = 42; EstActif = `$true; Date = Get-Date; Tableau = @(1, 2, 3) }"
Write-Host "Resultat:"
Inspect-Variable -InputObject $hash

# Test 5: Objet personnalise
Write-Host "`nTest 5: Objet personnalise" -ForegroundColor Green
$object = [PSCustomObject]@{
    Nom      = "Test"
    Valeur   = 42
    EstActif = $true
    Date     = Get-Date
    Tableau  = @(1, 2, 3)
    Imbrique = [PSCustomObject]@{
        Propriete = "Valeur imbriquee"
        Nombre    = 123
    }
}
Write-Host "Variable: `$object = [PSCustomObject]@{ ... }"
Write-Host "Resultat:"
Inspect-Variable -InputObject $object

# Test 6: Objet personnalise avec niveau de detail eleve
Write-Host "`nTest 6: Objet personnalise avec niveau de detail eleve" -ForegroundColor Green
Write-Host "Variable: `$object (meme que precedemment)"
Write-Host "Resultat avec DetailLevel = Detailed:"
Inspect-Variable -InputObject $object -DetailLevel Detailed

# Test 7: Objet personnalise avec niveau de detail bas
Write-Host "`nTest 7: Objet personnalise avec niveau de detail bas" -ForegroundColor Green
Write-Host "Variable: `$object (meme que precedemment)"
Write-Host "Resultat avec DetailLevel = Basic:"
Inspect-Variable -InputObject $object -DetailLevel Basic

# Test 8: Objet personnalise au format JSON
Write-Host "`nTest 8: Objet personnalise au format JSON" -ForegroundColor Green
Write-Host "Variable: `$object (meme que precedemment)"
Write-Host "Resultat avec Format = JSON:"
Inspect-Variable -InputObject $object -Format JSON

# Test 9: Processus (objet complexe du systeme)
Write-Host "`nTest 9: Processus (objet complexe du systeme)" -ForegroundColor Green
$process = Get-Process -Id $PID
Write-Host "Variable: `$process = Get-Process -Id `$PID"
Write-Host "Resultat:"
Inspect-Variable -InputObject $process

# Test 10: Valeur null
Write-Host "`nTest 10: Valeur null" -ForegroundColor Green
$null = $null
Write-Host "Variable: `$null"
Write-Host "Resultat:"
Inspect-Variable -InputObject $null

Write-Host "`nTests termines" -ForegroundColor Cyan
