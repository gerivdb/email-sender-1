# Script pour corriger l'encodage du hook d'intÃ©gration

# DÃ©finir le chemin du fichier
$filePath = Join-Path -Path $PSScriptRoot -ChildPath "TestOmnibus\hooks\ErrorPatternAnalyzer.ps1"

# DÃ©finir le contenu du fichier avec les commentaires d'aide au format reconnu par PSScriptAnalyzer
$content = @'
# Hook d'intÃ©gration avec le systÃ¨me d'analyse des patterns d'erreurs inÃ©dits

# Importer le module d'analyse des patterns d'erreur
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\maintenance\error-learning\ErrorPatternAnalyzer.psm1"
Import-Module $modulePath -Force

# Fonction pour traiter les erreurs de test
function Invoke-TestErrorProcessing {
<#
.SYNOPSIS
Traite les erreurs de test et les ajoute Ã  la base de donnÃ©es d'analyse des patterns.
.DESCRIPTION
Cette fonction prend un tableau d'erreurs de test, les convertit en objets ErrorRecord
et les ajoute Ã  la base de donnÃ©es d'analyse des patterns d'erreurs inÃ©dits.
.PARAMETER Errors
Tableau d'objets d'erreur Ã  traiter.
.EXAMPLE
Invoke-TestErrorProcessing -Errors $testErrors
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Errors
    )

    foreach ($errorItem in $Errors) {
        # CrÃ©er un objet ErrorRecord
        $exception = New-Object System.Exception $errorItem.Message
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "TestOmnibusError",
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            $null
        )

        # Ajouter des informations supplÃ©mentaires
        $errorRecord.PSObject.Properties.Add(
            (New-Object System.Management.Automation.PSNoteProperty "ScriptStackTrace", $errorItem.StackTrace)
        )

        # Ajouter l'erreur Ã  la base de donnÃ©es
        Add-ErrorRecord -ErrorRecord $errorRecord -Source $errorItem.Source
    }
}

# Exporter la fonction
Export-ModuleMember -Function Invoke-TestErrorProcessing
'@

# CrÃ©er un encodeur UTF-8 avec BOM
$utf8WithBom = New-Object System.Text.UTF8Encoding $true

# Ã‰crire le contenu avec le nouvel encodage
[System.IO.File]::WriteAllText($filePath, $content, $utf8WithBom)

Write-Host "Encodage corrigÃ© en UTF-8 avec BOM et commentaires d'aide ajoutÃ©s" -ForegroundColor Green
