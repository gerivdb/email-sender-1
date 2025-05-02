#Requires -Version 5.1
<#
.SYNOPSIS
    Module pour la détection des modules requis implicitement dans les scripts PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions pour détecter les modules requis implicitement dans les scripts PowerShell,
    notamment les appels de cmdlets sans import explicite, les types .NET spécifiques à des modules,
    et les variables globales spécifiques à des modules.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-12-15
#>

#region Private Functions

# Base de données de correspondance entre cmdlets et modules
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

# Base de données de correspondance entre types .NET et modules
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

# Base de données de correspondance entre variables globales et modules
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

# Base de données de correspondance entre alias de modules et modules
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

        # Extraire les noms des cmdlets appelées
        $cmdletCalls = @()
        foreach ($call in $commandCalls) {
            if ($call.CommandElements.Count -gt 0) {
                $cmdletName = $null

                # Vérifier si le premier élément est un nom de cmdlet
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

# Fonction interne pour vérifier si un module est importé explicitement
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

        # Vérifier si le module spécifié est importé
        foreach ($call in $importModuleCalls) {
            # Vérifier les paramètres nommés
            for ($i = 1; $i -lt $call.CommandElements.Count; $i++) {
                $element = $call.CommandElements[$i]

                # Vérifier si c'est un paramètre -Name ou -Path
                if ($element -is [System.Management.Automation.Language.CommandParameterAst] -and
                    ($element.ParameterName -eq 'Name' -or $element.ParameterName -eq 'Path')) {

                    # Vérifier si le paramètre a une valeur
                    if ($i + 1 -lt $call.CommandElements.Count -and
                        -not ($call.CommandElements[$i + 1] -is [System.Management.Automation.Language.CommandParameterAst])) {

                        $paramValue = $call.CommandElements[$i + 1]

                        # Extraire la valeur du paramètre
                        $value = $null
                        if ($paramValue -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                            $value = $paramValue.Value
                        } elseif ($paramValue -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
                            $value = $paramValue.Value
                        } else {
                            $value = $paramValue.Extent.Text
                        }

                        # Vérifier si la valeur correspond au module recherché
                        if ($value -eq $ModuleName) {
                            return $true
                        }
                    }
                }
                # Vérifier les paramètres positionnels
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
        Write-Error "Erreur lors de la vérification des imports de modules : $_"
        return $false
    }
}

# Fonction interne pour extraire les références aux modules dans les commentaires
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
        Write-Error "Erreur lors de l'extraction des références aux modules dans les commentaires : $_"
        return @()
    }
}

# Fonction interne pour extraire les références aux alias de modules d'un AST
function Get-ModuleAliasReferencesFromAst {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast
    )

    try {
        # Trouver toutes les références aux alias de modules dans l'AST
        $aliasReferences = @()

        # 1. Rechercher les références dans les commentaires
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

        # 2. Rechercher les références dans les chaînes de caractères
        $stringExpressions = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.StringConstantExpressionAst] -or
                $node -is [System.Management.Automation.Language.ExpandableStringExpressionAst]
            }, $true)

        foreach ($stringExpr in $stringExpressions) {
            $stringValue = $stringExpr.Value

            # Parcourir tous les alias de modules connus
            foreach ($alias in $script:ModuleAliasToModuleMapping.Keys) {
                # Rechercher les mentions de l'alias dans la chaîne
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

        # 3. Rechercher les références dans les noms de variables (ex: $ADUser)
        $variableExpressions = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.VariableExpressionAst]
            }, $true)

        foreach ($varExpr in $variableExpressions) {
            $variableName = $varExpr.VariablePath.UserPath

            # Parcourir tous les alias de modules connus
            foreach ($alias in $script:ModuleAliasToModuleMapping.Keys) {
                # Vérifier si le nom de la variable commence par l'alias
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
        Write-Error "Erreur lors de l'extraction des références aux alias de modules : $_"
        return @()
    }
}

# Fonction interne pour extraire les références aux variables globales d'un AST
function Get-GlobalVariableReferencesFromAst {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast
    )

    try {
        # Trouver toutes les références aux variables dans l'AST
        $variableReferences = @()

        # Rechercher les références aux variables
        $variableExpressions = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.VariableExpressionAst]
            }, $true)

        foreach ($varExpr in $variableExpressions) {
            # Exclure les variables locales (celles qui commencent par $)
            # Nous ne voulons que les variables globales qui sont définies par des modules
            if (-not [string]::IsNullOrEmpty($varExpr.VariablePath.UserPath)) {
                $variableName = $varExpr.VariablePath.UserPath

                # Ajouter la référence à la variable
                $variableReferences += [PSCustomObject]@{
                    VariableName = $variableName
                    LineNumber   = $varExpr.Extent.StartLineNumber
                    ColumnNumber = $varExpr.Extent.StartColumnNumber
                    Text         = $varExpr.Extent.Text
                    Source       = "Direct" # Référence directe à la variable
                }
            }
        }

        # Rechercher les références aux variables dans les expressions de membre
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

                # Ajouter la référence à la variable
                $variableReferences += [PSCustomObject]@{
                    VariableName = $variableName
                    LineNumber   = $memberExpr.Extent.StartLineNumber
                    ColumnNumber = $memberExpr.Extent.StartColumnNumber
                    Text         = $memberExpr.Extent.Text
                    Source       = "Member" # Référence via une expression de membre
                    Member       = $memberExpr.Member.Value
                }
            }
        }

        # Rechercher les références aux variables dans les expressions d'index
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

                # Essayer d'extraire l'index si c'est une chaîne constante
                $indexValue = $null
                if ($indexExpr.Index -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                    $indexValue = $indexExpr.Index.Value
                }

                # Ajouter la référence à la variable
                $variableReferences += [PSCustomObject]@{
                    VariableName = $variableName
                    LineNumber   = $indexExpr.Extent.StartLineNumber
                    ColumnNumber = $indexExpr.Extent.StartColumnNumber
                    Text         = $indexExpr.Extent.Text
                    Source       = "Index" # Référence via une expression d'index
                    Index        = $indexValue
                }
            }
        }

        return $variableReferences
    } catch {
        Write-Error "Erreur lors de l'extraction des références aux variables globales : $_"
        return @()
    }
}

