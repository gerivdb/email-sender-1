#Requires -Version 5.1
<#
.SYNOPSIS
    Module pour la dÃ©tection des modules requis implicitement dans les scripts PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions pour dÃ©tecter les modules requis implicitement dans les scripts PowerShell,
    notamment les appels de cmdlets sans import explicite, les types .NET spÃ©cifiques Ã  des modules,
    et les variables globales spÃ©cifiques Ã  des modules.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-12-15
#>

#region Private Functions

# Base de donnÃ©es de correspondance entre cmdlets et modules
$script:CmdletToModuleMapping = @{
    # Active Directory
    "Get-ADUser"             = "ActiveDirectory"
    "Set-ADUser"             = "ActiveDirectory"
    "New-ADUser"             = "ActiveDirectory"
    "Remove-ADUser"          = "ActiveDirectory"
    "Get-ADGroup"            = "ActiveDirectory"
    "Add-ADGroupMember"      = "ActiveDirectory"

    # Azure
    "Get-AzVM"               = "Az.Compute"
    "New-AzVM"               = "Az.Compute"
    "Start-AzVM"             = "Az.Compute"
    "Stop-AzVM"              = "Az.Compute"
    "Get-AzResource"         = "Az.Resources"

    # SQL Server
    "Invoke-Sqlcmd"          = "SqlServer"
    "Get-SqlDatabase"        = "SqlServer"
    "Backup-SqlDatabase"     = "SqlServer"

    # Pester
    "Describe"               = "Pester"
    "Context"                = "Pester"
    "It"                     = "Pester"
    "Should"                 = "Pester"
    "Mock"                   = "Pester"

    # PSScriptAnalyzer
    "Invoke-ScriptAnalyzer"  = "PSScriptAnalyzer"
    "Get-ScriptAnalyzerRule" = "PSScriptAnalyzer"

    # Dbatools
    "Get-DbaDatabase"        = "dbatools"
    "Backup-DbaDatabase"     = "dbatools"
    "Invoke-DbaQuery"        = "dbatools"

    # ImportExcel
    "Export-Excel"           = "ImportExcel"
    "Import-Excel"           = "ImportExcel"
    "New-ExcelChart"         = "ImportExcel"
}

# Base de donnÃ©es de correspondance entre types .NET et modules
$script:TypeToModuleMapping = @{
    # Active Directory
    "Microsoft.ActiveDirectory.Management.ADUser"                          = "ActiveDirectory"
    "Microsoft.ActiveDirectory.Management.ADGroup"                         = "ActiveDirectory"
    "Microsoft.ActiveDirectory.Management.ADPrincipal"                     = "ActiveDirectory"
    "Microsoft.ActiveDirectory.Management.ADObject"                        = "ActiveDirectory"

    # Azure
    "Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine"             = "Az.Compute"
    "Microsoft.Azure.Commands.Compute.Models.PSVirtualMachineSize"         = "Az.Compute"
    "Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork"             = "Az.Network"
    "Microsoft.Azure.Commands.Network.Models.PSNetworkInterface"           = "Az.Network"
    "Microsoft.Azure.Commands.Resources.Models.PSResource"                 = "Az.Resources"

    # SQL Server
    "Microsoft.SqlServer.Management.Smo.Server"                            = "SqlServer"
    "Microsoft.SqlServer.Management.Smo.Database"                          = "SqlServer"
    "Microsoft.SqlServer.Management.Smo.Table"                             = "SqlServer"
    "Microsoft.SqlServer.Management.Smo.StoredProcedure"                   = "SqlServer"

    # Pester
    "Pester.Runtime.PesterConfiguration"                                   = "Pester"
    "Pester.Runtime.TestResult"                                            = "Pester"
    "Pester.Runtime.Context"                                               = "Pester"

    # PSScriptAnalyzer
    "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" = "PSScriptAnalyzer"
    "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.RuleSeverity"     = "PSScriptAnalyzer"

    # Dbatools
    "Sqlcollaborative.Dbatools.Database.BackupHistory"                     = "dbatools"
    "Sqlcollaborative.Dbatools.Computer.DbaCmsRegServerStore"              = "dbatools"
    "Sqlcollaborative.Dbatools.Parameter.DbaInstanceParameter"             = "dbatools"

    # ImportExcel
    "OfficeOpenXml.ExcelPackage"                                           = "ImportExcel"
    "OfficeOpenXml.ExcelWorksheet"                                         = "ImportExcel"
    "OfficeOpenXml.ExcelRange"                                             = "ImportExcel"
    "OfficeOpenXml.Drawing.Chart.ExcelChart"                               = "ImportExcel"
}

# Base de donnÃ©es de correspondance entre variables globales et modules
$script:GlobalVariableToModuleMapping = @{
    # PowerShell Core
    "PSVersionTable"                = "Microsoft.PowerShell.Core"
    "PSEdition"                     = "Microsoft.PowerShell.Core"
    "PSCommandPath"                 = "Microsoft.PowerShell.Core"
    "PSScriptRoot"                  = "Microsoft.PowerShell.Core"
    "PSBoundParameters"             = "Microsoft.PowerShell.Core"
    "MyInvocation"                  = "Microsoft.PowerShell.Core"
    "PSCmdlet"                      = "Microsoft.PowerShell.Core"
    "PSItem"                        = "Microsoft.PowerShell.Core"
    "PSModuleAutoLoadingPreference" = "Microsoft.PowerShell.Core"

    # Active Directory
    "ADServerSettings"              = "ActiveDirectory"
    "ADSessionSettings"             = "ActiveDirectory"

    # Azure
    "AzureRmContext"                = "Az.Accounts"
    "AzContext"                     = "Az.Accounts"
    "AzureRmProfile"                = "Az.Accounts"
    "AzProfile"                     = "Az.Accounts"
    "AzDefaultLocation"             = "Az.Accounts"

    # SQL Server
    "SqlServerMaximumErrorLevel"    = "SqlServer"
    "SqlServerConnectionTimeout"    = "SqlServer"

    # Pester
    "PesterPreference"              = "Pester"
    "PesterConfiguration"           = "Pester"
    "PesterState"                   = "Pester"

    # PSScriptAnalyzer
    "PSScriptAnalyzerSettings"      = "PSScriptAnalyzer"
    "PSUseConsistentIndentation"    = "PSScriptAnalyzer"
    "PSUseConsistentWhitespace"     = "PSScriptAnalyzer"

    # Dbatools
    "DbatoolsConfig"                = "dbatools"
    "DbatoolsConfigFile"            = "dbatools"
    "DbatoolsImportDate"            = "dbatools"
    "DbatoolsInstallRoot"           = "dbatools"
    "DbatoolsPath"                  = "dbatools"

    # ImportExcel
    "ExcelPackageFolder"            = "ImportExcel"
    "ExcelDefaultXlsxFormat"        = "ImportExcel"
    "ExcelDefaultNumberFormat"      = "ImportExcel"
    "ExcelDefaultDateFormat"        = "ImportExcel"
}

# Base de donnÃ©es de correspondance entre alias de modules et modules
$script:ModuleAliasToModuleMapping = @{
    # PowerShell Core
    "PSCore"   = "Microsoft.PowerShell.Core"
    "Core"     = "Microsoft.PowerShell.Core"

    # Active Directory
    "AD"       = "ActiveDirectory"

    # Azure
    "Azure"    = "Az.Accounts"
    "Az"       = "Az.Accounts"
    "AzureRM"  = "Az.Accounts"

    # SQL Server
    "SQL"      = "SqlServer"

    # Pester
    "Test"     = "Pester"

    # PSScriptAnalyzer
    "PSSA"     = "PSScriptAnalyzer"
    "Analyzer" = "PSScriptAnalyzer"

    # Dbatools
    "DBA"      = "dbatools"

    # ImportExcel
    "Excel"    = "ImportExcel"
}

# Fonction interne pour extraire les appels de cmdlets d'un AST
function Get-CmdletCallsFromAst {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast
    )

    try {
        # Trouver tous les appels de commandes dans l'AST
        $commandCalls = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst]
            }, $true)

        # Extraire les noms des cmdlets appelÃ©es
        $cmdletCalls = @()
        foreach ($call in $commandCalls) {
            if ($call.CommandElements.Count -gt 0) {
                $cmdletName = $null

                # VÃ©rifier si le premier Ã©lÃ©ment est un nom de cmdlet
                if ($call.CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                    $cmdletName = $call.CommandElements[0].Value
                }

                if ($cmdletName) {
                    $cmdletCalls += [PSCustomObject]@{
                        Name         = $cmdletName
                        LineNumber   = $call.Extent.StartLineNumber
                        ColumnNumber = $call.Extent.StartColumnNumber
                        Text         = $call.Extent.Text
                    }
                }
            }
        }

        return $cmdletCalls
    } catch {
        Write-Error "Erreur lors de l'extraction des appels de cmdlets : $_"
        return @()
    }
}

# Fonction interne pour vÃ©rifier si un module est importÃ© explicitement
function Test-ModuleImported {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    try {
        # Trouver toutes les instructions Import-Module dans l'AST
        $importModuleCalls = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.CommandElements.Count -gt 0 -and
                $node.CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
                $node.CommandElements[0].Value -eq 'Import-Module'
            }, $true)

        # VÃ©rifier si le module spÃ©cifiÃ© est importÃ©
        foreach ($call in $importModuleCalls) {
            # VÃ©rifier les paramÃ¨tres nommÃ©s
            for ($i = 1; $i -lt $call.CommandElements.Count; $i++) {
                $element = $call.CommandElements[$i]

                # VÃ©rifier si c'est un paramÃ¨tre -Name ou -Path
                if ($element -is [System.Management.Automation.Language.CommandParameterAst] -and
                    ($element.ParameterName -eq 'Name' -or $element.ParameterName -eq 'Path')) {

                    # VÃ©rifier si le paramÃ¨tre a une valeur
                    if ($i + 1 -lt $call.CommandElements.Count -and
                        -not ($call.CommandElements[$i + 1] -is [System.Management.Automation.Language.CommandParameterAst])) {

                        $paramValue = $call.CommandElements[$i + 1]

                        # Extraire la valeur du paramÃ¨tre
                        $value = $null
                        if ($paramValue -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                            $value = $paramValue.Value
                        } elseif ($paramValue -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
                            $value = $paramValue.Value
                        } else {
                            $value = $paramValue.Extent.Text
                        }

                        # VÃ©rifier si la valeur correspond au module recherchÃ©
                        if ($value -eq $ModuleName) {
                            return $true
                        }
                    }
                }
                # VÃ©rifier les paramÃ¨tres positionnels
                elseif (-not ($element -is [System.Management.Automation.Language.CommandParameterAst]) -and $i -eq 1) {
                    $value = $null
                    if ($element -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                        $value = $element.Value
                    } elseif ($element -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
                        $value = $element.Value
                    } else {
                        $value = $element.Extent.Text
                    }

                    if ($value -eq $ModuleName) {
                        return $true
                    }
                }
            }
        }

        return $false
    } catch {
        Write-Error "Erreur lors de la vÃ©rification des imports de modules : $_"
        return $false
    }
}

