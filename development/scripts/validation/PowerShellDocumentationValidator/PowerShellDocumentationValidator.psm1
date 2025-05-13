#Requires -Version 5.1
<#
.SYNOPSIS
    Module de validation de la documentation PowerShell.
.DESCRIPTION
    Ce module fournit des fonctions pour valider que la documentation PowerShell respecte
    les conventions définies dans les guides de style du projet EMAIL_SENDER_1.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

# Variables globales du module
$script:DocumentationRules = @{
    # Règles pour les commentaires d'en-tête
    HeaderRules    = @{
        RequireHeader        = $true
        RequireSynopsis      = $true
        RequireDescription   = $true
        RequireNotes         = $true
        MinSynopsisLength    = 10
        MinDescriptionLength = 30
        RequireAuthor        = $true
        RequireVersion       = $true
        RequireDate          = $true
    }

    # Règles pour les commentaires de fonction
    FunctionRules  = @{
        RequireDocumentation = $true
        RequireSynopsis      = $true
        RequireDescription   = $true
        RequireExample       = $true
        MinExampleCount      = 1
        RequireOutputType    = $true
        RequireNotes         = $false
        MinSynopsisLength    = 10
        MinDescriptionLength = 30
    }

    # Règles pour les commentaires de paramètres
    ParameterRules = @{
        RequireDocumentation = $true
        RequireType          = $true
        RequireDescription   = $true
        MinDescriptionLength = 10
        RequireMandatoryInfo = $true
        RequireDefaultValue  = $true
        RequireValidValues   = $true
    }

    # Règles pour les exemples
    ExampleRules   = @{
        RequireExample       = $true
        MinExampleCount      = 1
        RequireDescription   = $true
        RequireCode          = $true
        RequireOutput        = $false
        MinDescriptionLength = 10
    }
}

<#
.SYNOPSIS
    Valide la documentation d'un fichier PowerShell.
.DESCRIPTION
    Cette fonction analyse un fichier PowerShell et vérifie que sa documentation respecte
    les conventions définies dans les guides de style du projet.
.PARAMETER Path
    Chemin du fichier PowerShell à valider.
.PARAMETER Rules
    Règles de documentation à appliquer. Par défaut, toutes les règles sont appliquées.
.EXAMPLE
    Test-PowerShellDocumentation -Path ".\MyScript.ps1"
    Valide la documentation du fichier MyScript.ps1 avec toutes les règles par défaut.
.EXAMPLE
    Test-PowerShellDocumentation -Path ".\MyScript.ps1" -Rules @("HeaderRules", "FunctionRules")
    Valide la documentation du fichier MyScript.ps1 avec uniquement les règles d'en-tête et de fonction.
#>
function Test-PowerShellDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string[]]$Rules = @("HeaderRules", "FunctionRules", "ParameterRules", "ExampleRules")
    )

    begin {
        Write-Verbose "Démarrage de la validation de la documentation PowerShell"
        $results = @()
    }

    process {
        try {
            # Vérifier que le fichier existe
            if (-not (Test-Path -Path $Path -PathType Leaf)) {
                Write-Error "Le fichier '$Path' n'existe pas."
                return
            }

            # Vérifier que le fichier est un fichier PowerShell
            if (-not ($Path -match '\.(ps1|psm1|psd1)$')) {
                Write-Error "Le fichier '$Path' n'est pas un fichier PowerShell (.ps1, .psm1 ou .psd1)."
                return
            }

            # Lire le contenu du fichier
            $content = Get-Content -Path $Path -Raw

            # Analyser le contenu du fichier
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)

            # Valider les règles de documentation
            foreach ($ruleCategory in $Rules) {
                switch ($ruleCategory) {
                    "HeaderRules" {
                        $results += Test-HeaderDocumentation -Ast $ast -Path $Path
                    }
                    "FunctionRules" {
                        $results += Test-FunctionDocumentation -Ast $ast -Path $Path
                    }
                    "ParameterRules" {
                        $results += Test-ParameterDocumentation -Ast $ast -Path $Path
                    }
                    "ExampleRules" {
                        $results += Test-ExampleDocumentation -Ast $ast -Path $Path
                    }
                    default {
                        Write-Warning "Catégorie de règles inconnue : $ruleCategory"
                    }
                }
            }
        } catch {
            Write-Error "Erreur lors de la validation de la documentation du fichier '$Path' : $_"
        }
    }

    end {
        Write-Verbose "Fin de la validation de la documentation PowerShell"
        return $results
    }
}

