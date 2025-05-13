#Requires -Version 5.1
<#
.SYNOPSIS
    Test complet pour le module PowerShellDocumentationValidator.
.DESCRIPTION
    Ce script teste les fonctionnalités du module PowerShellDocumentationValidator
    avec un fichier qui respecte toutes les règles de documentation.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

[CmdletBinding()]
param()

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\PowerShellDocumentationValidator.psm1'
Import-Module -Name $modulePath -Force

# Créer un fichier de test complet
$tempFile = Join-Path -Path $PSScriptRoot -ChildPath 'CompleteTestFile.ps1'

$fileContent = @'
<#
.SYNOPSIS
    Module de test pour le validateur de documentation.
.DESCRIPTION
    Ce module contient des fonctions de test pour valider le fonctionnement
    du validateur de documentation PowerShell. Il sert d'exemple de documentation
    complète et conforme aux standards du projet.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-05-15
#>

<#
.SYNOPSIS
    Fonction de test avec documentation complète.
.DESCRIPTION
    Cette fonction est utilisée pour tester le validateur de documentation
    avec une documentation complète incluant tous les éléments requis.
    Elle montre comment documenter correctement une fonction PowerShell.
.PARAMETER Parameter1
    Premier paramètre de type string. Ce paramètre est obligatoire et doit
    contenir une chaîne de caractères non vide.
.PARAMETER Parameter2
    Deuxième paramètre de type int. Ce paramètre est facultatif et a une 
    valeur par défaut de 0. Les valeurs valides sont entre 0 et 100.
.EXAMPLE
    Test-Function -Parameter1 "Test" -Parameter2 42
    
    Exécute la fonction avec les paramètres spécifiés et retourne "Test: Test, 42".
.EXAMPLE
    Test-Function -Parameter1 "Test"
    
    Exécute la fonction avec seulement le premier paramètre et retourne "Test: Test, 0".
.OUTPUTS
    System.String
    Cette fonction retourne une chaîne de caractères formatée.
.NOTES
    Cette fonction est un exemple de documentation complète conforme aux
    standards du projet EMAIL_SENDER_1.
#>
function Test-Function {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Parameter1,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [int]$Parameter2 = 0
    )
    
    # Traitement de la fonction
    $result = "Test: $Parameter1, $Parameter2"
    
    # Retourner le résultat
    return $result
}
'@

$fileContent | Out-File -FilePath $tempFile -Encoding utf8

# Tester le validateur
Write-Host "Test du validateur de documentation avec un fichier complet..." -ForegroundColor Cyan
$results = Test-PowerShellDocumentation -Path $tempFile

# Afficher les résultats
Write-Host "Résultats de la validation :" -ForegroundColor Yellow
if ($results.Count -eq 0) {
    Write-Host "Aucun problème détecté. La documentation est conforme aux standards." -ForegroundColor Green
}
else {
    $results | Format-Table -Property Rule, Line, Severity, Message -AutoSize
}

# Nettoyer les fichiers temporaires
if (Test-Path -Path $tempFile) {
    Remove-Item -Path $tempFile -Force
    Write-Verbose "Fichier temporaire supprimé : $tempFile"
}

Write-Host "Test terminé." -ForegroundColor Yellow