# Fonction interne pour extraire les rÃ©fÃ©rences aux modules dans les commentaires
function Get-ModuleReferencesFromComments {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast
    )

    try {
        # Trouver tous les commentaires dans l'AST
        $commentReferences = @()

        $commentTokens = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommentAst]
            }, $true)

        # Obtenir tous les noms de modules connus
        $knownModules = @()
        $knownModules += $script:CmdletToModuleMapping.Values | Select-Object -Unique
        $knownModules += $script:TypeToModuleMapping.Values | Select-Object -Unique
        $knownModules += $script:GlobalVariableToModuleMapping.Values | Select-Object -Unique
        $knownModules += $script:ModuleAliasToModuleMapping.Values | Select-Object -Unique
        $knownModules = $knownModules | Select-Object -Unique

        # Obtenir tous les alias de modules connus
        $knownAliases = $script:ModuleAliasToModuleMapping.Keys

        foreach ($comment in $commentTokens) {
            $commentText = $comment.Extent.Text

            # 1. Rechercher les mentions explicites de modules
            foreach ($module in $knownModules) {
                # Rechercher les mentions du module dans le commentaire
                # Utiliser une regex pour trouver le module comme mot entier
                $matchResults = [regex]::Matches($commentText, "\b$module\b")

                foreach ($match in $matchResults) {
                    $commentReferences += [PSCustomObject]@{
                        ModuleName   = $module
                        LineNumber   = $comment.Extent.StartLineNumber
                        ColumnNumber = $comment.Extent.StartColumnNumber + $match.Index
                        Text         = $match.Value
                        Source       = "Comment"
                        Type         = "ExplicitModule"
                    }
                }
            }

            # 2. Rechercher les mentions d'alias de modules
            foreach ($alias in $knownAliases) {
                # Rechercher les mentions de l'alias dans le commentaire
                # Utiliser une regex pour trouver l'alias comme mot entier
                $matchResults = [regex]::Matches($commentText, "\b$alias\b")

                foreach ($match in $matchResults) {
                    $commentReferences += [PSCustomObject]@{
                        ModuleName   = $script:ModuleAliasToModuleMapping[$alias]
                        AliasName    = $alias
                        LineNumber   = $comment.Extent.StartLineNumber
                        ColumnNumber = $comment.Extent.StartColumnNumber + $match.Index
                        Text         = $match.Value
                        Source       = "Comment"
                        Type         = "AliasModule"
                    }
                }
            }

            # 3. Rechercher les mentions de cmdlets
            foreach ($cmdlet in $script:CmdletToModuleMapping.Keys) {
                # Rechercher les mentions de la cmdlet dans le commentaire
                # Utiliser une regex pour trouver la cmdlet comme mot entier
                $matchResults = [regex]::Matches($commentText, "\b$cmdlet\b")

                foreach ($match in $matchResults) {
                    $commentReferences += [PSCustomObject]@{
                        ModuleName   = $script:CmdletToModuleMapping[$cmdlet]
                        CmdletName   = $cmdlet
                        LineNumber   = $comment.Extent.StartLineNumber
                        ColumnNumber = $comment.Extent.StartColumnNumber + $match.Index
                        Text         = $match.Value
                        Source       = "Comment"
                        Type         = "Cmdlet"
                    }
                }
            }

            # 4. Rechercher les mentions de types .NET
            foreach ($type in $script:TypeToModuleMapping.Keys) {
                # Rechercher les mentions du type dans le commentaire
                if ($commentText -like "*$type*") {
                    $matchResults = [regex]::Matches($commentText, [regex]::Escape($type))

                    foreach ($match in $matchResults) {
                        $commentReferences += [PSCustomObject]@{
                            ModuleName   = $script:TypeToModuleMapping[$type]
                            TypeName     = $type
                            LineNumber   = $comment.Extent.StartLineNumber
                            ColumnNumber = $comment.Extent.StartColumnNumber + $match.Index
                            Text         = $match.Value
                            Source       = "Comment"
                            Type         = "DotNetType"
                        }
                    }
                }
            }

            # 5. Rechercher les mentions de variables globales
            foreach ($variable in $script:GlobalVariableToModuleMapping.Keys) {
                # Rechercher les mentions de la variable dans le commentaire
                # Utiliser une regex pour trouver la variable comme mot entier
                $matchResults = [regex]::Matches($commentText, "\b\$?$variable\b")

                foreach ($match in $matchResults) {
                    $commentReferences += [PSCustomObject]@{
                        ModuleName   = $script:GlobalVariableToModuleMapping[$variable]
                        VariableName = $variable
                        LineNumber   = $comment.Extent.StartLineNumber
                        ColumnNumber = $comment.Extent.StartColumnNumber + $match.Index
                        Text         = $match.Value
                        Source       = "Comment"
                        Type         = "GlobalVariable"
                    }
                }
            }

            # 6. Rechercher les mentions de #Requires -Modules
            $requiresMatches = [regex]::Matches($commentText, "#Requires\s+-Modules?\s+([a-zA-Z0-9_\.-]+)")
            foreach ($match in $requiresMatches) {
                $moduleName = $match.Groups[1].Value
                $commentReferences += [PSCustomObject]@{
                    ModuleName   = $moduleName
                    LineNumber   = $comment.Extent.StartLineNumber
                    ColumnNumber = $comment.Extent.StartColumnNumber + $match.Index
                    Text         = $match.Value
                    Source       = "Comment"
                    Type         = "RequiresModule"
                }
            }
        }

        return $commentReferences
    } catch {
        Write-Error "Erreur lors de l'extraction des rÃ©fÃ©rences aux modules dans les commentaires : $_"
        return @()
    }
}

# Fonction interne pour extraire les rÃ©fÃ©rences aux alias de modules d'un AST
function Get-ModuleAliasReferencesFromAst {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast
    )

    try {
        # Trouver toutes les rÃ©fÃ©rences aux alias de modules dans l'AST
        $aliasReferences = @()

        # 1. Rechercher les rÃ©fÃ©rences dans les commentaires
        $commentTokens = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommentAst]
            }, $true)

        foreach ($comment in $commentTokens) {
            $commentText = $comment.Extent.Text

            # Parcourir tous les alias de modules connus
            foreach ($alias in $script:ModuleAliasToModuleMapping.Keys) {
                # Rechercher les mentions de l'alias dans le commentaire
                # Utiliser une regex pour trouver l'alias comme mot entier
                $matchResults = [regex]::Matches($commentText, "\b$alias\b")

                foreach ($match in $matchResults) {
                    $aliasReferences += [PSCustomObject]@{
                        AliasName    = $alias
                        LineNumber   = $comment.Extent.StartLineNumber
                        ColumnNumber = $comment.Extent.StartColumnNumber + $match.Index
                        Text         = $match.Value
                        Source       = "Comment"
                    }
                }
            }
        }

        # 2. Rechercher les rÃ©fÃ©rences dans les chaÃ®nes de caractÃ¨res
        $stringExpressions = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.StringConstantExpressionAst] -or
                $node -is [System.Management.Automation.Language.ExpandableStringExpressionAst]
            }, $true)

        foreach ($stringExpr in $stringExpressions) {
            $stringValue = $stringExpr.Value

            # Parcourir tous les alias de modules connus
            foreach ($alias in $script:ModuleAliasToModuleMapping.Keys) {
                # Rechercher les mentions de l'alias dans la chaÃ®ne
                # Utiliser une regex pour trouver l'alias comme mot entier
                $matchResults = [regex]::Matches($stringValue, "\b$alias\b")

                foreach ($match in $matchResults) {
                    $aliasReferences += [PSCustomObject]@{
                        AliasName    = $alias
                        LineNumber   = $stringExpr.Extent.StartLineNumber
                        ColumnNumber = $stringExpr.Extent.StartColumnNumber + $match.Index
                        Text         = $match.Value
                        Source       = "String"
                    }
                }
            }
        }

        # 3. Rechercher les rÃ©fÃ©rences dans les noms de variables (ex: $ADUser)
        $variableExpressions = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.VariableExpressionAst]
            }, $true)

        foreach ($varExpr in $variableExpressions) {
            $variableName = $varExpr.VariablePath.UserPath

            # Parcourir tous les alias de modules connus
            foreach ($alias in $script:ModuleAliasToModuleMapping.Keys) {
                # VÃ©rifier si le nom de la variable commence par l'alias
                if ($variableName -match "^$alias") {
                    $aliasReferences += [PSCustomObject]@{
                        AliasName    = $alias
                        LineNumber   = $varExpr.Extent.StartLineNumber
                        ColumnNumber = $varExpr.Extent.StartColumnNumber
                        Text         = $varExpr.Extent.Text
                        Source       = "Variable"
                    }
                }
            }
        }

        return $aliasReferences
    } catch {
        Write-Error "Erreur lors de l'extraction des rÃ©fÃ©rences aux alias de modules : $_"
        return @()
    }
}

# Fonction interne pour extraire les rÃ©fÃ©rences aux variables globales d'un AST
function Get-GlobalVariableReferencesFromAst {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast
    )

    try {
        # Trouver toutes les rÃ©fÃ©rences aux variables dans l'AST
        $variableReferences = @()

        # Rechercher les rÃ©fÃ©rences aux variables
        $variableExpressions = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.VariableExpressionAst]
            }, $true)

        foreach ($varExpr in $variableExpressions) {
            # Exclure les variables locales (celles qui commencent par $)
            # Nous ne voulons que les variables globales qui sont dÃ©finies par des modules
            if (-not [string]::IsNullOrEmpty($varExpr.VariablePath.UserPath)) {
                $variableName = $varExpr.VariablePath.UserPath

                # Ajouter la rÃ©fÃ©rence Ã  la variable
                $variableReferences += [PSCustomObject]@{
                    VariableName = $variableName
                    LineNumber   = $varExpr.Extent.StartLineNumber
                    ColumnNumber = $varExpr.Extent.StartColumnNumber
                    Text         = $varExpr.Extent.Text
                    Source       = "Direct" # RÃ©fÃ©rence directe Ã  la variable
                }
            }
        }

        # Rechercher les rÃ©fÃ©rences aux variables dans les expressions de membre
        # Par exemple: $PSVersionTable.PSVersion ou $AzContext.Subscription
        $memberExpressions = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.MemberExpressionAst] -and
                $node.Expression -is [System.Management.Automation.Language.VariableExpressionAst]
            }, $true)

        foreach ($memberExpr in $memberExpressions) {
            $varExpr = $memberExpr.Expression
            if (-not [string]::IsNullOrEmpty($varExpr.VariablePath.UserPath)) {
                $variableName = $varExpr.VariablePath.UserPath

                # Ajouter la rÃ©fÃ©rence Ã  la variable
                $variableReferences += [PSCustomObject]@{
                    VariableName = $variableName
                    LineNumber   = $memberExpr.Extent.StartLineNumber
                    ColumnNumber = $memberExpr.Extent.StartColumnNumber
                    Text         = $memberExpr.Extent.Text
                    Source       = "Member" # RÃ©fÃ©rence via une expression de membre
                    Member       = $memberExpr.Member.Value
                }
            }
        }

        # Rechercher les rÃ©fÃ©rences aux variables dans les expressions d'index
        # Par exemple: $PSVersionTable["PSVersion"] ou $AzContext["Subscription"]
        $indexExpressions = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.IndexExpressionAst] -and
                $node.Target -is [System.Management.Automation.Language.VariableExpressionAst]
            }, $true)

        foreach ($indexExpr in $indexExpressions) {
            $varExpr = $indexExpr.Target
            if (-not [string]::IsNullOrEmpty($varExpr.VariablePath.UserPath)) {
                $variableName = $varExpr.VariablePath.UserPath

                # Essayer d'extraire l'index si c'est une chaÃ®ne constante
                $indexValue = $null
                if ($indexExpr.Index -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                    $indexValue = $indexExpr.Index.Value
                }

                # Ajouter la rÃ©fÃ©rence Ã  la variable
                $variableReferences += [PSCustomObject]@{
                    VariableName = $variableName
                    LineNumber   = $indexExpr.Extent.StartLineNumber
                    ColumnNumber = $indexExpr.Extent.StartColumnNumber
                    Text         = $indexExpr.Extent.Text
                    Source       = "Index" # RÃ©fÃ©rence via une expression d'index
                    Index        = $indexValue
                }
            }
        }

        return $variableReferences
    } catch {
        Write-Error "Erreur lors de l'extraction des rÃ©fÃ©rences aux variables globales : $_"
        return @()
    }
}