# Fonction interne pour extraire les références de types .NET d'un AST
function Get-DotNetTypeReferencesFromAst {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast
    )

    try {
        # Trouver toutes les références de types dans l'AST
        $typeReferences = @()

        # 1. Rechercher les références de types dans les expressions de type
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

        # 2. Rechercher les références de types dans les expressions [Type]::Member
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

        # 3. Rechercher les références de types dans les expressions de cast [Type]$var
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

        # 4. Rechercher les références de types dans les expressions New-Object Type
        $newObjectCalls = $Ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.CommandElements.Count -gt 0 -and
                $node.CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
                $node.CommandElements[0].Value -eq 'New-Object'
            }, $true)

        foreach ($call in $newObjectCalls) {
            # Vérifier les paramètres nommés
            $typeName = $null
            $typeNameFound = $false

            for ($i = 1; $i -lt $call.CommandElements.Count; $i++) {
                $element = $call.CommandElements[$i]

                # Vérifier si c'est un paramètre -TypeName
                if ($element -is [System.Management.Automation.Language.CommandParameterAst] -and
                    $element.ParameterName -eq 'TypeName') {

                    # Vérifier si le paramètre a une valeur
                    if ($i + 1 -lt $call.CommandElements.Count -and
                        -not ($call.CommandElements[$i + 1] -is [System.Management.Automation.Language.CommandParameterAst])) {

                        $paramValue = $call.CommandElements[$i + 1]

                        # Extraire la valeur du paramètre
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
                # Vérifier les paramètres positionnels
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
        Write-Error "Erreur lors de l'extraction des références de types .NET : $_"
        return @()
    }
}

#endregion

#region Public Functions

function Find-CmdletWithoutExplicitImport {
    <#
    .SYNOPSIS
        Détecte les appels de cmdlets sans import explicite du module correspondant.

    .DESCRIPTION
        Cette fonction analyse un script PowerShell pour détecter les appels de cmdlets
        qui nécessitent un module spécifique, mais pour lesquels le module n'est pas
        explicitement importé dans le script.

    .PARAMETER FilePath
        Chemin du fichier PowerShell à analyser.

    .PARAMETER ScriptContent
        Contenu du script PowerShell à analyser. Si ce paramètre est spécifié, FilePath est ignoré.

    .PARAMETER IncludeImportedModules
        Indique si les cmdlets des modules déjà importés doivent être incluses dans les résultats.
        Par défaut, seules les cmdlets des modules non importés sont retournées.

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
                Write-Error "Le fichier spécifié n'existe pas : $FilePath"
                return @()
            }

            $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont été détectées dans le script : $($errors.Count) erreur(s)"
            }
        } else {
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont été détectées dans le script : $($errors.Count) erreur(s)"
            }
        }

        # Extraire les appels de cmdlets
        $cmdletCalls = Get-CmdletCallsFromAst -Ast $ast

        # Identifier les modules requis pour chaque cmdlet
        $results = @()
        foreach ($call in $cmdletCalls) {
            $moduleName = $script:CmdletToModuleMapping[$call.Name]

            # Vérifier si la cmdlet est dans notre base de données de correspondance
            if ($moduleName) {
                # Vérifier si le module est importé explicitement
                $isImported = Test-ModuleImported -Ast $ast -ModuleName $moduleName

                # Ajouter au résultat si le module n'est pas importé ou si on inclut tous les modules
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
        Write-Error "Erreur lors de la détection des cmdlets sans import explicite : $_"
        return @()
    }
}

