# Add-SqlPermissionRule.ps1
# Script pour ajouter une nouvelle règle de détection d'anomalies SQL Server

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
    [ValidateSet("Élevée", "Moyenne", "Faible")]
    [string]$Severity,

    [Parameter(Mandatory = $true)]
    [string]$CheckFunctionPath
)

begin {
    # Chemin du module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module" -Resolve
    $rulesFilePath = Join-Path -Path $modulePath -ChildPath "Functions\Private\SqlPermissionRules.ps1"

    # Vérifier que le fichier de règles existe
    if (-not (Test-Path -Path $rulesFilePath)) {
        throw "Le fichier de règles n'existe pas: $rulesFilePath"
    }

    # Vérifier que le fichier de fonction de vérification existe
    if (-not (Test-Path -Path $CheckFunctionPath)) {
        throw "Le fichier de fonction de vérification n'existe pas: $CheckFunctionPath"
    }

    # Lire le contenu du fichier de règles
    $rulesContent = Get-Content -Path $rulesFilePath -Raw

    # Vérifier si la règle existe déjà
    if ($rulesContent -match [regex]::Escape("RuleId = `"$RuleId`"")) {
        throw "La règle avec l'ID '$RuleId' existe déjà dans le fichier de règles."
    }

    # Lire le contenu du fichier de fonction de vérification
    $checkFunctionContent = Get-Content -Path $CheckFunctionPath -Raw
}

process {
    # Déterminer où insérer la nouvelle règle
    $ruleTypeSection = switch ($RuleType) {
        "Server" { "# Règles au niveau serveur" }
        "Database" { "# Règles au niveau base de données" }
        "Object" { "# Règles au niveau objet" }
    }

    # Trouver la position d'insertion
    $ruleTypeSectionPos = $rulesContent.IndexOf($ruleTypeSection)
    if ($ruleTypeSectionPos -eq -1) {
        throw "Section de type de règle '$ruleTypeSection' non trouvée dans le fichier de règles."
    }

    # Trouver la fin de la section
    $nextSectionPos = $rulesContent.IndexOf("elseif", $ruleTypeSectionPos)
    if ($nextSectionPos -eq -1) {
        $nextSectionPos = $rulesContent.IndexOf("# Filtrer par sévérité", $ruleTypeSectionPos)
    }

    # Trouver la position d'insertion exacte (avant la dernière accolade de la section)
    $insertPos = $rulesContent.LastIndexOf("}", $nextSectionPos)
    if ($insertPos -eq -1) {
        throw "Position d'insertion non trouvée dans le fichier de règles."
    }

    # Créer le contenu de la nouvelle règle
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

    # Insérer la nouvelle règle dans le contenu
    $newRulesContent = $rulesContent.Substring(0, $insertPos) + $newRuleContent + $rulesContent.Substring($insertPos)

    # Écrire le nouveau contenu dans le fichier de règles
    if ($PSCmdlet.ShouldProcess($rulesFilePath, "Ajouter la règle $RuleId")) {
        Set-Content -Path $rulesFilePath -Value $newRulesContent -Encoding UTF8
        Write-Host "La règle '$RuleId' a été ajoutée avec succès au fichier de règles." -ForegroundColor Green
    }
}

end {
    # Mettre à jour la documentation
    $docsFilePath = Join-Path -Path $PSScriptRoot -ChildPath "..\docs\SqlPermissionRules.md"
    if (Test-Path -Path $docsFilePath) {
        $docsContent = Get-Content -Path $docsFilePath -Raw

        # Déterminer la section de documentation à mettre à jour
        $docsSectionHeader = switch ($RuleType) {
            "Server" { "### Règles au niveau serveur" }
            "Database" { "### Règles au niveau base de données" }
            "Object" { "### Règles au niveau objet" }
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

            # Créer la nouvelle ligne de table
            $newTableRow = "| $RuleId | $Name | $Description | $Severity |`r`n"

            # Insérer la nouvelle ligne dans la table
            $newDocsContent = $docsContent.Substring(0, $tableEndPos) + $newTableRow + $docsContent.Substring($tableEndPos)

            # Écrire le nouveau contenu dans le fichier de documentation
            if ($PSCmdlet.ShouldProcess($docsFilePath, "Mettre à jour la documentation pour la règle $RuleId")) {
                Set-Content -Path $docsFilePath -Value $newDocsContent -Encoding UTF8
                Write-Host "La documentation a été mise à jour avec succès pour la règle '$RuleId'." -ForegroundColor Green
            }
        }
        else {
            Write-Warning "Section de documentation '$docsSectionHeader' non trouvée. La documentation n'a pas été mise à jour."
        }
    }
    else {
        Write-Warning "Fichier de documentation non trouvé: $docsFilePath. La documentation n'a pas été mise à jour."
    }
}