# Fonction interne pour extraire les rÃ©fÃ©rences de types .NET d'un AST
function Get-DotNetTypeReferencesFromAst {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast
    )

    try {
        # Trouver toutes les rÃ©fÃ©rences de types dans l'AST
        $typeReferences = @()

        # 1. Rechercher les rÃ©fÃ©rences de types dans les expressions de type
        $typeExpressions = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.TypeExpressionAst]
            }, $true)

        foreach ($typeExpr in $typeExpressions) {
            $typeReferences += [PSCustomObject]@{
                TypeName     = $typeExpr.TypeName.FullName
                LineNumber   = $typeExpr.Extent.StartLineNumber
                ColumnNumber = $typeExpr.Extent.StartColumnNumber
                Text         = $typeExpr.Extent.Text
            }
        }

        # 2. Rechercher les rÃ©fÃ©rences de types dans les expressions [Type]::Member
        $staticMemberExpressions = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.MemberExpressionAst] -and
                $node.Expression -is [System.Management.Automation.Language.TypeExpressionAst]
            }, $true)

        foreach ($memberExpr in $staticMemberExpressions) {
            $typeExpr = $memberExpr.Expression
            $typeReferences += [PSCustomObject]@{
                TypeName     = $typeExpr.TypeName.FullName
                LineNumber   = $memberExpr.Extent.StartLineNumber
                ColumnNumber = $memberExpr.Extent.StartColumnNumber
                Text         = $memberExpr.Extent.Text
                Member       = $memberExpr.Member.Value
            }
        }

        # 3. Rechercher les rÃ©fÃ©rences de types dans les expressions de cast [Type]$var
        $conversionExpressions = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.ConvertExpressionAst]
            }, $true)

        foreach ($convExpr in $conversionExpressions) {
            $typeReferences += [PSCustomObject]@{
                TypeName     = $convExpr.Type.TypeName.FullName
                LineNumber   = $convExpr.Extent.StartLineNumber
                ColumnNumber = $convExpr.Extent.StartColumnNumber
                Text         = $convExpr.Extent.Text
            }
        }

        # 4. Rechercher les rÃ©fÃ©rences de types dans les expressions New-Object Type
        $newObjectCalls = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.CommandElements.Count -gt 0 -and
                $node.CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
                $node.CommandElements[0].Value -eq 'New-Object'
            }, $true)

        foreach ($call in $newObjectCalls) {
            # VÃ©rifier les paramÃ¨tres nommÃ©s
            $typeName = $null
            $typeNameFound = $false

            for ($i = 1; $i -lt $call.CommandElements.Count; $i++) {
                $element = $call.CommandElements[$i]

                # VÃ©rifier si c'est un paramÃ¨tre -TypeName
                if ($element -is [System.Management.Automation.Language.CommandParameterAst] -and
                    $element.ParameterName -eq 'TypeName') {

                    # VÃ©rifier si le paramÃ¨tre a une valeur
                    if ($i + 1 -lt $call.CommandElements.Count -and
                        -not ($call.CommandElements[$i + 1] -is [System.Management.Automation.Language.CommandParameterAst])) {

                        $paramValue = $call.CommandElements[$i + 1]

                        # Extraire la valeur du paramÃ¨tre
                        if ($paramValue -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                            $typeName = $paramValue.Value
                            $typeNameFound = $true
                            break
                        } elseif ($paramValue -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
                            $typeName = $paramValue.Value
                            $typeNameFound = $true
                            break
                        }
                    }
                }
                # VÃ©rifier les paramÃ¨tres positionnels
                elseif (-not ($element -is [System.Management.Automation.Language.CommandParameterAst]) -and $i -eq 1) {
                    if ($element -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                        $typeName = $element.Value
                        $typeNameFound = $true
                        break
                    } elseif ($element -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
                        $typeName = $element.Value
                        $typeNameFound = $true
                        break
                    }
                }
            }

            if ($typeNameFound -and $typeName) {
                $typeReferences += [PSCustomObject]@{
                    TypeName     = $typeName
                    LineNumber   = $call.Extent.StartLineNumber
                    ColumnNumber = $call.Extent.StartColumnNumber
                    Text         = $call.Extent.Text
                    Source       = "New-Object"
                }
            }
        }

        return $typeReferences
    } catch {
        Write-Error "Erreur lors de l'extraction des rÃ©fÃ©rences de types .NET : $_"
        return @()
    }
}

#endregion

#region Public Functions

function Find-CmdletWithoutExplicitImport {
    <#
    .SYNOPSIS
        DÃ©tecte les appels de cmdlets sans import explicite du module correspondant.

    .DESCRIPTION
        Cette fonction analyse un script PowerShell pour dÃ©tecter les appels de cmdlets
        qui nÃ©cessitent un module spÃ©cifique, mais pour lesquels le module n'est pas
        explicitement importÃ© dans le script.

    .PARAMETER FilePath
        Chemin du fichier PowerShell Ã  analyser.

    .PARAMETER ScriptContent
        Contenu du script PowerShell Ã  analyser. Si ce paramÃ¨tre est spÃ©cifiÃ©, FilePath est ignorÃ©.

    .PARAMETER IncludeImportedModules
        Indique si les cmdlets des modules dÃ©jÃ  importÃ©s doivent Ãªtre incluses dans les rÃ©sultats.
        Par dÃ©faut, seules les cmdlets des modules non importÃ©s sont retournÃ©es.

    .EXAMPLE
        Find-CmdletWithoutExplicitImport -FilePath "C:\Scripts\MyScript.ps1"

    .EXAMPLE
        $scriptContent = Get-Content -Path "C:\Scripts\MyScript.ps1" -Raw
        Find-CmdletWithoutExplicitImport -ScriptContent $scriptContent

    .OUTPUTS
        PSCustomObject[]
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByPath")]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName = "ByContent")]
        [string]$ScriptContent,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeImportedModules
    )

    try {
        # Analyser le script avec l'AST
        $tokens = $errors = $null
        $ast = $null

        if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
                Write-Error "Le fichier spÃ©cifiÃ© n'existe pas : $FilePath"
                return @()
            }

            $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont Ã©tÃ© dÃ©tectÃ©es dans le script : $($errors.Count) erreur(s)"
            }
        } else {
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont Ã©tÃ© dÃ©tectÃ©es dans le script : $($errors.Count) erreur(s)"
            }
        }

        # Extraire les appels de cmdlets
        $cmdletCalls = Get-CmdletCallsFromAst -Ast $ast

        # Identifier les modules requis pour chaque cmdlet
        $results = @()
        foreach ($call in $cmdletCalls) {
            $moduleName = $script:CmdletToModuleMapping[$call.Name]

            # VÃ©rifier si la cmdlet est dans notre base de donnÃ©es de correspondance
            if ($moduleName) {
                # VÃ©rifier si le module est importÃ© explicitement
                $isImported = Test-ModuleImported -Ast $ast -ModuleName $moduleName

                # Ajouter au rÃ©sultat si le module n'est pas importÃ© ou si on inclut tous les modules
                if (-not $isImported -or $IncludeImportedModules) {
                    $results += [PSCustomObject]@{
                        CmdletName   = $call.Name
                        ModuleName   = $moduleName
                        LineNumber   = $call.LineNumber
                        ColumnNumber = $call.ColumnNumber
                        Text         = $call.Text
                        IsImported   = $isImported
                    }
                }
            }
        }

        return $results
    } catch {
        Write-Error "Erreur lors de la dÃ©tection des cmdlets sans import explicite : $_"
        return @()
    }
}

function Find-ModuleReferenceInComments {
    <#
    .SYNOPSIS
        DÃ©tecte les rÃ©fÃ©rences Ã  des modules dans les commentaires d'un script PowerShell.

    .DESCRIPTION
        Cette fonction analyse les commentaires d'un script PowerShell pour dÃ©tecter les rÃ©fÃ©rences
        Ã  des modules, que ce soit par leur nom, leurs alias, leurs cmdlets, leurs types, ou leurs variables.
        Elle permet de dÃ©tecter les dÃ©pendances implicites mentionnÃ©es dans les commentaires.

    .PARAMETER FilePath
        Chemin du fichier PowerShell Ã  analyser.

    .PARAMETER ScriptContent
        Contenu du script PowerShell Ã  analyser. Si ce paramÃ¨tre est spÃ©cifiÃ©, FilePath est ignorÃ©.

    .PARAMETER IncludeImportedModules
        Indique si les modules dÃ©jÃ  importÃ©s doivent Ãªtre inclus dans les rÃ©sultats.
        Par dÃ©faut, seuls les modules non importÃ©s sont retournÃ©s.

    .PARAMETER IncludeRequiresDirectives
        Indique si les directives #Requires -Modules doivent Ãªtre incluses dans les rÃ©sultats.
        Par dÃ©faut, ces directives sont incluses.

    .EXAMPLE
        Find-ModuleReferenceInComments -FilePath "C:\Scripts\MyScript.ps1"

    .EXAMPLE
        $scriptContent = Get-Content -Path "C:\Scripts\MyScript.ps1" -Raw
        Find-ModuleReferenceInComments -ScriptContent $scriptContent -IncludeImportedModules

    .OUTPUTS
        PSCustomObject[]
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByPath")]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName = "ByContent")]
        [string]$ScriptContent,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeImportedModules,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeRequiresDirectives
    )

    try {
        # Analyser le script avec l'AST
        $tokens = $errors = $null
        $ast = $null

        if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
                Write-Error "Le fichier spÃ©cifiÃ© n'existe pas : $FilePath"
                return @()
            }

            $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont Ã©tÃ© dÃ©tectÃ©es dans le script : $($errors.Count) erreur(s)"
            }
        } else {
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont Ã©tÃ© dÃ©tectÃ©es dans le script : $($errors.Count) erreur(s)"
            }
        }

        # Extraire les rÃ©fÃ©rences aux modules dans les commentaires
        $commentReferences = Get-ModuleReferencesFromComments -Ast $ast

        # Filtrer les rÃ©sultats selon les paramÃ¨tres
        # Par dÃ©faut, on inclut les directives #Requires
        if (-not $IncludeRequiresDirectives.IsPresent) {
            # Ne rien faire, garder toutes les rÃ©fÃ©rences
        } else {
            # Si le paramÃ¨tre est explicitement fourni et est $false, filtrer les directives #Requires
            if (-not $IncludeRequiresDirectives) {
                $commentReferences = $commentReferences | Where-Object { $_.Type -ne "RequiresModule" }
            }
        }

        # Identifier les modules requis pour chaque rÃ©fÃ©rence
        $results = @()
        foreach ($ref in $commentReferences) {
            $moduleName = $ref.ModuleName

            # VÃ©rifier si le module est importÃ© explicitement
            $isImported = Test-ModuleImported -Ast $ast -ModuleName $moduleName

            # Ajouter au rÃ©sultat si le module n'est pas importÃ© ou si on inclut tous les modules
            if (-not $isImported -or $IncludeImportedModules) {
                $result = [PSCustomObject]@{
                    ModuleName   = $moduleName
                    LineNumber   = $ref.LineNumber
                    ColumnNumber = $ref.ColumnNumber
                    Text         = $ref.Text
                    Source       = $ref.Source
                    Type         = $ref.Type
                    IsImported   = $isImported
                }

                # Ajouter des propriÃ©tÃ©s supplÃ©mentaires si elles existent
                if ($ref.PSObject.Properties.Name -contains "AliasName") {
                    $result | Add-Member -NotePropertyName "AliasName" -NotePropertyValue $ref.AliasName
                }
                if ($ref.PSObject.Properties.Name -contains "CmdletName") {
                    $result | Add-Member -NotePropertyName "CmdletName" -NotePropertyValue $ref.CmdletName
                }
                if ($ref.PSObject.Properties.Name -contains "TypeName") {
                    $result | Add-Member -NotePropertyName "TypeName" -NotePropertyValue $ref.TypeName
                }
                if ($ref.PSObject.Properties.Name -contains "VariableName") {
                    $result | Add-Member -NotePropertyName "VariableName" -NotePropertyValue $ref.VariableName
                }

                $results += $result
            }
        }

        return $results
    } catch {
        Write-Error "Erreur lors de la dÃ©tection des rÃ©fÃ©rences aux modules dans les commentaires : $_"
        return @()
    }
}

