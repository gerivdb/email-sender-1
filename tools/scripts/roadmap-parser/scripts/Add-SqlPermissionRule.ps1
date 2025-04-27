# Add-SqlPermissionRule.ps1
# Script pour ajouter une nouvelle rÃ¨gle de dÃ©tection d'anomalies SQL Server

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidatePattern("^(SVR|DB|OBJ)-\d{3}$")]
    [string]$RuleId,

    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Description,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Server", "Database", "Object")]
    [string]$RuleType,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Ã‰levÃ©e", "Moyenne", "Faible")]
    [string]$Severity,

    [Parameter(Mandatory = $true)]
    [string]$CheckFunctionPath
)

begin {
    # Chemin du module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module" -Resolve
    $rulesFilePath = Join-Path -Path $modulePath -ChildPath "Functions\Private\SqlPermissionRules.ps1"

    # VÃ©rifier que le fichier de rÃ¨gles existe
    if (-not (Test-Path -Path $rulesFilePath)) {
        throw "Le fichier de rÃ¨gles n'existe pas: $rulesFilePath"
    }

    # VÃ©rifier que le fichier de fonction de vÃ©rification existe
    if (-not (Test-Path -Path $CheckFunctionPath)) {
        throw "Le fichier de fonction de vÃ©rification n'existe pas: $CheckFunctionPath"
    }

    # Lire le contenu du fichier de rÃ¨gles
    $rulesContent = Get-Content -Path $rulesFilePath -Raw

    # VÃ©rifier si la rÃ¨gle existe dÃ©jÃ 
    if ($rulesContent -match [regex]::Escape("RuleId = `"$RuleId`"")) {
        throw "La rÃ¨gle avec l'ID '$RuleId' existe dÃ©jÃ  dans le fichier de rÃ¨gles."
    }

    # Lire le contenu du fichier de fonction de vÃ©rification
    $checkFunctionContent = Get-Content -Path $CheckFunctionPath -Raw
}

process {
    # DÃ©terminer oÃ¹ insÃ©rer la nouvelle rÃ¨gle
    $ruleTypeSection = switch ($RuleType) {
        "Server" { "# RÃ¨gles au niveau serveur" }
        "Database" { "# RÃ¨gles au niveau base de donnÃ©es" }
        "Object" { "# RÃ¨gles au niveau objet" }
    }

    # Trouver la position d'insertion
    $ruleTypeSectionPos = $rulesContent.IndexOf($ruleTypeSection)
    if ($ruleTypeSectionPos -eq -1) {
        throw "Section de type de rÃ¨gle '$ruleTypeSection' non trouvÃ©e dans le fichier de rÃ¨gles."
    }

    # Trouver la fin de la section
    $nextSectionPos = $rulesContent.IndexOf("elseif", $ruleTypeSectionPos)
    if ($nextSectionPos -eq -1) {
        $nextSectionPos = $rulesContent.IndexOf("# Filtrer par sÃ©vÃ©ritÃ©", $ruleTypeSectionPos)
    }

    # Trouver la position d'insertion exacte (avant la derniÃ¨re accolade de la section)
    $insertPos = $rulesContent.LastIndexOf("}", $nextSectionPos)
    if ($insertPos -eq -1) {
        throw "Position d'insertion non trouvÃ©e dans le fichier de rÃ¨gles."
    }

    # CrÃ©er le contenu de la nouvelle rÃ¨gle
    $newRuleContent = @"
            [PSCustomObject]@{
                RuleId = "$RuleId"
                Name = "$Name"
                Description = "$Description"
                Severity = "$Severity"
                RuleType = "$RuleType"
                CheckFunction = {
$checkFunctionContent
                }
            },

"@

    # InsÃ©rer la nouvelle rÃ¨gle dans le contenu
    $newRulesContent = $rulesContent.Substring(0, $insertPos) + $newRuleContent + $rulesContent.Substring($insertPos)

    # Ã‰crire le nouveau contenu dans le fichier de rÃ¨gles
    if ($PSCmdlet.ShouldProcess($rulesFilePath, "Ajouter la rÃ¨gle $RuleId")) {
        Set-Content -Path $rulesFilePath -Value $newRulesContent -Encoding UTF8
        Write-Host "La rÃ¨gle '$RuleId' a Ã©tÃ© ajoutÃ©e avec succÃ¨s au fichier de rÃ¨gles." -ForegroundColor Green
    }
}

end {
    # Mettre Ã  jour la documentation
    $docsFilePath = Join-Path -Path $PSScriptRoot -ChildPath "..\docs\SqlPermissionRules.md"
    if (Test-Path -Path $docsFilePath) {
        $docsContent = Get-Content -Path $docsFilePath -Raw

        # DÃ©terminer la section de documentation Ã  mettre Ã  jour
        $docsSectionHeader = switch ($RuleType) {
            "Server" { "### RÃ¨gles au niveau serveur" }
            "Database" { "### RÃ¨gles au niveau base de donnÃ©es" }
            "Object" { "### RÃ¨gles au niveau objet" }
        }

        # Trouver la position d'insertion dans la documentation
        $docsSectionPos = $docsContent.IndexOf($docsSectionHeader)
        if ($docsSectionPos -ne -1) {
            $docsSectionEndPos = $docsContent.IndexOf("###", $docsSectionPos + $docsSectionHeader.Length)
            if ($docsSectionEndPos -eq -1) {
                $docsSectionEndPos = $docsContent.Length
            }

            # Trouver la table dans la section
            $tableStartPos = $docsContent.IndexOf("|", $docsSectionPos)
            $tableEndPos = $docsContent.IndexOf("", $tableStartPos)
            if ($tableEndPos -eq -1 || $tableEndPos > $docsSectionEndPos) {
                $tableEndPos = $docsSectionEndPos
            }

            # CrÃ©er la nouvelle ligne de table
            $newTableRow = "| $RuleId | $Name | $Description | $Severity |`r`n"

            # InsÃ©rer la nouvelle ligne dans la table
            $newDocsContent = $docsContent.Substring(0, $tableEndPos) + $newTableRow + $docsContent.Substring($tableEndPos)

            # Ã‰crire le nouveau contenu dans le fichier de documentation
            if ($PSCmdlet.ShouldProcess($docsFilePath, "Mettre Ã  jour la documentation pour la rÃ¨gle $RuleId")) {
                Set-Content -Path $docsFilePath -Value $newDocsContent -Encoding UTF8
                Write-Host "La documentation a Ã©tÃ© mise Ã  jour avec succÃ¨s pour la rÃ¨gle '$RuleId'." -ForegroundColor Green
            }
        }
        else {
            Write-Warning "Section de documentation '$docsSectionHeader' non trouvÃ©e. La documentation n'a pas Ã©tÃ© mise Ã  jour."
        }
    }
    else {
        Write-Warning "Fichier de documentation non trouvÃ©: $docsFilePath. La documentation n'a pas Ã©tÃ© mise Ã  jour."
    }
}