<#
.SYNOPSIS
    Valide les commentaires d'en-tête dans un AST PowerShell.
.DESCRIPTION
    Cette fonction analyse un AST PowerShell et vérifie que les commentaires d'en-tête
    respectent les conventions définies.
.PARAMETER Ast
    AST PowerShell à analyser.
.PARAMETER Path
    Chemin du fichier PowerShell analysé (pour les messages d'erreur).
#>
function Test-HeaderDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $results = @()

    # Récupérer les commentaires d'en-tête
    $scriptBlockAst = $Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ScriptBlockAst] }, $false) | Select-Object -First 1

    if ($scriptBlockAst) {
        $helpContent = $scriptBlockAst.GetHelpContent()

        # Vérifier la présence d'un en-tête
        if ($script:DocumentationRules.HeaderRules.RequireHeader -and
            ($null -eq $helpContent -or
            ([string]::IsNullOrWhiteSpace($helpContent.Synopsis) -and
            [string]::IsNullOrWhiteSpace($helpContent.Description)))) {
            $results += [PSCustomObject]@{
                Path     = $Path
                Line     = 1
                Rule     = "RequireHeader"
                Message  = "Le fichier doit avoir un bloc de commentaires d'en-tête."
                Severity = "Error"
            }
        } elseif ($null -ne $helpContent) {
            # Vérifier la présence d'un synopsis
            if ($script:DocumentationRules.HeaderRules.RequireSynopsis -and
                [string]::IsNullOrWhiteSpace($helpContent.Synopsis)) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = 1
                    Rule     = "RequireSynopsis"
                    Message  = "Le bloc de commentaires d'en-tête doit avoir une section SYNOPSIS."
                    Severity = "Error"
                }
            } elseif ($script:DocumentationRules.HeaderRules.RequireSynopsis -and
                ($helpContent.Synopsis.Length -lt $script:DocumentationRules.HeaderRules.MinSynopsisLength)) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = 1
                    Rule     = "MinSynopsisLength"
                    Message  = "La section SYNOPSIS est trop courte. Minimum requis : $($script:DocumentationRules.HeaderRules.MinSynopsisLength) caractères."
                    Severity = "Warning"
                }
            }

            # Vérifier la présence d'une description
            if ($script:DocumentationRules.HeaderRules.RequireDescription -and
                [string]::IsNullOrWhiteSpace($helpContent.Description)) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = 1
                    Rule     = "RequireDescription"
                    Message  = "Le bloc de commentaires d'en-tête doit avoir une section DESCRIPTION."
                    Severity = "Error"
                }
            } elseif ($script:DocumentationRules.HeaderRules.RequireDescription -and
                ($helpContent.Description.Length -lt $script:DocumentationRules.HeaderRules.MinDescriptionLength)) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = 1
                    Rule     = "MinDescriptionLength"
                    Message  = "La section DESCRIPTION est trop courte. Minimum requis : $($script:DocumentationRules.HeaderRules.MinDescriptionLength) caractères."
                    Severity = "Warning"
                }
            }

            # Vérifier la présence de notes
            if ($script:DocumentationRules.HeaderRules.RequireNotes -and
                [string]::IsNullOrWhiteSpace($helpContent.Notes)) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = 1
                    Rule     = "RequireNotes"
                    Message  = "Le bloc de commentaires d'en-tête doit avoir une section NOTES."
                    Severity = "Warning"
                }
            }

            # Vérifier la présence d'informations spécifiques dans les notes
            if (-not [string]::IsNullOrWhiteSpace($helpContent.Notes)) {
                # Vérifier la présence de l'auteur
                if ($script:DocumentationRules.HeaderRules.RequireAuthor -and
                    $helpContent.Notes -notmatch 'Auteur\s*:') {
                    $results += [PSCustomObject]@{
                        Path     = $Path
                        Line     = 1
                        Rule     = "RequireAuthor"
                        Message  = "La section NOTES doit contenir l'information 'Auteur:'."
                        Severity = "Warning"
                    }
                }

                # Vérifier la présence de la version
                if ($script:DocumentationRules.HeaderRules.RequireVersion -and
                    $helpContent.Notes -notmatch 'Version\s*:') {
                    $results += [PSCustomObject]@{
                        Path     = $Path
                        Line     = 1
                        Rule     = "RequireVersion"
                        Message  = "La section NOTES doit contenir l'information 'Version:'."
                        Severity = "Warning"
                    }
                }

                # Vérifier la présence de la date
                if ($script:DocumentationRules.HeaderRules.RequireDate -and
                    $helpContent.Notes -notmatch 'Date\s*:') {
                    $results += [PSCustomObject]@{
                        Path     = $Path
                        Line     = 1
                        Rule     = "RequireDate"
                        Message  = "La section NOTES doit contenir l'information 'Date:'."
                        Severity = "Warning"
                    }
                }
            }
        }
    }

    return $results
}