function Find-ModuleAliasWithoutExplicitImport {
    <#
    .SYNOPSIS
        DÃ©tecte les rÃ©fÃ©rences Ã  des alias de modules sans import explicite du module correspondant.

    .DESCRIPTION
        Cette fonction analyse un script PowerShell pour dÃ©tecter les rÃ©fÃ©rences Ã  des alias de modules
        qui sont spÃ©cifiques Ã  des modules PowerShell, mais pour lesquels le module n'est pas
        explicitement importÃ© dans le script. Les rÃ©fÃ©rences peuvent Ãªtre trouvÃ©es dans les commentaires,
        les chaÃ®nes de caractÃ¨res, ou les noms de variables.

    .PARAMETER FilePath
        Chemin du fichier PowerShell Ã  analyser.

    .PARAMETER ScriptContent
        Contenu du script PowerShell Ã  analyser. Si ce paramÃ¨tre est spÃ©cifiÃ©, FilePath est ignorÃ©.

    .PARAMETER IncludeImportedModules
        Indique si les alias des modules dÃ©jÃ  importÃ©s doivent Ãªtre inclus dans les rÃ©sultats.
        Par dÃ©faut, seuls les alias des modules non importÃ©s sont retournÃ©s.

    .EXAMPLE
        Find-ModuleAliasWithoutExplicitImport -FilePath "C:\Scripts\MyScript.ps1"

    .EXAMPLE
        $scriptContent = Get-Content -Path "C:\Scripts\MyScript.ps1" -Raw
        Find-ModuleAliasWithoutExplicitImport -ScriptContent $scriptContent

    .OUTPUTS
        PSCustomObject[]
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByPath")]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName = "ByContent")]
        [string]$ScriptContent,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeImportedModules
    )

    try {
        # Analyser le script avec l'AST
        $tokens = $errors = $null
        $ast = $null

        if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
                Write-Error "Le fichier spÃ©cifiÃ© n'existe pas : $FilePath"
                return @()
            }

            $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont Ã©tÃ© dÃ©tectÃ©es dans le script : $($errors.Count) erreur(s)"
            }
        } else {
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont Ã©tÃ© dÃ©tectÃ©es dans le script : $($errors.Count) erreur(s)"
            }
        }

        # Extraire les rÃ©fÃ©rences aux alias de modules
        $aliasReferences = Get-ModuleAliasReferencesFromAst -Ast $ast

        # Identifier les modules requis pour chaque alias
        $results = @()
        foreach ($aliasRef in $aliasReferences) {
            $moduleName = $script:ModuleAliasToModuleMapping[$aliasRef.AliasName]

            # Si un module est trouvÃ© pour cet alias
            if ($moduleName) {
                # VÃ©rifier si le module est importÃ© explicitement
                $isImported = Test-ModuleImported -Ast $ast -ModuleName $moduleName

                # Ajouter au rÃ©sultat si le module n'est pas importÃ© ou si on inclut tous les modules
                if (-not $isImported -or $IncludeImportedModules) {
                    $results += [PSCustomObject]@{
                        AliasName    = $aliasRef.AliasName
                        ModuleName   = $moduleName
                        LineNumber   = $aliasRef.LineNumber
                        ColumnNumber = $aliasRef.ColumnNumber
                        Text         = $aliasRef.Text
                        Source       = $aliasRef.Source
                        IsImported   = $isImported
                    }
                }
            }
        }

        return $results
    } catch {
        Write-Error "Erreur lors de la dÃ©tection des alias de modules sans import explicite : $_"
        return @()
    }
}

function Find-DotNetTypeWithoutExplicitImport {
    <#
    .SYNOPSIS
        DÃ©tecte les rÃ©fÃ©rences Ã  des types .NET spÃ©cifiques Ã  des modules sans import explicite.

    .DESCRIPTION
        Cette fonction analyse un script PowerShell pour dÃ©tecter les rÃ©fÃ©rences Ã  des types .NET
        qui sont spÃ©cifiques Ã  des modules PowerShell, mais pour lesquels le module n'est pas
        explicitement importÃ© dans le script.

    .PARAMETER FilePath
        Chemin du fichier PowerShell Ã  analyser.

    .PARAMETER ScriptContent
        Contenu du script PowerShell Ã  analyser. Si ce paramÃ¨tre est spÃ©cifiÃ©, FilePath est ignorÃ©.

    .PARAMETER IncludeImportedModules
        Indique si les types des modules dÃ©jÃ  importÃ©s doivent Ãªtre inclus dans les rÃ©sultats.
        Par dÃ©faut, seuls les types des modules non importÃ©s sont retournÃ©s.

    .EXAMPLE
        Find-DotNetTypeWithoutExplicitImport -FilePath "C:\Scripts\MyScript.ps1"

    .EXAMPLE
        $scriptContent = Get-Content -Path "C:\Scripts\MyScript.ps1" -Raw
        Find-DotNetTypeWithoutExplicitImport -ScriptContent $scriptContent

    .OUTPUTS
        PSCustomObject[]
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByPath")]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName = "ByContent")]
        [string]$ScriptContent,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeImportedModules
    )

    try {
        # Analyser le script avec l'AST
        $tokens = $errors = $null
        $ast = $null

        if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
                Write-Error "Le fichier spÃ©cifiÃ© n'existe pas : $FilePath"
                return @()
            }

            $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont Ã©tÃ© dÃ©tectÃ©es dans le script : $($errors.Count) erreur(s)"
            }
        } else {
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont Ã©tÃ© dÃ©tectÃ©es dans le script : $($errors.Count) erreur(s)"
            }
        }

        # Extraire les rÃ©fÃ©rences de types .NET
        $typeReferences = Get-DotNetTypeReferencesFromAst -Ast $ast

        # Identifier les modules requis pour chaque type
        $results = @()
        foreach ($typeRef in $typeReferences) {
            $moduleName = $null

            # VÃ©rifier si le type est dans notre base de donnÃ©es de correspondance
            $moduleName = $script:TypeToModuleMapping[$typeRef.TypeName]

            # Si le type n'est pas trouvÃ© directement, essayer de trouver une correspondance partielle
            if (-not $moduleName) {
                foreach ($key in $script:TypeToModuleMapping.Keys) {
                    if ($typeRef.TypeName -like "$key*" -or $typeRef.TypeName -like "*.$key*") {
                        $moduleName = $script:TypeToModuleMapping[$key]
                        break
                    }
                }
            }

            # Si un module est trouvÃ© pour ce type
            if ($moduleName) {
                # VÃ©rifier si le module est importÃ© explicitement
                $isImported = Test-ModuleImported -Ast $ast -ModuleName $moduleName

                # Ajouter au rÃ©sultat si le module n'est pas importÃ© ou si on inclut tous les modules
                if (-not $isImported -or $IncludeImportedModules) {
                    $result = [PSCustomObject]@{
                        TypeName     = $typeRef.TypeName
                        ModuleName   = $moduleName
                        LineNumber   = $typeRef.LineNumber
                        ColumnNumber = $typeRef.ColumnNumber
                        Text         = $typeRef.Text
                        IsImported   = $isImported
                    }

                    # Ajouter des propriÃ©tÃ©s supplÃ©mentaires si elles existent
                    if ($typeRef.PSObject.Properties.Name -contains "Member") {
                        $result | Add-Member -NotePropertyName "Member" -NotePropertyValue $typeRef.Member
                    }
                    if ($typeRef.PSObject.Properties.Name -contains "Source") {
                        $result | Add-Member -NotePropertyName "Source" -NotePropertyValue $typeRef.Source
                    }

                    $results += $result
                }
            }
        }

        return $results
    } catch {
        Write-Error "Erreur lors de la dÃ©tection des types .NET sans import explicite : $_"
        return @()
    }
}

#endregion