function Find-ModuleReferenceInComments {
    <#
    .SYNOPSIS
        Détecte les références à des modules dans les commentaires d'un script PowerShell.

    .DESCRIPTION
        Cette fonction analyse les commentaires d'un script PowerShell pour détecter les références
        à des modules, que ce soit par leur nom, leurs alias, leurs cmdlets, leurs types, ou leurs variables.
        Elle permet de détecter les dépendances implicites mentionnées dans les commentaires.

    .PARAMETER FilePath
        Chemin du fichier PowerShell à analyser.

    .PARAMETER ScriptContent
        Contenu du script PowerShell à analyser. Si ce paramètre est spécifié, FilePath est ignoré.

    .PARAMETER IncludeImportedModules
        Indique si les modules déjà importés doivent être inclus dans les résultats.
        Par défaut, seuls les modules non importés sont retournés.

    .PARAMETER IncludeRequiresDirectives
        Indique si les directives #Requires -Modules doivent être incluses dans les résultats.
        Par défaut, ces directives sont incluses.

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
                Write-Error "Le fichier spécifié n'existe pas : $FilePath"
                return @()
            }

            $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont été détectées dans le script : $($errors.Count) erreur(s)"
            }
        } else {
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont été détectées dans le script : $($errors.Count) erreur(s)"
            }
        }

        # Extraire les références aux modules dans les commentaires
        $commentReferences = Get-ModuleReferencesFromComments -Ast $ast

        # Filtrer les résultats selon les paramètres
        # Par défaut, on inclut les directives #Requires
        if (-not $IncludeRequiresDirectives.IsPresent) {
            # Ne rien faire, garder toutes les références
        } else {
            # Si le paramètre est explicitement fourni et est $false, filtrer les directives #Requires
            if (-not $IncludeRequiresDirectives) {
                $commentReferences = $commentReferences | Where-Object { $_.Type -ne "RequiresModule" }
            }
        }

        # Identifier les modules requis pour chaque référence
        $results = @()
        foreach ($ref in $commentReferences) {
            $moduleName = $ref.ModuleName

            # Vérifier si le module est importé explicitement
            $isImported = Test-ModuleImported -Ast $ast -ModuleName $moduleName

            # Ajouter au résultat si le module n'est pas importé ou si on inclut tous les modules
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

                # Ajouter des propriétés supplémentaires si elles existent
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
        Write-Error "Erreur lors de la détection des références aux modules dans les commentaires : $_"
        return @()
    }
}

function Find-ModuleAliasWithoutExplicitImport {
    <#
    .SYNOPSIS
        Détecte les références à des alias de modules sans import explicite du module correspondant.

    .DESCRIPTION
        Cette fonction analyse un script PowerShell pour détecter les références à des alias de modules
        qui sont spécifiques à des modules PowerShell, mais pour lesquels le module n'est pas
        explicitement importé dans le script. Les références peuvent être trouvées dans les commentaires,
        les chaînes de caractères, ou les noms de variables.

    .PARAMETER FilePath
        Chemin du fichier PowerShell à analyser.

    .PARAMETER ScriptContent
        Contenu du script PowerShell à analyser. Si ce paramètre est spécifié, FilePath est ignoré.

    .PARAMETER IncludeImportedModules
        Indique si les alias des modules déjà importés doivent être inclus dans les résultats.
        Par défaut, seuls les alias des modules non importés sont retournés.

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
                Write-Error "Le fichier spécifié n'existe pas : $FilePath"
                return @()
            }

            $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont été détectées dans le script : $($errors.Count) erreur(s)"
            }
        } else {
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont été détectées dans le script : $($errors.Count) erreur(s)"
            }
        }

        # Extraire les références aux alias de modules
        $aliasReferences = Get-ModuleAliasReferencesFromAst -Ast $ast

        # Identifier les modules requis pour chaque alias
        $results = @()
        foreach ($aliasRef in $aliasReferences) {
            $moduleName = $script:ModuleAliasToModuleMapping[$aliasRef.AliasName]

            # Si un module est trouvé pour cet alias
            if ($moduleName) {
                # Vérifier si le module est importé explicitement
                $isImported = Test-ModuleImported -Ast $ast -ModuleName $moduleName

                # Ajouter au résultat si le module n'est pas importé ou si on inclut tous les modules
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
        Write-Error "Erreur lors de la détection des alias de modules sans import explicite : $_"
        return @()
    }
}