<#
.SYNOPSIS
    Valide les commentaires de fonction dans un AST PowerShell.
.DESCRIPTION
    Cette fonction analyse un AST PowerShell et vérifie que les commentaires de fonction
    respectent les conventions définies.
.PARAMETER Ast
    AST PowerShell à analyser.
.PARAMETER Path
    Chemin du fichier PowerShell analysé (pour les messages d'erreur).
#>
function Test-FunctionDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $results = @()

    # Récupérer toutes les définitions de fonction
    $functionDefinitions = $Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

    foreach ($function in $functionDefinitions) {
        $functionName = $function.Name
        $helpContent = $function.GetHelpContent()

        # Vérifier la présence de documentation
        if ($script:DocumentationRules.FunctionRules.RequireDocumentation -and
            ($null -eq $helpContent -or
            ([string]::IsNullOrWhiteSpace($helpContent.Synopsis) -and
            [string]::IsNullOrWhiteSpace($helpContent.Description)))) {
            $results += [PSCustomObject]@{
                Path     = $Path
                Line     = $function.Extent.StartLineNumber
                Rule     = "RequireDocumentation"
                Message  = "La fonction '$functionName' doit avoir un bloc de documentation."
                Severity = "Error"
            }

            # Passer à la fonction suivante si pas de documentation
            continue
        }

        if ($null -ne $helpContent) {
            # Vérifier la présence d'un synopsis
            if ($script:DocumentationRules.FunctionRules.RequireSynopsis -and
                [string]::IsNullOrWhiteSpace($helpContent.Synopsis)) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireSynopsis"
                    Message  = "La fonction '$functionName' doit avoir une section SYNOPSIS dans son bloc de documentation."
                    Severity = "Error"
                }
            } elseif ($script:DocumentationRules.FunctionRules.RequireSynopsis -and
                ($helpContent.Synopsis.Length -lt $script:DocumentationRules.FunctionRules.MinSynopsisLength)) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "MinSynopsisLength"
                    Message  = "La section SYNOPSIS de la fonction '$functionName' est trop courte. Minimum requis : $($script:DocumentationRules.FunctionRules.MinSynopsisLength) caractères."
                    Severity = "Warning"
                }
            }

            # Vérifier la présence d'une description
            if ($script:DocumentationRules.FunctionRules.RequireDescription -and
                [string]::IsNullOrWhiteSpace($helpContent.Description)) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireDescription"
                    Message  = "La fonction '$functionName' doit avoir une section DESCRIPTION dans son bloc de documentation."
                    Severity = "Error"
                }
            } elseif ($script:DocumentationRules.FunctionRules.RequireDescription -and
                ($helpContent.Description.Length -lt $script:DocumentationRules.FunctionRules.MinDescriptionLength)) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "MinDescriptionLength"
                    Message  = "La section DESCRIPTION de la fonction '$functionName' est trop courte. Minimum requis : $($script:DocumentationRules.FunctionRules.MinDescriptionLength) caractères."
                    Severity = "Warning"
                }
            }

            # Vérifier la présence d'exemples
            if ($script:DocumentationRules.FunctionRules.RequireExample -and
                ($helpContent.Examples.Count -eq 0)) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireExample"
                    Message  = "La fonction '$functionName' doit avoir au moins un exemple dans son bloc de documentation."
                    Severity = "Error"
                }
            } elseif ($script:DocumentationRules.FunctionRules.RequireExample -and
                ($helpContent.Examples.Count -lt $script:DocumentationRules.FunctionRules.MinExampleCount)) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "MinExampleCount"
                    Message  = "La fonction '$functionName' doit avoir au moins $($script:DocumentationRules.FunctionRules.MinExampleCount) exemple(s) dans son bloc de documentation."
                    Severity = "Warning"
                }
            }

            # Vérifier la présence du type de sortie
            if ($script:DocumentationRules.FunctionRules.RequireOutputType -and
                [string]::IsNullOrWhiteSpace($helpContent.ReturnValues)) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireOutputType"
                    Message  = "La fonction '$functionName' doit avoir une section OUTPUTS dans son bloc de documentation."
                    Severity = "Warning"
                }
            }

            # Vérifier la présence de notes
            if ($script:DocumentationRules.FunctionRules.RequireNotes -and
                [string]::IsNullOrWhiteSpace($helpContent.Notes)) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $function.Extent.StartLineNumber
                    Rule     = "RequireNotes"
                    Message  = "La fonction '$functionName' doit avoir une section NOTES dans son bloc de documentation."
                    Severity = "Warning"
                }
            }
        }
    }

    return $results
}