function New-ModuleMappingDatabase {
    <#
    .SYNOPSIS
        CrÃ©e une base de donnÃ©es de correspondance entre cmdlets/types/variables et modules.

    .DESCRIPTION
        Cette fonction analyse les modules installÃ©s sur le systÃ¨me et crÃ©e une base de donnÃ©es
        de correspondance entre les cmdlets, types .NET et variables globales et leurs modules respectifs.
        Cette base de donnÃ©es peut Ãªtre utilisÃ©e pour dÃ©tecter les dÃ©pendances implicites dans les scripts PowerShell.

    .PARAMETER ModuleNames
        Noms des modules Ã  analyser. Si non spÃ©cifiÃ©, tous les modules disponibles seront analysÃ©s.

    .PARAMETER OutputPath
        Chemin du fichier de sortie pour la base de donnÃ©es. Si non spÃ©cifiÃ©, la base de donnÃ©es
        sera retournÃ©e sous forme d'objet PowerShell.

    .PARAMETER IncludeCmdlets
        Indique si les cmdlets doivent Ãªtre incluses dans la base de donnÃ©es.

    .PARAMETER IncludeTypes
        Indique si les types .NET doivent Ãªtre inclus dans la base de donnÃ©es.

    .PARAMETER IncludeVariables
        Indique si les variables globales doivent Ãªtre incluses dans la base de donnÃ©es.

    .EXAMPLE
        New-ModuleMappingDatabase -ModuleNames "ActiveDirectory", "SqlServer" -OutputPath "C:\Temp\ModuleMapping.psd1"

    .EXAMPLE
        $mapping = New-ModuleMappingDatabase -IncludeCmdlets -IncludeTypes

    .OUTPUTS
        System.Collections.Hashtable ou System.IO.FileInfo
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$ModuleNames,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeCmdlets = $true,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeTypes = $true,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeVariables = $true
    )

    try {
        # Initialiser les tables de correspondance
        $cmdletToModuleMapping = @{}
        $typeToModuleMapping = @{}
        $variableToModuleMapping = @{}

        # Obtenir la liste des modules Ã  analyser
        $modules = @()
        if ($ModuleNames) {
            foreach ($moduleName in $ModuleNames) {
                $module = Get-Module -Name $moduleName -ListAvailable | Select-Object -First 1
                if ($module) {
                    $modules += $module
                } else {
                    Write-Warning "Le module '$moduleName' n'a pas Ã©tÃ© trouvÃ©."
                }
            }
        } else {
            $modules = Get-Module -ListAvailable
        }

        # Analyser chaque module
        foreach ($module in $modules) {
            $moduleName = $module.Name
            Write-Verbose "Analyse du module: $moduleName"

            # Analyser les cmdlets si demandÃ©
            if ($IncludeCmdlets) {
                Write-Verbose "  Analyse des cmdlets..."
                $cmdlets = Get-Command -Module $moduleName -CommandType Cmdlet, Function, Alias -ErrorAction SilentlyContinue
                foreach ($cmdlet in $cmdlets) {
                    $cmdletName = $cmdlet.Name
                    if (-not $cmdletToModuleMapping.ContainsKey($cmdletName)) {
                        $cmdletToModuleMapping[$cmdletName] = $moduleName
                    }
                }
            }

            # Analyser les types .NET si demandÃ©
            if ($IncludeTypes) {
                Write-Verbose "  Analyse des types .NET..."
                try {
                    # Importer le module pour accÃ©der Ã  ses types
                    Import-Module $moduleName -ErrorAction SilentlyContinue

                    # Obtenir les types exportÃ©s par le module
                    $assembly = [System.AppDomain]::CurrentDomain.GetAssemblies() |
                        Where-Object { $_.GetName().Name -eq $moduleName -or $_.GetName().Name -like "$moduleName.*" }

                    if ($assembly) {
                        foreach ($type in $assembly.GetExportedTypes()) {
                            $typeName = $type.FullName
                            if (-not $typeToModuleMapping.ContainsKey($typeName)) {
                                $typeToModuleMapping[$typeName] = $moduleName
                            }
                        }
                    }
                } catch {
                    Write-Warning "Erreur lors de l'analyse des types du module '$moduleName': $_"
                }
            }

            # Analyser les variables globales si demandÃ©
            if ($IncludeVariables) {
                Write-Verbose "  Analyse des variables globales..."
                try {
                    # Importer le module pour accÃ©der Ã  ses variables
                    $beforeVars = Get-Variable -Scope Global -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
                    Import-Module $moduleName -ErrorAction SilentlyContinue
                    $afterVars = Get-Variable -Scope Global -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name

                    # Identifier les nouvelles variables introduites par le module
                    $newVars = $afterVars | Where-Object { $beforeVars -notcontains $_ }
                    foreach ($varName in $newVars) {
                        if (-not $variableToModuleMapping.ContainsKey($varName)) {
                            $variableToModuleMapping[$varName] = $moduleName
                        }
                    }
                } catch {
                    Write-Warning "Erreur lors de l'analyse des variables du module '$moduleName': $_"
                }
            }
        }

        # CrÃ©er la base de donnÃ©es complÃ¨te
        $database = @{
            CmdletToModuleMapping   = $cmdletToModuleMapping
            TypeToModuleMapping     = $typeToModuleMapping
            VariableToModuleMapping = $variableToModuleMapping
        }

        # Exporter la base de donnÃ©es si un chemin de sortie est spÃ©cifiÃ©
        if ($OutputPath) {
            $databaseContent = @"
# Base de donnÃ©es de correspondance entre cmdlets/types/variables et modules
# GÃ©nÃ©rÃ©e le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

@{
    CmdletToModuleMapping = @{
$($cmdletToModuleMapping.GetEnumerator() | ForEach-Object { "        '$($_.Key)' = '$($_.Value)'" } | Out-String)
    }

    TypeToModuleMapping = @{
$($typeToModuleMapping.GetEnumerator() | ForEach-Object { "        '$($_.Key)' = '$($_.Value)'" } | Out-String)
    }

    VariableToModuleMapping = @{
$($variableToModuleMapping.GetEnumerator() | ForEach-Object { "        '$($_.Key)' = '$($_.Value)'" } | Out-String)
    }
}
"@
            Set-Content -Path $OutputPath -Value $databaseContent -Encoding UTF8
            Get-Item -Path $OutputPath
        } else {
            # Retourner la base de donnÃ©es
            $database
        }
    } catch {
        Write-Error "Erreur lors de la crÃ©ation de la base de donnÃ©es de correspondance : $_"
        if ($OutputPath) {
            return $null
        } else {
            return @{
                CmdletToModuleMapping   = @{}
                TypeToModuleMapping     = @{}
                VariableToModuleMapping = @{}
            }
        }
    }
}

function Update-ModuleMappingDatabase {
    <#
    .SYNOPSIS
        Met Ã  jour la base de donnÃ©es de correspondance entre cmdlets/types/variables et modules.

    .DESCRIPTION
        Cette fonction met Ã  jour la base de donnÃ©es de correspondance existante avec de nouvelles
        entrÃ©es provenant des modules spÃ©cifiÃ©s.

    .PARAMETER DatabasePath
        Chemin du fichier de base de donnÃ©es Ã  mettre Ã  jour.

    .PARAMETER ModuleNames
        Noms des modules Ã  analyser. Si non spÃ©cifiÃ©, tous les modules disponibles seront analysÃ©s.

    .PARAMETER OutputPath
        Chemin du fichier de sortie pour la base de donnÃ©es mise Ã  jour. Si non spÃ©cifiÃ©, le fichier
        d'entrÃ©e sera Ã©crasÃ©.

    .PARAMETER IncludeCmdlets
        Indique si les cmdlets doivent Ãªtre incluses dans la base de donnÃ©es.

    .PARAMETER IncludeTypes
        Indique si les types .NET doivent Ãªtre inclus dans la base de donnÃ©es.

    .PARAMETER IncludeVariables
        Indique si les variables globales doivent Ãªtre incluses dans la base de donnÃ©es.

    .EXAMPLE
        Update-ModuleMappingDatabase -DatabasePath "C:\Temp\ModuleMapping.psd1" -ModuleNames "Az.Compute", "Az.Network"

    .EXAMPLE
        Update-ModuleMappingDatabase -DatabasePath "C:\Temp\ModuleMapping.psd1" -OutputPath "C:\Temp\ModuleMapping_Updated.psd1"

    .OUTPUTS
        System.IO.FileInfo
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DatabasePath,

        [Parameter(Mandatory = $false)]
        [string[]]$ModuleNames,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeCmdlets = $true,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeTypes = $true,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeVariables = $true
    )

    try {
        # VÃ©rifier si le fichier de base de donnÃ©es existe
        if (-not (Test-Path -Path $DatabasePath -PathType Leaf)) {
            Write-Error "Le fichier de base de donnÃ©es spÃ©cifiÃ© n'existe pas : $DatabasePath"
            return $null
        }

        # Charger la base de donnÃ©es existante
        $existingDatabase = & ([ScriptBlock]::Create("return $(Get-Content -Path $DatabasePath -Raw)"))

        # CrÃ©er une nouvelle base de donnÃ©es pour les modules spÃ©cifiÃ©s
        $newDatabase = New-ModuleMappingDatabase -ModuleNames $ModuleNames -IncludeCmdlets:$IncludeCmdlets -IncludeTypes:$IncludeTypes -IncludeVariables:$IncludeVariables

        # Fusionner les bases de donnÃ©es
        $mergedDatabase = @{
            CmdletToModuleMapping   = @{}
            TypeToModuleMapping     = @{}
            VariableToModuleMapping = @{}
        }

        # Fusionner les mappings de cmdlets
        foreach ($key in $existingDatabase.CmdletToModuleMapping.Keys) {
            $mergedDatabase.CmdletToModuleMapping[$key] = $existingDatabase.CmdletToModuleMapping[$key]
        }
        foreach ($key in $newDatabase.CmdletToModuleMapping.Keys) {
            $mergedDatabase.CmdletToModuleMapping[$key] = $newDatabase.CmdletToModuleMapping[$key]
        }

        # Fusionner les mappings de types
        foreach ($key in $existingDatabase.TypeToModuleMapping.Keys) {
            $mergedDatabase.TypeToModuleMapping[$key] = $existingDatabase.TypeToModuleMapping[$key]
        }
        foreach ($key in $newDatabase.TypeToModuleMapping.Keys) {
            $mergedDatabase.TypeToModuleMapping[$key] = $newDatabase.TypeToModuleMapping[$key]
        }

        # Fusionner les mappings de variables
        foreach ($key in $existingDatabase.VariableToModuleMapping.Keys) {
            $mergedDatabase.VariableToModuleMapping[$key] = $existingDatabase.VariableToModuleMapping[$key]
        }
        foreach ($key in $newDatabase.VariableToModuleMapping.Keys) {
            $mergedDatabase.VariableToModuleMapping[$key] = $newDatabase.VariableToModuleMapping[$key]
        }

        # DÃ©terminer le chemin de sortie
        $outputFilePath = if ($OutputPath) { $OutputPath } else { $DatabasePath }

        # Exporter la base de donnÃ©es fusionnÃ©e
        $databaseContent = @"
# Base de donnÃ©es de correspondance entre cmdlets/types/variables et modules
# Mise Ã  jour le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

@{
    CmdletToModuleMapping = @{
$($mergedDatabase.CmdletToModuleMapping.GetEnumerator() | ForEach-Object { "        '$($_.Key)' = '$($_.Value)'" } | Out-String)
    }

    TypeToModuleMapping = @{
$($mergedDatabase.TypeToModuleMapping.GetEnumerator() | ForEach-Object { "        '$($_.Key)' = '$($_.Value)'" } | Out-String)
    }

    VariableToModuleMapping = @{
$($mergedDatabase.VariableToModuleMapping.GetEnumerator() | ForEach-Object { "        '$($_.Key)' = '$($_.Value)'" } | Out-String)
    }
}
"@
        Set-Content -Path $outputFilePath -Value $databaseContent -Encoding UTF8
        Get-Item -Path $outputFilePath
    } catch {
        Write-Error "Erreur lors de la mise Ã  jour de la base de donnÃ©es de correspondance : $_"
        return $null
    }
}

function Import-ModuleMappingDatabase {
    <#
    .SYNOPSIS
        Importe une base de donnÃ©es de correspondance entre cmdlets/types/variables et modules.

    .DESCRIPTION
        Cette fonction importe une base de donnÃ©es de correspondance Ã  partir d'un fichier PSD1
        et met Ã  jour les variables globales du script avec les mappings importÃ©s.

    .PARAMETER DatabasePath
        Chemin du fichier de base de donnÃ©es Ã  importer.

    .PARAMETER UpdateGlobalMappings
        Indique si les mappings globaux du script doivent Ãªtre mis Ã  jour avec les mappings importÃ©s.

    .EXAMPLE
        Import-ModuleMappingDatabase -DatabasePath "C:\Temp\ModuleMapping.psd1"

    .EXAMPLE
        $database = Import-ModuleMappingDatabase -DatabasePath "C:\Temp\ModuleMapping.psd1" -UpdateGlobalMappings:$false

    .OUTPUTS
        System.Collections.Hashtable
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DatabasePath,

        [Parameter(Mandatory = $false)]
        [switch]$UpdateGlobalMappings = $true
    )

    try {
        # VÃ©rifier si le fichier de base de donnÃ©es existe
        if (-not (Test-Path -Path $DatabasePath -PathType Leaf)) {
            Write-Error "Le fichier de base de donnÃ©es spÃ©cifiÃ© n'existe pas : $DatabasePath"
            return $null
        }

        # Charger la base de donnÃ©es
        $database = & ([ScriptBlock]::Create("return $(Get-Content -Path $DatabasePath -Raw)"))

        # Mettre Ã  jour les mappings globaux si demandÃ©
        if ($UpdateGlobalMappings) {
            # Mettre Ã  jour le mapping de cmdlets
            $script:CmdletToModuleMapping = $database.CmdletToModuleMapping

            # Mettre Ã  jour le mapping de types
            $script:TypeToModuleMapping = $database.TypeToModuleMapping

            # Mettre Ã  jour le mapping de variables
            $script:GlobalVariableToModuleMapping = $database.VariableToModuleMapping
        }

        # Retourner la base de donnÃ©es
        $database
    } catch {
        Write-Error "Erreur lors de l'importation de la base de donnÃ©es de correspondance : $_"
        return $null
    }
}