function Find-DotNetTypeWithoutExplicitImport {
    <#
    .SYNOPSIS
        Détecte les références à des types .NET spécifiques à des modules sans import explicite.

    .DESCRIPTION
        Cette fonction analyse un script PowerShell pour détecter les références à des types .NET
        qui sont spécifiques à des modules PowerShell, mais pour lesquels le module n'est pas
        explicitement importé dans le script.

    .PARAMETER FilePath
        Chemin du fichier PowerShell à analyser.

    .PARAMETER ScriptContent
        Contenu du script PowerShell à analyser. Si ce paramètre est spécifié, FilePath est ignoré.

    .PARAMETER IncludeImportedModules
        Indique si les types des modules déjà importés doivent être inclus dans les résultats.
        Par défaut, seuls les types des modules non importés sont retournés.

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
                Write-Error "Le fichier spécifié n'existe pas : $FilePath"
                return @()
            }

            $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont été détectées dans le script : $($errors.Count) erreur(s)"
            }
        } else {
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont été détectées dans le script : $($errors.Count) erreur(s)"
            }
        }

        # Extraire les références de types .NET
        $typeReferences = Get-DotNetTypeReferencesFromAst -Ast $ast

        # Identifier les modules requis pour chaque type
        $results = @()
        foreach ($typeRef in $typeReferences) {
            $moduleName = $null

            # Vérifier si le type est dans notre base de données de correspondance
            $moduleName = $script:TypeToModuleMapping[$typeRef.TypeName]

            # Si le type n'est pas trouvé directement, essayer de trouver une correspondance partielle
            if (-not $moduleName) {
                foreach ($key in $script:TypeToModuleMapping.Keys) {
                    if ($typeRef.TypeName -like "$key*" -or $typeRef.TypeName -like "*.$key*") {
                        $moduleName = $script:TypeToModuleMapping[$key]
                        break
                    }
                }
            }

            # Si un module est trouvé pour ce type
            if ($moduleName) {
                # Vérifier si le module est importé explicitement
                $isImported = Test-ModuleImported -Ast $ast -ModuleName $moduleName

                # Ajouter au résultat si le module n'est pas importé ou si on inclut tous les modules
                if (-not $isImported -or $IncludeImportedModules) {
                    $result = [PSCustomObject]@{
                        TypeName     = $typeRef.TypeName
                        ModuleName   = $moduleName
                        LineNumber   = $typeRef.LineNumber
                        ColumnNumber = $typeRef.ColumnNumber
                        Text         = $typeRef.Text
                        IsImported   = $isImported
                    }

                    # Ajouter des propriétés supplémentaires si elles existent
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
        Write-Error "Erreur lors de la détection des types .NET sans import explicite : $_"
        return @()
    }
}

#endregion

function New-ModuleMappingDatabase {
    <#
    .SYNOPSIS
        Crée une base de données de correspondance entre cmdlets/types/variables et modules.

    .DESCRIPTION
        Cette fonction analyse les modules installés sur le système et crée une base de données
        de correspondance entre les cmdlets, types .NET et variables globales et leurs modules respectifs.
        Cette base de données peut être utilisée pour détecter les dépendances implicites dans les scripts PowerShell.

    .PARAMETER ModuleNames
        Noms des modules à analyser. Si non spécifié, tous les modules disponibles seront analysés.

    .PARAMETER OutputPath
        Chemin du fichier de sortie pour la base de données. Si non spécifié, la base de données
        sera retournée sous forme d'objet PowerShell.

    .PARAMETER IncludeCmdlets
        Indique si les cmdlets doivent être incluses dans la base de données.

    .PARAMETER IncludeTypes
        Indique si les types .NET doivent être inclus dans la base de données.

    .PARAMETER IncludeVariables
        Indique si les variables globales doivent être incluses dans la base de données.

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

        # Obtenir la liste des modules à analyser
        $modules = @()
        if ($ModuleNames) {
            foreach ($moduleName in $ModuleNames) {
                $module = Get-Module -Name $moduleName -ListAvailable | Select-Object -First 1
                if ($module) {
                    $modules += $module
                } else {
                    Write-Warning "Le module '$moduleName' n'a pas été trouvé."
                }
            }
        } else {
            $modules = Get-Module -ListAvailable
        }

        # Analyser chaque module
        foreach ($module in $modules) {
            $moduleName = $module.Name
            Write-Verbose "Analyse du module: $moduleName"

            # Analyser les cmdlets si demandé
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

            # Analyser les types .NET si demandé
            if ($IncludeTypes) {
                Write-Verbose "  Analyse des types .NET..."
                try {
                    # Importer le module pour accéder à ses types
                    Import-Module $moduleName -ErrorAction SilentlyContinue

                    # Obtenir les types exportés par le module
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

            # Analyser les variables globales si demandé
            if ($IncludeVariables) {
                Write-Verbose "  Analyse des variables globales..."
                try {
                    # Importer le module pour accéder à ses variables
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

        # Créer la base de données complète
        $database = @{
            CmdletToModuleMapping   = $cmdletToModuleMapping
            TypeToModuleMapping     = $typeToModuleMapping
            VariableToModuleMapping = $variableToModuleMapping
        }

        # Exporter la base de données si un chemin de sortie est spécifié
        if ($OutputPath) {
            $databaseContent = @"
# Base de données de correspondance entre cmdlets/types/variables et modules
# Générée le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

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
            # Retourner la base de données
            $database
        }
    } catch {
        Write-Error "Erreur lors de la création de la base de données de correspondance : $_"
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
        Met à jour la base de données de correspondance entre cmdlets/types/variables et modules.

    .DESCRIPTION
        Cette fonction met à jour la base de données de correspondance existante avec de nouvelles
        entrées provenant des modules spécifiés.

    .PARAMETER DatabasePath
        Chemin du fichier de base de données à mettre à jour.

    .PARAMETER ModuleNames
        Noms des modules à analyser. Si non spécifié, tous les modules disponibles seront analysés.

    .PARAMETER OutputPath
        Chemin du fichier de sortie pour la base de données mise à jour. Si non spécifié, le fichier
        d'entrée sera écrasé.

    .PARAMETER IncludeCmdlets
        Indique si les cmdlets doivent être incluses dans la base de données.

    .PARAMETER IncludeTypes
        Indique si les types .NET doivent être inclus dans la base de données.

    .PARAMETER IncludeVariables
        Indique si les variables globales doivent être incluses dans la base de données.

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
        # Vérifier si le fichier de base de données existe
        if (-not (Test-Path -Path $DatabasePath -PathType Leaf)) {
            Write-Error "Le fichier de base de données spécifié n'existe pas : $DatabasePath"
            return $null
        }

        # Charger la base de données existante
        $existingDatabase = & ([ScriptBlock]::Create("return $(Get-Content -Path $DatabasePath -Raw)"))

        # Créer une nouvelle base de données pour les modules spécifiés
        $newDatabase = New-ModuleMappingDatabase -ModuleNames $ModuleNames -IncludeCmdlets:$IncludeCmdlets -IncludeTypes:$IncludeTypes -IncludeVariables:$IncludeVariables

        # Fusionner les bases de données
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

        # Déterminer le chemin de sortie
        $outputFilePath = if ($OutputPath) { $OutputPath } else { $DatabasePath }

        # Exporter la base de données fusionnée
        $databaseContent = @"
# Base de données de correspondance entre cmdlets/types/variables et modules
# Mise à jour le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

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
        Write-Error "Erreur lors de la mise à jour de la base de données de correspondance : $_"
        return $null
    }
}

function Import-ModuleMappingDatabase {
    <#
    .SYNOPSIS
        Importe une base de données de correspondance entre cmdlets/types/variables et modules.

    .DESCRIPTION
        Cette fonction importe une base de données de correspondance à partir d'un fichier PSD1
        et met à jour les variables globales du script avec les mappings importés.

    .PARAMETER DatabasePath
        Chemin du fichier de base de données à importer.

    .PARAMETER UpdateGlobalMappings
        Indique si les mappings globaux du script doivent être mis à jour avec les mappings importés.

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
        # Vérifier si le fichier de base de données existe
        if (-not (Test-Path -Path $DatabasePath -PathType Leaf)) {
            Write-Error "Le fichier de base de données spécifié n'existe pas : $DatabasePath"
            return $null
        }

        # Charger la base de données
        $database = & ([ScriptBlock]::Create("return $(Get-Content -Path $DatabasePath -Raw)"))

        # Mettre à jour les mappings globaux si demandé
        if ($UpdateGlobalMappings) {
            # Mettre à jour le mapping de cmdlets
            $script:CmdletToModuleMapping = $database.CmdletToModuleMapping

            # Mettre à jour le mapping de types
            $script:TypeToModuleMapping = $database.TypeToModuleMapping

            # Mettre à jour le mapping de variables
            $script:GlobalVariableToModuleMapping = $database.VariableToModuleMapping
        }

        # Retourner la base de données
        $database
    } catch {
        Write-Error "Erreur lors de l'importation de la base de données de correspondance : $_"
        return $null
    }
}

function Get-ModuleDependencyScore {
    <#
    .SYNOPSIS
        Calcule un score de probabilité pour les dépendances de modules détectées.

    .DESCRIPTION
        Cette fonction analyse les résultats des fonctions de détection de dépendances
        et calcule un score de probabilité pour chaque module détecté, en fonction
        de différents critères comme le nombre de références, le type de références,
        et la présence d'autres modules du même fournisseur.

    .PARAMETER CmdletReferences
        Résultats de la fonction Find-CmdletWithoutExplicitImport.

    .PARAMETER TypeReferences
        Résultats de la fonction Find-DotNetTypeWithoutExplicitImport.

    .PARAMETER VariableReferences
        Résultats de la fonction Find-GlobalVariableWithoutExplicitImport.

    .PARAMETER AliasReferences
        Résultats de la fonction Find-ModuleAliasWithoutExplicitImport.

    .PARAMETER CommentReferences
        Résultats de la fonction Find-ModuleReferenceInComments.

    .PARAMETER ScoreThreshold
        Seuil de score à partir duquel une dépendance est considérée comme probable.
        Par défaut, ce seuil est fixé à 0.5 (50%).

    .PARAMETER IncludeDetails
        Indique si les détails du calcul du score doivent être inclus dans les résultats.

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
        # Vérifier si au moins un type de référence est fourni
        if (-not $CmdletReferences -and -not $TypeReferences -and -not $VariableReferences -and -not $AliasReferences -and -not $CommentReferences) {
            Write-Error "Au moins un type de référence doit être fourni."
            return @()
        }

        # Initialiser les poids pour chaque type de référence
        $weights = @{
            Cmdlet   = 0.30  # Les cmdlets ont un poids important car elles sont souvent spécifiques à un module
            Type     = 0.25  # Les types .NET ont un poids légèrement inférieur car ils peuvent être partagés
            Variable = 0.20  # Les variables globales ont un poids plus faible car elles sont moins spécifiques
            Alias    = 0.15  # Les alias ont le poids le plus faible car ils peuvent être ambigus
            Comment  = 0.10  # Les références dans les commentaires ont le poids le plus faible car elles sont souvent documentaires
        }

        # Regrouper toutes les références par module
        $moduleReferences = @{}

        # Traiter les références de cmdlets
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

        # Traiter les références de types
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

        # Traiter les références de variables
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

        # Traiter les références d'alias
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

        # Traiter les références dans les commentaires
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

        # Calculer le nombre total de références
        $totalReferences = 0
        foreach ($module in $moduleReferences.Keys) {
            $totalReferences += $moduleReferences[$module].TotalReferences
        }

        # Calculer le score pour chaque module
        $results = @()
        foreach ($module in $moduleReferences.Keys) {
            $moduleData = $moduleReferences[$module]

            # Calculer le score de base en fonction du nombre de références
            $baseScore = [Math]::Min(1.0, $moduleData.TotalReferences / 10.0)

            # Calculer le score pondéré en fonction des types de références
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

            # Calculer le score de diversité (bonus si plusieurs types de références sont présents)
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

            # Déterminer si le module est probablement requis
            $isProbablyRequired = $finalScore -ge $ScoreThreshold

            # Créer l'objet résultat
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

            # Ajouter les détails si demandé
            if ($IncludeDetails) {
                $result | Add-Member -NotePropertyName "BaseScore" -NotePropertyValue ([Math]::Round($baseScore, 2))
                $result | Add-Member -NotePropertyName "WeightedScore" -NotePropertyValue ([Math]::Round($weightedScore, 2))
                $result | Add-Member -NotePropertyName "DiversityScore" -NotePropertyValue ([Math]::Round($diversityScore, 2))
                $result | Add-Member -NotePropertyName "Cmdlets" -NotePropertyValue ($moduleData.Cmdlets | Select-Object -ExpandProperty CmdletName -Unique)
                $result | Add-Member -NotePropertyName "Types" -NotePropertyValue ($moduleData.Types | Select-Object -ExpandProperty TypeName -Unique)
                $result | Add-Member -NotePropertyName "Variables" -NotePropertyValue ($moduleData.Variables | Select-Object -ExpandProperty VariableName -Unique)
                $result | Add-Member -NotePropertyName "Aliases" -NotePropertyValue ($moduleData.Aliases | Select-Object -ExpandProperty AliasName -Unique)

                # Ajouter les références de commentaires si elles existent
                if ($moduleData.Comments.Count -gt 0) {
                    $commentTypes = $moduleData.Comments | Group-Object -Property Type | Select-Object -Property Name, Count
                    $result | Add-Member -NotePropertyName "CommentTypes" -NotePropertyValue $commentTypes
                }
            }

            $results += $result
        }

        # Trier les résultats par score décroissant
        $results = $results | Sort-Object -Property Score -Descending

        return $results
    } catch {
        Write-Error "Erreur lors du calcul des scores de dépendance : $_"
        return @()
    }
}

function Find-GlobalVariableWithoutExplicitImport {
    <#
    .SYNOPSIS
        Détecte les références aux variables globales spécifiques à des modules sans import explicite.

    .DESCRIPTION
        Cette fonction analyse un script PowerShell pour détecter les références aux variables globales
        qui sont spécifiques à des modules PowerShell, mais pour lesquels le module n'est pas
        explicitement importé dans le script. Elle détecte les références directes aux variables,
        ainsi que les références via des expressions de membre ou d'index.

    .PARAMETER FilePath
        Chemin du fichier PowerShell à analyser.

    .PARAMETER ScriptContent
        Contenu du script PowerShell à analyser. Si ce paramètre est spécifié, FilePath est ignoré.

    .PARAMETER IncludeImportedModules
        Indique si les variables des modules déjà importés doivent être incluses dans les résultats.
        Par défaut, seules les variables des modules non importés sont retournées.

    .PARAMETER IncludeModulePatterns
        Indique si les variables qui suivent des modèles de nommage de modules doivent être incluses
        dans les résultats, même si elles ne sont pas explicitement mappées à un module.

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
                Write-Error "Le fichier spécifié n'existe pas : $FilePath"
                return @()
            }

            $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont été détectées dans le script : $($errors.Count) erreur(s)"
            }
        } else {
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Des erreurs de syntaxe ont été détectées dans le script : $($errors.Count) erreur(s)"
            }
        }

        # Extraire les références aux variables globales
        $variableReferences = Get-GlobalVariableReferencesFromAst -Ast $ast

        # Identifier les modules requis pour chaque variable
        $results = @()
        foreach ($varRef in $variableReferences) {
            $moduleName = $script:GlobalVariableToModuleMapping[$varRef.VariableName]
            $moduleNameFound = $false

            # Si un module est trouvé pour cette variable dans le mapping explicite
            if ($moduleName) {
                $moduleNameFound = $true
            }
            # Si on inclut les modèles de nommage de modules et qu'aucun module n'a été trouvé
            elseif ($IncludeModulePatterns -and -not $moduleNameFound) {
                # Vérifier si la variable suit un modèle de nommage de module
                # Par exemple: $AzureRm*, $Az*, $AD*, $SQL*, etc.
                foreach ($alias in $script:ModuleAliasToModuleMapping.Keys) {
                    if ($varRef.VariableName -like "$alias*") {
                        $moduleName = $script:ModuleAliasToModuleMapping[$alias]
                        $moduleNameFound = $true
                        break
                    }
                }

                # Vérifier si la variable contient le nom d'un module connu
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

            # Si un module a été trouvé pour cette variable
            if ($moduleNameFound -and $moduleName) {
                # Vérifier si le module est importé explicitement
                $isImported = Test-ModuleImported -Ast $ast -ModuleName $moduleName

                # Ajouter au résultat si le module n'est pas importé ou si on inclut tous les modules
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

                    # Ajouter des propriétés supplémentaires si elles existent
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
        Write-Error "Erreur lors de la détection des variables globales sans import explicite : $_"
        return @()
    }
}

function Find-ImplicitModuleDependency {
    <#
    .SYNOPSIS
        Détecte les dépendances implicites de modules dans un script PowerShell.

    .DESCRIPTION
        Cette fonction combine toutes les fonctions de détection de dépendances
        et calcule un score de probabilité pour chaque module détecté, en une seule étape.

    .PARAMETER FilePath
        Chemin du fichier PowerShell à analyser.

    .PARAMETER ScriptContent
        Contenu du script PowerShell à analyser. Si ce paramètre est spécifié, FilePath est ignoré.

    .PARAMETER ScoreThreshold
        Seuil de score à partir duquel une dépendance est considérée comme probable.
        Par défaut, ce seuil est fixé à 0.5 (50%).

    .PARAMETER IncludeImportedModules
        Indique si les modules déjà importés doivent être inclus dans les résultats.
        Par défaut, seuls les modules non importés sont analysés.

    .PARAMETER IncludeDetails
        Indique si les détails du calcul du score doivent être inclus dans les résultats.

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
        # Détecter les références de cmdlets
        $cmdletReferences = if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            Find-CmdletWithoutExplicitImport -FilePath $FilePath -IncludeImportedModules:$IncludeImportedModules
        } else {
            Find-CmdletWithoutExplicitImport -ScriptContent $ScriptContent -IncludeImportedModules:$IncludeImportedModules
        }

        # Détecter les références de types .NET
        $typeReferences = if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            Find-DotNetTypeWithoutExplicitImport -FilePath $FilePath -IncludeImportedModules:$IncludeImportedModules
        } else {
            Find-DotNetTypeWithoutExplicitImport -ScriptContent $ScriptContent -IncludeImportedModules:$IncludeImportedModules
        }

        # Détecter les références de variables globales
        $variableReferences = if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            Find-GlobalVariableWithoutExplicitImport -FilePath $FilePath -IncludeImportedModules:$IncludeImportedModules -IncludeModulePatterns
        } else {
            Find-GlobalVariableWithoutExplicitImport -ScriptContent $ScriptContent -IncludeImportedModules:$IncludeImportedModules -IncludeModulePatterns
        }

        # Détecter les références d'alias de modules
        $aliasReferences = if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            Find-ModuleAliasWithoutExplicitImport -FilePath $FilePath -IncludeImportedModules:$IncludeImportedModules
        } else {
            Find-ModuleAliasWithoutExplicitImport -ScriptContent $ScriptContent -IncludeImportedModules:$IncludeImportedModules
        }

        # Détecter les références aux modules dans les commentaires
        $commentReferences = if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            Find-ModuleReferenceInComments -FilePath $FilePath -IncludeImportedModules:$IncludeImportedModules
        } else {
            Find-ModuleReferenceInComments -ScriptContent $ScriptContent -IncludeImportedModules:$IncludeImportedModules
        }

        # Convertir les références d'alias en format compatible avec Get-ModuleDependencyScore
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

        # Convertir les références de commentaires en format compatible avec Get-ModuleDependencyScore
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

        # Calculer les scores de dépendance
        $scores = Get-ModuleDependencyScore -CmdletReferences $cmdletReferences -TypeReferences $typeReferences -VariableReferences $variableReferences -AliasReferences $aliasReferencesForScore -CommentReferences $commentReferencesForScore -ScoreThreshold $ScoreThreshold -IncludeDetails:$IncludeDetails

        # Retourner les résultats
        return $scores
    } catch {
        Write-Error "Erreur lors de la détection des dépendances implicites : $_"
        return @()
    }
}