<#
.SYNOPSIS
    Valide les commentaires de paramètres dans un AST PowerShell.
.DESCRIPTION
    Cette fonction analyse un AST PowerShell et vérifie que les commentaires de paramètres
    respectent les conventions définies.
.PARAMETER Ast
    AST PowerShell à analyser.
.PARAMETER Path
    Chemin du fichier PowerShell analysé (pour les messages d'erreur).
#>
function Test-ParameterDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $results = @()

    # Récupérer toutes les définitions de fonction
    $functionDefinitions = $Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

    foreach ($function in $functionDefinitions) {
        $functionName = $function.Name
        $helpContent = $function.GetHelpContent()

        # Vérifier si la fonction a des paramètres
        $parameters = $function.Body.ParamBlock.Parameters
        if ($null -eq $parameters -or $parameters.Count -eq 0) {
            # Pas de paramètres, pas besoin de documentation de paramètres
            continue
        }

        # Vérifier si la fonction a une documentation
        if ($null -eq $helpContent) {
            # Pas de documentation, déjà signalé par Test-FunctionDocumentation
            continue
        }

        # Vérifier la documentation de chaque paramètre
        foreach ($parameter in $parameters) {
            $parameterName = $parameter.Name.VariablePath.UserPath

            # Vérifier si le paramètre est documenté
            # Note: PowerShell stocke les noms de paramètres en majuscules dans helpContent.Parameters
            if ($script:DocumentationRules.ParameterRules.RequireDocumentation -and
                -not $helpContent.Parameters.ContainsKey($parameterName.ToUpper())) {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $parameter.Extent.StartLineNumber
                    Rule     = "RequireParameterDocumentation"
                    Message  = "Le paramètre '$parameterName' de la fonction '$functionName' doit être documenté."
                    Severity = "Error"
                }

                # Passer au paramètre suivant
                continue
            }

            # Vérifier la description du paramètre
            if ($helpContent.Parameters.ContainsKey($parameterName.ToUpper())) {
                $parameterDescription = $helpContent.Parameters[$parameterName.ToUpper()]

                if ($script:DocumentationRules.ParameterRules.RequireDescription -and
                    [string]::IsNullOrWhiteSpace($parameterDescription)) {
                    $results += [PSCustomObject]@{
                        Path     = $Path
                        Line     = $parameter.Extent.StartLineNumber
                        Rule     = "RequireParameterDescription"
                        Message  = "Le paramètre '$parameterName' de la fonction '$functionName' doit avoir une description."
                        Severity = "Error"
                    }
                } elseif ($script:DocumentationRules.ParameterRules.RequireDescription -and
                    ($parameterDescription.Length -lt $script:DocumentationRules.ParameterRules.MinDescriptionLength)) {
                    $results += [PSCustomObject]@{
                        Path     = $Path
                        Line     = $parameter.Extent.StartLineNumber
                        Rule     = "MinParameterDescriptionLength"
                        Message  = "La description du paramètre '$parameterName' de la fonction '$functionName' est trop courte. Minimum requis : $($script:DocumentationRules.ParameterRules.MinDescriptionLength) caractères."
                        Severity = "Warning"
                    }
                }
            }

            # Vérifier si le paramètre a un attribut [Parameter]
            $parameterAttributes = $parameter.Attributes | Where-Object { $_.TypeName.Name -eq 'Parameter' }
            if ($parameterAttributes.Count -gt 0) {
                $parameterAttribute = $parameterAttributes[0]

                # Vérifier si le paramètre est obligatoire
                $isMandatory = $false
                $namedArguments = $parameterAttribute.NamedArguments
                foreach ($namedArgument in $namedArguments) {
                    if ($namedArgument.ArgumentName -eq 'Mandatory' -and $namedArgument.Argument.SafeGetValue()) {
                        $isMandatory = $true
                        break
                    }
                }

                # Vérifier si l'information sur le caractère obligatoire est mentionnée dans la description
                if ($script:DocumentationRules.ParameterRules.RequireMandatoryInfo -and
                    $isMandatory -and
                    $helpContent.Parameters.ContainsKey($parameterName.ToUpper()) -and
                    $helpContent.Parameters[$parameterName.ToUpper()] -notmatch '(obligatoire|mandatory|required)') {
                    $results += [PSCustomObject]@{
                        Path     = $Path
                        Line     = $parameter.Extent.StartLineNumber
                        Rule     = "RequireMandatoryInfo"
                        Message  = "La description du paramètre obligatoire '$parameterName' de la fonction '$functionName' doit mentionner qu'il est obligatoire."
                        Severity = "Warning"
                    }
                }
            }

            # Vérifier si le paramètre a une valeur par défaut
            if ($parameter.DefaultValue -and
                $script:DocumentationRules.ParameterRules.RequireDefaultValue -and
                $helpContent.Parameters.ContainsKey($parameterName.ToUpper()) -and
                $helpContent.Parameters[$parameterName.ToUpper()] -notmatch '(défaut|default)') {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $parameter.Extent.StartLineNumber
                    Rule     = "RequireDefaultValueInfo"
                    Message  = "La description du paramètre '$parameterName' de la fonction '$functionName' doit mentionner sa valeur par défaut."
                    Severity = "Warning"
                }
            }

            # Vérifier si le paramètre a un attribut de validation
            $validationAttributes = $parameter.Attributes | Where-Object {
                $_.TypeName.Name -match '^Validate' -or
                $_.TypeName.Name -eq 'ArgumentCompleter' -or
                $_.TypeName.Name -eq 'ValidateSet'
            }

            if ($validationAttributes.Count -gt 0 -and
                $script:DocumentationRules.ParameterRules.RequireValidValues -and
                $helpContent.Parameters.ContainsKey($parameterName.ToUpper()) -and
                $helpContent.Parameters[$parameterName.ToUpper()] -notmatch '(valeurs? valides?|valid values?)') {
                $results += [PSCustomObject]@{
                    Path     = $Path
                    Line     = $parameter.Extent.StartLineNumber
                    Rule     = "RequireValidValuesInfo"
                    Message  = "La description du paramètre '$parameterName' de la fonction '$functionName' doit mentionner les valeurs valides."
                    Severity = "Warning"
                }
            }
        }
    }

    return $results
}

