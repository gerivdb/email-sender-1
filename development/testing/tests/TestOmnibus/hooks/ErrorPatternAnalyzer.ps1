# Hook d'intÃ©gration avec le systÃ¨me d'analyse des patterns d'erreurs inÃ©dits

# Importer le module d'analyse des patterns d'erreur
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\maintenance\error-learning\ErrorPatternAnalyzer.psm1"
Import-Module $modulePath -Force

# Fonction pour traiter les erreurs de test
function Invoke-TestErrorProcessing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Errors
    )

    foreach ($error in $Errors) {
        # CrÃ©er un objet ErrorRecord
        $exception = New-Object System.Exception $error.Message
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "TestOmnibusError",
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            $null
        )

        # Ajouter des informations supplÃ©mentaires
        $errorRecord.PSObject.Properties.Add(
            (New-Object System.Management.Automation.PSNoteProperty "ScriptStackTrace", $error.StackTrace)
        )

        # Ajouter l'erreur Ã  la base de donnÃ©es
        Add-ErrorRecord -ErrorRecord $errorRecord -Source $error.Source
    }
}

# Exporter la fonction
Export-ModuleMember -Function Invoke-TestErrorProcessing