function Get-ModuleDependencyScore {
    <#
    .SYNOPSIS
        Calcule un score de probabilitÃ© pour les dÃ©pendances de modules dÃ©tectÃ©es.

    .DESCRIPTION
        Cette fonction analyse les rÃ©sultats des fonctions de dÃ©tection de dÃ©pendances
        et calcule un score de probabilitÃ© pour chaque module dÃ©tectÃ©, en fonction
        de diffÃ©rents critÃ¨res comme le nombre de rÃ©fÃ©rences, le type de rÃ©fÃ©rences,
        et la prÃ©sence d'autres modules du mÃªme fournisseur.

    .PARAMETER CmdletReferences
        RÃ©sultats de la fonction Find-CmdletWithoutExplicitImport.

    .PARAMETER TypeReferences
        RÃ©sultats de la fonction Find-DotNetTypeWithoutExplicitImport.

    .PARAMETER VariableReferences
        RÃ©sultats de la fonction Find-GlobalVariableWithoutExplicitImport.

    .PARAMETER AliasReferences
        RÃ©sultats de la fonction Find-ModuleAliasWithoutExplicitImport.

    .PARAMETER CommentReferences
        RÃ©sultats de la fonction Find-ModuleReferenceInComments.

    .PARAMETER ScoreThreshold
        Seuil de score Ã  partir duquel une dÃ©pendance est considÃ©rÃ©e comme probable.
        Par dÃ©faut, ce seuil est fixÃ© Ã  0.5 (50%).

    .PARAMETER IncludeDetails
        Indique si les dÃ©tails du calcul du score doivent Ãªtre inclus dans les rÃ©sultats.

    .EXAMPLE
        $cmdlets = Find-CmdletWithoutExplicitImport -FilePath "C:\Scripts\MyScript.ps1"
        $types = Find-DotNetTypeWithoutExplicitImport -FilePath "C:\Scripts\MyScript.ps1"
        $variables = Find-GlobalVariableWithoutExplicitImport -FilePath "C:\Scripts\MyScript.ps1"
        $aliases = Find-ModuleAliasWithoutExplicitImport -FilePath "C:\Scripts\MyScript.ps1"
        $comments = Find-ModuleReferenceInComments -FilePath "C:\Scripts\MyScript.ps1"
        Get-ModuleDependencyScore -CmdletReferences $cmdlets -TypeReferences $types -VariableReferences $variables -AliasReferences $aliases -CommentReferences $comments

    .OUTPUTS
        PSCustomObject[]
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [PSObject[]]$CmdletReferences,

        [Parameter(Mandatory = $false)]
        [PSObject[]]$TypeReferences,

        [Parameter(Mandatory = $false)]
        [PSObject[]]$VariableReferences,

        [Parameter(Mandatory = $false)]
        [PSObject[]]$AliasReferences,

        [Parameter(Mandatory = $false)]
        [PSObject[]]$CommentReferences,

        [Parameter(Mandatory = $false)]
        [double]$ScoreThreshold = 0.5,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails
    )

    try {
        # VÃ©rifier si au moins un type de rÃ©fÃ©rence est fourni
        if (-not $CmdletReferences -and -not $TypeReferences -and -not $VariableReferences -and -not $AliasReferences -and -not $CommentReferences) {
            Write-Error "Au moins un type de rÃ©fÃ©rence doit Ãªtre fourni."
            return @()
        }

        # Initialiser les poids pour chaque type de rÃ©fÃ©rence
        $weights = @{
            Cmdlet   = 0.30  # Les cmdlets ont un poids important car elles sont souvent spÃ©cifiques Ã  un module
            Type     = 0.25  # Les types .NET ont un poids lÃ©gÃ¨rement infÃ©rieur car ils peuvent Ãªtre partagÃ©s
            Variable = 0.20  # Les variables globales ont un poids plus faible car elles sont moins spÃ©cifiques
            Alias    = 0.15  # Les alias ont le poids le plus faible car ils peuvent Ãªtre ambigus
            Comment  = 0.10  # Les rÃ©fÃ©rences dans les commentaires ont le poids le plus faible car elles sont souvent documentaires
        }

        # Regrouper toutes les rÃ©fÃ©rences par module
        $moduleReferences = @{}

        # Traiter les rÃ©fÃ©rences de cmdlets
        if ($CmdletReferences) {
            foreach ($ref in $CmdletReferences) {
                if (-not $moduleReferences.ContainsKey($ref.ModuleName)) {
                    $moduleReferences[$ref.ModuleName] = @{
                        Cmdlets         = @()
                        Types           = @()
                        Variables       = @()
                        Aliases         = @()
                        Comments        = @()
                        TotalReferences = 0
                    }
                }
                $moduleReferences[$ref.ModuleName].Cmdlets += $ref
                $moduleReferences[$ref.ModuleName].TotalReferences++
            }
        }

        # Traiter les rÃ©fÃ©rences de types
        if ($TypeReferences) {
            foreach ($ref in $TypeReferences) {
                if (-not $moduleReferences.ContainsKey($ref.ModuleName)) {
                    $moduleReferences[$ref.ModuleName] = @{
                        Cmdlets         = @()
                        Types           = @()
                        Variables       = @()
                        Aliases         = @()
                        Comments        = @()
                        TotalReferences = 0
                    }
                }
                $moduleReferences[$ref.ModuleName].Types += $ref
                $moduleReferences[$ref.ModuleName].TotalReferences++
            }
        }

        # Traiter les rÃ©fÃ©rences de variables
        if ($VariableReferences) {
            foreach ($ref in $VariableReferences) {
                if (-not $moduleReferences.ContainsKey($ref.ModuleName)) {
                    $moduleReferences[$ref.ModuleName] = @{
                        Cmdlets         = @()
                        Types           = @()
                        Variables       = @()
                        Aliases         = @()
                        Comments        = @()
                        TotalReferences = 0
                    }
                }
                $moduleReferences[$ref.ModuleName].Variables += $ref
                $moduleReferences[$ref.ModuleName].TotalReferences++
            }
        }

        # Traiter les rÃ©fÃ©rences d'alias
        if ($AliasReferences) {
            foreach ($ref in $AliasReferences) {
                if (-not $moduleReferences.ContainsKey($ref.ModuleName)) {
                    $moduleReferences[$ref.ModuleName] = @{
                        Cmdlets         = @()
                        Types           = @()
                        Variables       = @()
                        Aliases         = @()
                        Comments        = @()
                        TotalReferences = 0
                    }
                }
                $moduleReferences[$ref.ModuleName].Aliases += $ref
                $moduleReferences[$ref.ModuleName].TotalReferences++
            }
        }

        # Traiter les rÃ©fÃ©rences dans les commentaires
        if ($CommentReferences) {
            foreach ($ref in $CommentReferences) {
                if (-not $moduleReferences.ContainsKey($ref.ModuleName)) {
                    $moduleReferences[$ref.ModuleName] = @{
                        Cmdlets         = @()
                        Types           = @()
                        Variables       = @()
                        Aliases         = @()
                        Comments        = @()
                        TotalReferences = 0
                    }
                }
                $moduleReferences[$ref.ModuleName].Comments += $ref
                $moduleReferences[$ref.ModuleName].TotalReferences++
            }
        }

        # Calculer le nombre total de rÃ©fÃ©rences
        $totalReferences = 0
        foreach ($module in $moduleReferences.Keys) {
            $totalReferences += $moduleReferences[$module].TotalReferences
        }

        # Calculer le score pour chaque module
        $results = @()
        foreach ($module in $moduleReferences.Keys) {
            $moduleData = $moduleReferences[$module]

            # Calculer le score de base en fonction du nombre de rÃ©fÃ©rences
            $baseScore = [Math]::Min(1.0, $moduleData.TotalReferences / 10.0)

            # Calculer le score pondÃ©rÃ© en fonction des types de rÃ©fÃ©rences
            $weightedScore = 0
            if ($moduleData.Cmdlets.Count -gt 0) {
                $weightedScore += $weights.Cmdlet * [Math]::Min(1.0, $moduleData.Cmdlets.Count / 5.0)
            }
            if ($moduleData.Types.Count -gt 0) {
                $weightedScore += $weights.Type * [Math]::Min(1.0, $moduleData.Types.Count / 3.0)
            }
            if ($moduleData.Variables.Count -gt 0) {
                $weightedScore += $weights.Variable * [Math]::Min(1.0, $moduleData.Variables.Count / 2.0)
            }
            if ($moduleData.Aliases.Count -gt 0) {
                $weightedScore += $weights.Alias * [Math]::Min(1.0, $moduleData.Aliases.Count / 2.0)
            }
            if ($moduleData.Comments.Count -gt 0) {
                $weightedScore += $weights.Comment * [Math]::Min(1.0, $moduleData.Comments.Count / 3.0)
            }

            # Calculer le score de diversitÃ© (bonus si plusieurs types de rÃ©fÃ©rences sont prÃ©sents)
            $diversityScore = 0
            $referenceTypes = 0
            if ($moduleData.Cmdlets.Count -gt 0) { $referenceTypes++ }
            if ($moduleData.Types.Count -gt 0) { $referenceTypes++ }
            if ($moduleData.Variables.Count -gt 0) { $referenceTypes++ }
            if ($moduleData.Aliases.Count -gt 0) { $referenceTypes++ }
            if ($moduleData.Comments.Count -gt 0) { $referenceTypes++ }
            $diversityScore = $referenceTypes / 5.0

            # Calculer le score final
            $finalScore = ($baseScore * 0.3) + ($weightedScore * 0.5) + ($diversityScore * 0.2)

            # DÃ©terminer si le module est probablement requis
            $isProbablyRequired = $finalScore -ge $ScoreThreshold

            # CrÃ©er l'objet rÃ©sultat
            $result = [PSCustomObject]@{
                ModuleName         = $module
                Score              = [Math]::Round($finalScore, 2)
                TotalReferences    = $moduleData.TotalReferences
                CmdletReferences   = $moduleData.Cmdlets.Count
                TypeReferences     = $moduleData.Types.Count
                VariableReferences = $moduleData.Variables.Count
                AliasReferences    = $moduleData.Aliases.Count
                CommentReferences  = $moduleData.Comments.Count
                IsProbablyRequired = $isProbablyRequired
            }

            # Ajouter les dÃ©tails si demandÃ©
            if ($IncludeDetails) {
                $result | Add-Member -NotePropertyName "BaseScore" -NotePropertyValue ([Math]::Round($baseScore, 2))
                $result | Add-Member -NotePropertyName "WeightedScore" -NotePropertyValue ([Math]::Round($weightedScore, 2))
                $result | Add-Member -NotePropertyName "DiversityScore" -NotePropertyValue ([Math]::Round($diversityScore, 2))
                $result | Add-Member -NotePropertyName "Cmdlets" -NotePropertyValue ($moduleData.Cmdlets | Select-Object -ExpandProperty CmdletName -Unique)
                $result | Add-Member -NotePropertyName "Types" -NotePropertyValue ($moduleData.Types | Select-Object -ExpandProperty TypeName -Unique)
                $result | Add-Member -NotePropertyName "Variables" -NotePropertyValue ($moduleData.Variables | Select-Object -ExpandProperty VariableName -Unique)
                $result | Add-Member -NotePropertyName "Aliases" -NotePropertyValue ($moduleData.Aliases | Select-Object -ExpandProperty AliasName -Unique)

                # Ajouter les rÃ©fÃ©rences de commentaires si elles existent
                if ($moduleData.Comments.Count -gt 0) {
                    $commentTypes = $moduleData.Comments | Group-Object -Property Type | Select-Object -Property Name, Count
                    $result | Add-Member -NotePropertyName "CommentTypes" -NotePropertyValue $commentTypes
                }
            }

            $results += $result
        }

        # Trier les rÃ©sultats par score dÃ©croissant
        $results = $results | Sort-Object -Property Score -Descending

        return $results
    } catch {
        Write-Error "Erreur lors du calcul des scores de dÃ©pendance : $_"
        return @()
    }
}