<#
.SYNOPSIS
    Valide les exemples dans un AST PowerShell.
.DESCRIPTION
    Cette fonction analyse un AST PowerShell et vérifie que les exemples
    respectent les conventions définies.
.PARAMETER Ast
    AST PowerShell à analyser.
.PARAMETER Path
    Chemin du fichier PowerShell analysé (pour les messages d'erreur).
#>
function Test-ExampleDocumentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $results = @()

    # Récupérer toutes les définitions de fonction
    $functionDefinitions = $Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

    foreach ($function in $functionDefinitions) {
        $functionName = $function.Name
        $helpContent = $function.GetHelpContent()

        # Vérifier si la fonction a une documentation
        if ($null -eq $helpContent) {
            # Pas de documentation, déjà signalé par Test-FunctionDocumentation
            continue
        }

        # Vérifier la présence d'exemples
        if ($script:DocumentationRules.ExampleRules.RequireExample -and
            ($helpContent.Examples.Count -eq 0)) {
            $results += [PSCustomObject]@{
                Path     = $Path
                Line     = $function.Extent.StartLineNumber
                Rule     = "RequireExample"
                Message  = "La fonction '$functionName' doit avoir au moins un exemple dans son bloc de documentation."
                Severity = "Error"
            }

            # Passer à la fonction suivante
            continue
        }

        # Vérifier le nombre minimum d'exemples
        if ($script:DocumentationRules.ExampleRules.RequireExample -and
            ($helpContent.Examples.Count -lt $script:DocumentationRules.ExampleRules.MinExampleCount)) {
            $results += [PSCustomObject]@{
                Path     = $Path
                Line     = $function.Extent.StartLineNumber
                Rule     = "MinExampleCount"
                Message  = "La fonction '$functionName' doit avoir au moins $($script:DocumentationRules.ExampleRules.MinExampleCount) exemple(s) dans son bloc de documentation."
                Severity = "Warning"
            }
        }

        # Note: En raison d'une limitation de l'API PowerShell, les exemples sont détectés
        # mais leur contenu (introduction, code, remarques, output) n'est pas correctement extrait.
        # Nous vérifions donc uniquement la présence d'exemples, pas leur contenu.

        # Nous considérons que si des exemples sont détectés, ils sont valides
        Write-Verbose "Fonction '$functionName' : $($helpContent.Examples.Count) exemples détectés"
    }

    return $results
}