function Test-ModuleAvailability {
    <#
    .SYNOPSIS
        Vérifie la disponibilité des modules détectés.

    .DESCRIPTION
        Cette fonction vérifie si les modules détectés sont disponibles sur le système,
        soit déjà importés, soit disponibles pour importation. Elle peut également
        vérifier si les modules sont disponibles dans la galerie PowerShell.

    .PARAMETER ModuleNames
        Noms des modules à vérifier.

    .PARAMETER CheckGallery
        Indique si la disponibilité des modules dans la galerie PowerShell doit être vérifiée.
        Par défaut, seule la disponibilité locale est vérifiée.

    .PARAMETER IncludeDetails
        Indique si des détails supplémentaires sur les modules doivent être inclus dans les résultats.

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
        # Obtenir la liste des modules importés
        $importedModules = Get-Module

        # Obtenir la liste des modules disponibles
        $availableModules = Get-Module -ListAvailable

        # Initialiser les résultats
        $results = @()

        foreach ($moduleName in $ModuleNames) {
            # Vérifier si le module est déjà importé
            $isImported = $importedModules | Where-Object { $_.Name -eq $moduleName }

            # Vérifier si le module est disponible localement
            $isAvailable = $availableModules | Where-Object { $_.Name -eq $moduleName }

            # Initialiser les variables pour la galerie
            $isInGallery = $null
            $galleryVersion = $null
            $galleryDetails = $null

            # Vérifier si le module est disponible dans la galerie PowerShell
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

            # Créer l'objet résultat
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

            # Ajouter des détails supplémentaires si demandé
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
        Write-Error "Erreur lors de la vérification de la disponibilité des modules : $_"
        return @()
    }
}