function Find-GlobalVariableWithoutExplicitImport {
    <#
    .SYNOPSIS
        DÃ©tecte les rÃ©fÃ©rences aux variables globales spÃ©cifiques Ã  des modules sans import explicite.

    .DESCRIPTION
        Cette fonction analyse un script PowerShell pour dÃ©tecter les rÃ©fÃ©rences aux variables globales
        qui sont spÃ©cifiques Ã  des modules PowerShell, mais pour lesquels le module n'est pas
        explicitement importÃ© dans le script. Elle dÃ©tecte les rÃ©fÃ©rences directes aux variables,
        ainsi que les rÃ©fÃ©rences via des expressions de membre ou d'index.

    .PARAMETER FilePath
        Chemin du fichier PowerShell Ã  analyser.

    .PARAMETER ScriptContent
        Contenu du script PowerShell Ã  analyser. Si ce paramÃ¨tre est spÃ©cifiÃ©, FilePath est ignorÃ©.

    .PARAMETER IncludeImportedModules
        Indique si les variables des modules dÃ©jÃ  importÃ©s doivent Ãªtre incluses dans les rÃ©sultats.
        Par dÃ©faut, seules les variables des modules non importÃ©s sont retournÃ©es.

    .PARAMETER IncludeModulePatterns
        Indique si les variables qui suivent des modÃ¨les de nommage de modules doivent Ãªtre incluses
        dans les rÃ©sultats, mÃªme si elles ne sont pas explicitement mappÃ©es Ã  un module.

    .EXAMPLE
        Find-GlobalVariableWithoutExplicitImport -FilePath "C:\Scripts\MyScript.ps1"

    .EXAMPLE
        $scriptContent = Get-Content -Path "C:\Scripts\MyScript.ps1" -Raw
        Find-GlobalVariableWithoutExplicitImport -ScriptContent $scriptContent -IncludeModulePatterns

    .OUTPUTS
        PSCustomObject[]
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByPath")]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName = "ByContent")]
        [string]$ScriptContent,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeImportedModules,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeModulePatterns
    )

    try {
        # Analyser le script avec l'AST
        $tokens = $errors = $null
        $ast = $null

        if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
                Write-Error "Le fichier spÃ©cifiÃ© n'existe pas : $FilePath"
                return @()
            }

            $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont Ã©tÃ© dÃ©tectÃ©es dans le script : $($errors.Count) erreur(s)"
            }
        } else {
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont Ã©tÃ© dÃ©tectÃ©es dans le script : $($errors.Count) erreur(s)"
            }
        }

        # Extraire les rÃ©fÃ©rences aux variables globales
        $variableReferences = Get-GlobalVariableReferencesFromAst -Ast $ast

        # Identifier les modules requis pour chaque variable
        $results = @()
        foreach ($varRef in $variableReferences) {
            $moduleName = $script:GlobalVariableToModuleMapping[$varRef.VariableName]
            $moduleNameFound = $false

            # Si un module est trouvÃ© pour cette variable dans le mapping explicite
            if ($moduleName) {
                $moduleNameFound = $true
            }
            # Si on inclut les modÃ¨les de nommage de modules et qu'aucun module n'a Ã©tÃ© trouvÃ©
            elseif ($IncludeModulePatterns -and -not $moduleNameFound) {
                # VÃ©rifier si la variable suit un modÃ¨le de nommage de module
                # Par exemple: $AzureRm*, $Az*, $AD*, $SQL*, etc.
                foreach ($alias in $script:ModuleAliasToModuleMapping.Keys) {
                    if ($varRef.VariableName -like "$alias*") {
                        $moduleName = $script:ModuleAliasToModuleMapping[$alias]
                        $moduleNameFound = $true
                        break
                    }
                }

                # VÃ©rifier si la variable contient le nom d'un module connu
                if (-not $moduleNameFound) {
                    foreach ($knownModule in ($script:CmdletToModuleMapping.Values | Select-Object -Unique)) {
                        if ($varRef.VariableName -like "*$knownModule*") {
                            $moduleName = $knownModule
                            $moduleNameFound = $true
                            break
                        }
                    }
                }
            }

            # Si un module a Ã©tÃ© trouvÃ© pour cette variable
            if ($moduleNameFound -and $moduleName) {
                # VÃ©rifier si le module est importÃ© explicitement
                $isImported = Test-ModuleImported -Ast $ast -ModuleName $moduleName

                # Ajouter au rÃ©sultat si le module n'est pas importÃ© ou si on inclut tous les modules
                if (-not $isImported -or $IncludeImportedModules) {
                    $result = [PSCustomObject]@{
                        VariableName = $varRef.VariableName
                        ModuleName   = $moduleName
                        LineNumber   = $varRef.LineNumber
                        ColumnNumber = $varRef.ColumnNumber
                        Text         = $varRef.Text
                        Source       = $varRef.Source
                        IsImported   = $isImported
                    }

                    # Ajouter des propriÃ©tÃ©s supplÃ©mentaires si elles existent
                    if ($varRef.PSObject.Properties.Name -contains "Member") {
                        $result | Add-Member -NotePropertyName "Member" -NotePropertyValue $varRef.Member
                    }
                    if ($varRef.PSObject.Properties.Name -contains "Index") {
                        $result | Add-Member -NotePropertyName "Index" -NotePropertyValue $varRef.Index
                    }

                    $results += $result
                }
            }
        }

        return $results
    } catch {
        Write-Error "Erreur lors de la dÃ©tection des variables globales sans import explicite : $_"
        return @()
    }
}

function Find-ImplicitModuleDependency {
    <#
    .SYNOPSIS
        DÃ©tecte les dÃ©pendances implicites de modules dans un script PowerShell.

    .DESCRIPTION
        Cette fonction combine toutes les fonctions de dÃ©tection de dÃ©pendances
        et calcule un score de probabilitÃ© pour chaque module dÃ©tectÃ©, en une seule Ã©tape.

    .PARAMETER FilePath
        Chemin du fichier PowerShell Ã  analyser.

    .PARAMETER ScriptContent
        Contenu du script PowerShell Ã  analyser. Si ce paramÃ¨tre est spÃ©cifiÃ©, FilePath est ignorÃ©.

    .PARAMETER ScoreThreshold
        Seuil de score Ã  partir duquel une dÃ©pendance est considÃ©rÃ©e comme probable.
        Par dÃ©faut, ce seuil est fixÃ© Ã  0.5 (50%).

    .PARAMETER IncludeImportedModules
        Indique si les modules dÃ©jÃ  importÃ©s doivent Ãªtre inclus dans les rÃ©sultats.
        Par dÃ©faut, seuls les modules non importÃ©s sont analysÃ©s.

    .PARAMETER IncludeDetails
        Indique si les dÃ©tails du calcul du score doivent Ãªtre inclus dans les rÃ©sultats.

    .EXAMPLE
        Find-ImplicitModuleDependency -FilePath "C:\Scripts\MyScript.ps1"

    .EXAMPLE
        $scriptContent = Get-Content -Path "C:\Scripts\MyScript.ps1" -Raw
        Find-ImplicitModuleDependency -ScriptContent $scriptContent -ScoreThreshold 0.7 -IncludeDetails

    .OUTPUTS
        PSCustomObject[]
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByPath")]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName = "ByContent")]
        [string]$ScriptContent,

        [Parameter(Mandatory = $false)]
        [double]$ScoreThreshold = 0.5,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeImportedModules,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails
    )

    try {
        # DÃ©tecter les rÃ©fÃ©rences de cmdlets
        $cmdletReferences = if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            Find-CmdletWithoutExplicitImport -FilePath $FilePath -IncludeImportedModules:$IncludeImportedModules
        } else {
            Find-CmdletWithoutExplicitImport -ScriptContent $ScriptContent -IncludeImportedModules:$IncludeImportedModules
        }

        # DÃ©tecter les rÃ©fÃ©rences de types .NET
        $typeReferences = if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            Find-DotNetTypeWithoutExplicitImport -FilePath $FilePath -IncludeImportedModules:$IncludeImportedModules
        } else {
            Find-DotNetTypeWithoutExplicitImport -ScriptContent $ScriptContent -IncludeImportedModules:$IncludeImportedModules
        }

        # DÃ©tecter les rÃ©fÃ©rences de variables globales
        $variableReferences = if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            Find-GlobalVariableWithoutExplicitImport -FilePath $FilePath -IncludeImportedModules:$IncludeImportedModules -IncludeModulePatterns
        } else {
            Find-GlobalVariableWithoutExplicitImport -ScriptContent $ScriptContent -IncludeImportedModules:$IncludeImportedModules -IncludeModulePatterns
        }

        # DÃ©tecter les rÃ©fÃ©rences d'alias de modules
        $aliasReferences = if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            Find-ModuleAliasWithoutExplicitImport -FilePath $FilePath -IncludeImportedModules:$IncludeImportedModules
        } else {
            Find-ModuleAliasWithoutExplicitImport -ScriptContent $ScriptContent -IncludeImportedModules:$IncludeImportedModules
        }

        # DÃ©tecter les rÃ©fÃ©rences aux modules dans les commentaires
        $commentReferences = if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            Find-ModuleReferenceInComments -FilePath $FilePath -IncludeImportedModules:$IncludeImportedModules
        } else {
            Find-ModuleReferenceInComments -ScriptContent $ScriptContent -IncludeImportedModules:$IncludeImportedModules
        }

        # Convertir les rÃ©fÃ©rences d'alias en format compatible avec Get-ModuleDependencyScore
        $aliasReferencesForScore = @()
        foreach ($ref in $aliasReferences) {
            $aliasReferencesForScore += [PSCustomObject]@{
                AliasName    = $ref.AliasName
                ModuleName   = $ref.ModuleName
                LineNumber   = $ref.LineNumber
                ColumnNumber = $ref.ColumnNumber
                Text         = $ref.Text
                Source       = $ref.Source
                IsImported   = $ref.IsImported
            }
        }

        # Convertir les rÃ©fÃ©rences de commentaires en format compatible avec Get-ModuleDependencyScore
        $commentReferencesForScore = @()
        foreach ($ref in $commentReferences) {
            $commentReferencesForScore += [PSCustomObject]@{
                ModuleName   = $ref.ModuleName
                LineNumber   = $ref.LineNumber
                ColumnNumber = $ref.ColumnNumber
                Text         = $ref.Text
                Source       = $ref.Source
                Type         = $ref.Type
                IsImported   = $ref.IsImported
            }
        }

        # Calculer les scores de dÃ©pendance
        $scores = Get-ModuleDependencyScore -CmdletReferences $cmdletReferences -TypeReferences $typeReferences -VariableReferences $variableReferences -AliasReferences $aliasReferencesForScore -CommentReferences $commentReferencesForScore -ScoreThreshold $ScoreThreshold -IncludeDetails:$IncludeDetails

        # Retourner les rÃ©sultats
        return $scores
    } catch {
        Write-Error "Erreur lors de la dÃ©tection des dÃ©pendances implicites : $_"
        return @()
    }
}