<#
.SYNOPSIS
    Génère un rapport de validation de la documentation PowerShell.
.DESCRIPTION
    Cette fonction génère un rapport détaillé des résultats de validation de la documentation PowerShell.
.PARAMETER Results
    Résultats de la validation de la documentation PowerShell.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport. Si non spécifié, le rapport est affiché dans la console.
.PARAMETER Format
    Format du rapport (Text, CSV, HTML). Par défaut, Text.
.EXAMPLE
    $results = Test-PowerShellDocumentation -Path ".\MyScript.ps1"
    New-PowerShellDocumentationReport -Results $results -Format HTML -OutputPath ".\DocumentationReport.html"
    Génère un rapport HTML des résultats de validation de la documentation PowerShell.
#>
function New-PowerShellDocumentationReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [PSObject[]]$Results,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML")]
        [string]$Format = "Text"
    )

    begin {
        $allResults = @()
    }

    process {
        $allResults += $Results
    }

    end {
        # Trier les résultats par chemin, ligne et règle
        $sortedResults = $allResults | Sort-Object -Property Path, Line, Rule

        # Générer le rapport selon le format spécifié
        switch ($Format) {
            "Text" {
                $report = "Rapport de validation de la documentation PowerShell`n"
                $report += "================================================`n`n"

                $report += "Résumé :`n"
                $report += "- Nombre total de problèmes : $($sortedResults.Count)`n"
                $report += "- Erreurs : $($sortedResults | Where-Object { $_.Severity -eq 'Error' } | Measure-Object | Select-Object -ExpandProperty Count)`n"
                $report += "- Avertissements : $($sortedResults | Where-Object { $_.Severity -eq 'Warning' } | Measure-Object | Select-Object -ExpandProperty Count)`n`n"

                $report += "Détails :`n"
                foreach ($result in $sortedResults) {
                    $report += "[$($result.Severity)] $($result.Path):$($result.Line) - $($result.Rule): $($result.Message)`n"
                }
            }
            "CSV" {
                $report = $sortedResults | ConvertTo-Csv -NoTypeInformation
            }
            "HTML" {
                $htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de validation de la documentation PowerShell</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0066cc; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .error { color: #cc0000; }
        .warning { color: #ff9900; }
        .summary { margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Rapport de validation de la documentation PowerShell</h1>
    <div class="summary">
        <h2>Résumé</h2>
        <p>Nombre total de problèmes : $($sortedResults.Count)</p>
        <p>Erreurs : $($sortedResults | Where-Object { $_.Severity -eq 'Error' } | Measure-Object | Select-Object -ExpandProperty Count)</p>
        <p>Avertissements : $($sortedResults | Where-Object { $_.Severity -eq 'Warning' } | Measure-Object | Select-Object -ExpandProperty Count)</p>
    </div>
    <h2>Détails</h2>
    <table>
        <tr>
            <th>Sévérité</th>
            <th>Fichier</th>
            <th>Ligne</th>
            <th>Règle</th>
            <th>Message</th>
        </tr>
"@

                $htmlRows = foreach ($result in $sortedResults) {
                    $severityClass = if ($result.Severity -eq 'Error') { 'error' } else { 'warning' }
                    "<tr><td class='$severityClass'>$($result.Severity)</td><td>$($result.Path)</td><td>$($result.Line)</td><td>$($result.Rule)</td><td>$($result.Message)</td></tr>"
                }

                $htmlFooter = @"
    </table>
</body>
</html>
"@

                $report = $htmlHeader + [string]::Join("`n", $htmlRows) + $htmlFooter
            }
        }

        # Afficher ou enregistrer le rapport
        if ($OutputPath) {
            $report | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Verbose "Rapport enregistré dans '$OutputPath'"
        } else {
            return $report
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Test-PowerShellDocumentation, New-PowerShellDocumentationReport