function Confirm-ModuleDependencies {
    <#
    .SYNOPSIS
        Valide les dépendances de modules détectées et propose des actions correctives.

    .DESCRIPTION
        Cette fonction analyse les résultats de la détection de dépendances implicites,
        vérifie la disponibilité des modules requis, et propose des actions correctives
        comme l'ajout d'instructions Import-Module ou l'installation de modules manquants.

    .PARAMETER FilePath
        Chemin du fichier PowerShell à analyser.

    .PARAMETER ScriptContent
        Contenu du script PowerShell à analyser. Si ce paramètre est spécifié, FilePath est ignoré.

    .PARAMETER ScoreThreshold
        Seuil de score à partir duquel une dépendance est considérée comme probable.
        Par défaut, ce seuil est fixé à 0.5 (50%).

    .PARAMETER CheckGallery
        Indique si la disponibilité des modules dans la galerie PowerShell doit être vérifiée.
        Par défaut, seule la disponibilité locale est vérifiée.

    .PARAMETER GenerateImportStatements
        Indique si des instructions Import-Module doivent être générées pour les modules manquants.

    .PARAMETER IncludeDetails
        Indique si des détails supplémentaires doivent être inclus dans les résultats.

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
        # Détecter les dépendances implicites
        $dependencies = if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            Find-ImplicitModuleDependency -FilePath $FilePath -ScoreThreshold $ScoreThreshold -IncludeDetails:$IncludeDetails
        } else {
            Find-ImplicitModuleDependency -ScriptContent $ScriptContent -ScoreThreshold $ScoreThreshold -IncludeDetails:$IncludeDetails
        }

        # Filtrer les dépendances probables
        $probableDependencies = $dependencies | Where-Object { $_.IsProbablyRequired }

        # Si aucune dépendance probable n'est trouvée
        if (-not $probableDependencies -or $probableDependencies.Count -eq 0) {
            return [PSCustomObject]@{
                Status            = "NoDependenciesFound"
                Message           = "Aucune dépendance implicite probable n'a été détectée."
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

        # Vérifier la disponibilité des modules
        $moduleAvailability = Test-ModuleAvailability -ModuleNames $moduleNames -CheckGallery:$CheckGallery -IncludeDetails:$IncludeDetails

        # Séparer les modules validés et manquants
        $validatedModules = $moduleAvailability | Where-Object { $_.ValidationPassed }
        $missingModules = $moduleAvailability | Where-Object { -not $_.ValidationPassed }

        # Générer des instructions Import-Module si demandé
        $importStatements = @()
        if ($GenerateImportStatements) {
            foreach ($module in $validatedModules) {
                $importStatements += "Import-Module -Name '$($module.ModuleName)' -ErrorAction Stop"
            }
        }

        # Générer des instructions d'installation pour les modules manquants
        $installStatements = @()
        foreach ($module in $missingModules) {
            if ($module.IsInGallery) {
                $installStatements += "Install-Module -Name '$($module.ModuleName)' -Scope CurrentUser -Force"
            }
        }

        # Déterminer le statut global
        $status = if ($missingModules.Count -eq 0) {
            "AllModulesAvailable"
        } elseif ($missingModules | Where-Object { $_.IsInGallery }) {
            "SomeModulesNeedInstallation"
        } else {
            "SomeModulesNotFound"
        }

        # Créer le message approprié
        $message = switch ($status) {
            "AllModulesAvailable" {
                "Tous les modules requis sont disponibles. Ajoutez des instructions Import-Module pour les utiliser explicitement."
            }
            "SomeModulesNeedInstallation" {
                "Certains modules requis ne sont pas installés mais sont disponibles dans la galerie PowerShell. Installez-les avant d'utiliser le script."
            }
            "SomeModulesNotFound" {
                "Certains modules requis n'ont pas été trouvés, ni localement ni dans la galerie PowerShell. Vérifiez les noms des modules ou leur disponibilité."
            }
        }

        # Créer l'objet résultat
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
        Write-Error "Erreur lors de la validation des dépendances de modules : $_"
        return $null
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Find-CmdletWithoutExplicitImport, Find-DotNetTypeWithoutExplicitImport, Find-GlobalVariableWithoutExplicitImport, Find-ModuleAliasWithoutExplicitImport, Find-ModuleReferenceInComments, Test-ModuleAvailability, Confirm-ModuleDependencies, New-ModuleMappingDatabase, Update-ModuleMappingDatabase, Import-ModuleMappingDatabase, Get-ModuleDependencyScore, Find-ImplicitModuleDependency