function Test-ModuleAvailability {
    <#
    .SYNOPSIS
        VÃ©rifie la disponibilitÃ© des modules dÃ©tectÃ©s.

    .DESCRIPTION
        Cette fonction vÃ©rifie si les modules dÃ©tectÃ©s sont disponibles sur le systÃ¨me,
        soit dÃ©jÃ  importÃ©s, soit disponibles pour importation. Elle peut Ã©galement
        vÃ©rifier si les modules sont disponibles dans la galerie PowerShell.

    .PARAMETER ModuleNames
        Noms des modules Ã  vÃ©rifier.

    .PARAMETER CheckGallery
        Indique si la disponibilitÃ© des modules dans la galerie PowerShell doit Ãªtre vÃ©rifiÃ©e.
        Par dÃ©faut, seule la disponibilitÃ© locale est vÃ©rifiÃ©e.

    .PARAMETER IncludeDetails
        Indique si des dÃ©tails supplÃ©mentaires sur les modules doivent Ãªtre inclus dans les rÃ©sultats.

    .EXAMPLE
        Test-ModuleAvailability -ModuleNames "ActiveDirectory", "Az.Accounts", "Pester"

    .EXAMPLE
        $results = Find-ImplicitModuleDependency -FilePath "C:\Scripts\MyScript.ps1"
        $moduleNames = $results | Where-Object { $_.IsProbablyRequired } | Select-Object -ExpandProperty ModuleName
        Test-ModuleAvailability -ModuleNames $moduleNames -CheckGallery -IncludeDetails

    .OUTPUTS
        PSCustomObject[]
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]]$ModuleNames,

        [Parameter(Mandatory = $false)]
        [switch]$CheckGallery,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails
    )

    try {
        # Obtenir la liste des modules importÃ©s
        $importedModules = Get-Module

        # Obtenir la liste des modules disponibles
        $availableModules = Get-Module -ListAvailable

        # Initialiser les rÃ©sultats
        $results = @()

        foreach ($moduleName in $ModuleNames) {
            # VÃ©rifier si le module est dÃ©jÃ  importÃ©
            $isImported = $importedModules | Where-Object { $_.Name -eq $moduleName }

            # VÃ©rifier si le module est disponible localement
            $isAvailable = $availableModules | Where-Object { $_.Name -eq $moduleName }

            # Initialiser les variables pour la galerie
            $isInGallery = $null
            $galleryVersion = $null
            $galleryDetails = $null

            # VÃ©rifier si le module est disponible dans la galerie PowerShell
            if ($CheckGallery) {
                try {
                    $galleryModule = Find-Module -Name $moduleName -ErrorAction SilentlyContinue
                    if ($galleryModule) {
                        $isInGallery = $true
                        $galleryVersion = $galleryModule.Version
                        $galleryDetails = $galleryModule
                    } else {
                        $isInGallery = $false
                    }
                } catch {
                    $isInGallery = $false
                }
            }

            # CrÃ©er l'objet rÃ©sultat
            $result = [PSCustomObject]@{
                ModuleName         = $moduleName
                IsImported         = ($null -ne $isImported)
                IsAvailable        = ($null -ne $isAvailable)
                IsInGallery        = $isInGallery
                LocalVersion       = if ($null -ne $isImported) { $isImported.Version } elseif ($null -ne $isAvailable) { $isAvailable[0].Version } else { $null }
                GalleryVersion     = $galleryVersion
                Status             = if ($null -ne $isImported) {
                    "Imported"
                } elseif ($null -ne $isAvailable) {
                    "Available"
                } elseif ($isInGallery) {
                    "InGallery"
                } else {
                    "NotFound"
                }
                ValidationPassed   = ($null -ne $isImported) -or ($null -ne $isAvailable)
                InstallationNeeded = ($null -eq $isImported) -and ($null -eq $isAvailable) -and $isInGallery
            }

            # Ajouter des dÃ©tails supplÃ©mentaires si demandÃ©
            if ($IncludeDetails) {
                if ($null -ne $isImported) {
                    $result | Add-Member -NotePropertyName "ImportedModule" -NotePropertyValue $isImported
                }
                if ($null -ne $isAvailable) {
                    $result | Add-Member -NotePropertyName "AvailableModule" -NotePropertyValue $isAvailable[0]
                }
                if ($null -ne $galleryDetails) {
                    $result | Add-Member -NotePropertyName "GalleryModule" -NotePropertyValue $galleryDetails
                }
            }

            $results += $result
        }

        return $results
    } catch {
        Write-Error "Erreur lors de la vÃ©rification de la disponibilitÃ© des modules : $_"
        return @()
    }
}

function Confirm-ModuleDependencies {
    <#
    .SYNOPSIS
        Valide les dÃ©pendances de modules dÃ©tectÃ©es et propose des actions correctives.

    .DESCRIPTION
        Cette fonction analyse les rÃ©sultats de la dÃ©tection de dÃ©pendances implicites,
        vÃ©rifie la disponibilitÃ© des modules requis, et propose des actions correctives
        comme l'ajout d'instructions Import-Module ou l'installation de modules manquants.

    .PARAMETER FilePath
        Chemin du fichier PowerShell Ã  analyser.

    .PARAMETER ScriptContent
        Contenu du script PowerShell Ã  analyser. Si ce paramÃ¨tre est spÃ©cifiÃ©, FilePath est ignorÃ©.

    .PARAMETER ScoreThreshold
        Seuil de score Ã  partir duquel une dÃ©pendance est considÃ©rÃ©e comme probable.
        Par dÃ©faut, ce seuil est fixÃ© Ã  0.5 (50%).

    .PARAMETER CheckGallery
        Indique si la disponibilitÃ© des modules dans la galerie PowerShell doit Ãªtre vÃ©rifiÃ©e.
        Par dÃ©faut, seule la disponibilitÃ© locale est vÃ©rifiÃ©e.

    .PARAMETER GenerateImportStatements
        Indique si des instructions Import-Module doivent Ãªtre gÃ©nÃ©rÃ©es pour les modules manquants.

    .PARAMETER IncludeDetails
        Indique si des dÃ©tails supplÃ©mentaires doivent Ãªtre inclus dans les rÃ©sultats.

    .EXAMPLE
        Confirm-ModuleDependencies -FilePath "C:\Scripts\MyScript.ps1"

    .EXAMPLE
        $scriptContent = Get-Content -Path "C:\Scripts\MyScript.ps1" -Raw
        Confirm-ModuleDependencies -ScriptContent $scriptContent -ScoreThreshold 0.7 -CheckGallery -GenerateImportStatements

    .OUTPUTS
        PSCustomObject
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByPath")]
        [string]$FilePath,

        [Parameter(Mandatory = $true, ParameterSetName = "ByContent")]
        [string]$ScriptContent,

        [Parameter(Mandatory = $false)]
        [double]$ScoreThreshold = 0.5,

        [Parameter(Mandatory = $false)]
        [switch]$CheckGallery,

        [Parameter(Mandatory = $false)]
        [switch]$GenerateImportStatements,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails
    )

    try {
        # DÃ©tecter les dÃ©pendances implicites
        $dependencies = if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            Find-ImplicitModuleDependency -FilePath $FilePath -ScoreThreshold $ScoreThreshold -IncludeDetails:$IncludeDetails
        } else {
            Find-ImplicitModuleDependency -ScriptContent $ScriptContent -ScoreThreshold $ScoreThreshold -IncludeDetails:$IncludeDetails
        }

        # Filtrer les dÃ©pendances probables
        $probableDependencies = $dependencies | Where-Object { $_.IsProbablyRequired }

        # Si aucune dÃ©pendance probable n'est trouvÃ©e
        if (-not $probableDependencies -or $probableDependencies.Count -eq 0) {
            return [PSCustomObject]@{
                Status            = "NoDependenciesFound"
                Message           = "Aucune dÃ©pendance implicite probable n'a Ã©tÃ© dÃ©tectÃ©e."
                Dependencies      = $dependencies
                ValidatedModules  = @()
                MissingModules    = @()
                ImportStatements  = @()
                InstallStatements = @()
                ValidationPassed  = $true
            }
        }

        # Extraire les noms de modules
        $moduleNames = $probableDependencies | Select-Object -ExpandProperty ModuleName

        # VÃ©rifier la disponibilitÃ© des modules
        $moduleAvailability = Test-ModuleAvailability -ModuleNames $moduleNames -CheckGallery:$CheckGallery -IncludeDetails:$IncludeDetails

        # SÃ©parer les modules validÃ©s et manquants
        $validatedModules = $moduleAvailability | Where-Object { $_.ValidationPassed }
        $missingModules = $moduleAvailability | Where-Object { -not $_.ValidationPassed }

        # GÃ©nÃ©rer des instructions Import-Module si demandÃ©
        $importStatements = @()
        if ($GenerateImportStatements) {
            foreach ($module in $validatedModules) {
                $importStatements += "Import-Module -Name '$($module.ModuleName)' -ErrorAction Stop"
            }
        }

        # GÃ©nÃ©rer des instructions d'installation pour les modules manquants
        $installStatements = @()
        foreach ($module in $missingModules) {
            if ($module.IsInGallery) {
                $installStatements += "Install-Module -Name '$($module.ModuleName)' -Scope CurrentUser -Force"
            }
        }

        # DÃ©terminer le statut global
        $status = if ($missingModules.Count -eq 0) {
            "AllModulesAvailable"
        } elseif ($missingModules | Where-Object { $_.IsInGallery }) {
            "SomeModulesNeedInstallation"
        } else {
            "SomeModulesNotFound"
        }

        # CrÃ©er le message appropriÃ©
        $message = switch ($status) {
            "AllModulesAvailable" {
                "Tous les modules requis sont disponibles. Ajoutez des instructions Import-Module pour les utiliser explicitement."
            }
            "SomeModulesNeedInstallation" {
                "Certains modules requis ne sont pas installÃ©s mais sont disponibles dans la galerie PowerShell. Installez-les avant d'utiliser le script."
            }
            "SomeModulesNotFound" {
                "Certains modules requis n'ont pas Ã©tÃ© trouvÃ©s, ni localement ni dans la galerie PowerShell. VÃ©rifiez les noms des modules ou leur disponibilitÃ©."
            }
        }

        # CrÃ©er l'objet rÃ©sultat
        $result = [PSCustomObject]@{
            Status            = $status
            Message           = $message
            Dependencies      = $dependencies
            ValidatedModules  = $validatedModules
            MissingModules    = $missingModules
            ImportStatements  = $importStatements
            InstallStatements = $installStatements
            ValidationPassed  = ($missingModules.Count -eq 0)
        }

        return $result
    } catch {
        Write-Error "Erreur lors de la validation des dÃ©pendances de modules : $_"
        return $null
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Find-CmdletWithoutExplicitImport, Find-DotNetTypeWithoutExplicitImport, Find-GlobalVariableWithoutExplicitImport, Find-ModuleAliasWithoutExplicitImport, Find-ModuleReferenceInComments, Test-ModuleAvailability, Confirm-ModuleDependencies, New-ModuleMappingDatabase, Update-ModuleMappingDatabase, Import-ModuleMappingDatabase, Get-ModuleDependencyScore, Find-ImplicitModuleDependency
