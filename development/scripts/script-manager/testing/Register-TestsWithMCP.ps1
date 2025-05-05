#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre les tests du script manager avec MCP Desktop Commander.
.DESCRIPTION
    Ce script enregistre les tests du script manager avec MCP Desktop Commander
    pour une exÃ©cution plus facile.
.PARAMETER MCPPath
    Chemin du dossier MCP Desktop Commander.
.EXAMPLE
    .\Register-TestsWithMCP.ps1 -MCPPath "D:\MCP"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [string]$MCPPath
)

# Fonction pour Ã©crire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

# VÃ©rifier si MCP Desktop Commander existe
if (-not (Test-Path -Path $MCPPath)) {
    Write-Log "MCP Desktop Commander n'existe pas Ã  l'emplacement spÃ©cifiÃ©: $MCPPath" -Level "ERROR"
    exit 1
}

# VÃ©rifier si le dossier de configuration MCP existe
$mcpConfigPath = Join-Path -Path $MCPPath -ChildPath "config"
if (-not (Test-Path -Path $mcpConfigPath)) {
    if ($PSCmdlet.ShouldProcess($mcpConfigPath, "CrÃ©er le dossier de configuration MCP")) {
        New-Item -Path $mcpConfigPath -ItemType Directory -Force | Out-Null
    }
}

# VÃ©rifier si le dossier de scripts MCP existe
$mcpScriptsPath = Join-Path -Path $MCPPath -ChildPath "scripts"
if (-not (Test-Path -Path $mcpScriptsPath)) {
    if ($PSCmdlet.ShouldProcess($mcpScriptsPath, "CrÃ©er le dossier de scripts MCP")) {
        New-Item -Path $mcpScriptsPath -ItemType Directory -Force | Out-Null
    }
}

# VÃ©rifier si le dossier de tests MCP existe
$mcpTestsPath = Join-Path -Path $mcpScriptsPath -ChildPath "tests"
if (-not (Test-Path -Path $mcpTestsPath)) {
    if ($PSCmdlet.ShouldProcess($mcpTestsPath, "CrÃ©er le dossier de tests MCP")) {
        New-Item -Path $mcpTestsPath -ItemType Directory -Force | Out-Null
    }
}

# VÃ©rifier si le dossier de tests du script manager existe
$mcpManagerTestsPath = Join-Path -Path $mcpTestsPath -ChildPath "manager"
if (-not (Test-Path -Path $mcpManagerTestsPath)) {
    if ($PSCmdlet.ShouldProcess($mcpManagerTestsPath, "CrÃ©er le dossier de tests du script manager")) {
        New-Item -Path $mcpManagerTestsPath -ItemType Directory -Force | Out-Null
    }
}

# CrÃ©er le fichier de configuration MCP pour les tests du script manager
$mcpConfigFile = Join-Path -Path $mcpConfigPath -ChildPath "manager-tests.json"
$mcpConfig = @{
    name = "Tests du script manager"
    description = "Tests unitaires pour le script manager"
    version = "1.0.0"
    author = "EMAIL_SENDER_1 Team"
    category = "Testing"
    tags = @("tests", "manager", "scripts")
    commands = @(
        @{
            name = "Run-AllTests"
            description = "ExÃ©cute tous les tests du script manager"
            script = "tests/manager/Run-AllTests.ps1"
            parameters = @(
                @{
                    name = "OutputPath"
                    description = "Chemin du dossier pour les rapports de tests"
                    type = "string"
                    default = "./reports/tests"
                },
                @{
                    name = "GenerateHTML"
                    description = "GÃ©nÃ¨re un rapport HTML des rÃ©sultats des tests"
                    type = "switch"
                    default = $false
                }
            )
        },
        @{
            name = "Run-SimplifiedTests"
            description = "ExÃ©cute les tests simplifiÃ©s du script manager"
            script = "tests/manager/Run-SimplifiedTests.ps1"
            parameters = @(
                @{
                    name = "OutputPath"
                    description = "Chemin du dossier pour les rapports de tests"
                    type = "string"
                    default = "./reports/tests"
                },
                @{
                    name = "GenerateHTML"
                    description = "GÃ©nÃ¨re un rapport HTML des rÃ©sultats des tests"
                    type = "switch"
                    default = $false
                }
            )
        },
        @{
            name = "Run-FixedTests"
            description = "ExÃ©cute les tests corrigÃ©s du script manager"
            script = "tests/manager/Run-FixedTests.ps1"
            parameters = @(
                @{
                    name = "OutputPath"
                    description = "Chemin du dossier pour les rapports de tests"
                    type = "string"
                    default = "./reports/tests"
                },
                @{
                    name = "GenerateHTML"
                    description = "GÃ©nÃ¨re un rapport HTML des rÃ©sultats des tests"
                    type = "switch"
                    default = $false
                },
                @{
                    name = "TestName"
                    description = "Nom du test Ã  exÃ©cuter"
                    type = "string"
                    default = ""
                }
            )
        },
        @{
            name = "Run-PerformanceTests"
            description = "ExÃ©cute des tests de performance pour le script manager"
            script = "tests/manager/Run-PerformanceTests.ps1"
            parameters = @(
                @{
                    name = "OutputPath"
                    description = "Chemin du dossier pour les rapports de tests"
                    type = "string"
                    default = "./reports/performance"
                },
                @{
                    name = "Iterations"
                    description = "Nombre d'itÃ©rations pour chaque test de performance"
                    type = "int"
                    default = 5
                },
                @{
                    name = "GenerateHTML"
                    description = "GÃ©nÃ¨re un rapport HTML des rÃ©sultats des tests"
                    type = "switch"
                    default = $false
                }
            )
        },
        @{
            name = "Run-ParameterizedTests"
            description = "ExÃ©cute des tests paramÃ©trÃ©s pour le script manager"
            script = "tests/manager/Run-ParameterizedTests.ps1"
            parameters = @(
                @{
                    name = "OutputPath"
                    description = "Chemin du dossier pour les rapports de tests"
                    type = "string"
                    default = "./reports/tests"
                },
                @{
                    name = "GenerateHTML"
                    description = "GÃ©nÃ¨re un rapport HTML des rÃ©sultats des tests"
                    type = "switch"
                    default = $false
                }
            )
        },
        @{
            name = "Run-MutationTests"
            description = "ExÃ©cute des tests de mutation pour le script manager"
            script = "tests/manager/Run-MutationTests.ps1"
            parameters = @(
                @{
                    name = "OutputPath"
                    description = "Chemin du dossier pour les rapports de tests"
                    type = "string"
                    default = "./reports/mutation"
                },
                @{
                    name = "GenerateHTML"
                    description = "GÃ©nÃ¨re un rapport HTML des rÃ©sultats des tests"
                    type = "switch"
                    default = $false
                },
                @{
                    name = "MaxMutations"
                    description = "Nombre maximum de mutations Ã  effectuer"
                    type = "int"
                    default = 5
                }
            )
        },
        @{
            name = "Generate-TestDocumentation"
            description = "GÃ©nÃ¨re la documentation des tests unitaires du script manager"
            script = "tests/manager/Generate-TestDocumentation.ps1"
            parameters = @(
                @{
                    name = "OutputPath"
                    description = "Chemin du dossier pour la documentation"
                    type = "string"
                    default = "./docs/tests"
                }
            )
        }
    )
}

if ($PSCmdlet.ShouldProcess($mcpConfigFile, "CrÃ©er le fichier de configuration MCP")) {
    $mcpConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $mcpConfigFile -Encoding utf8
    Write-Log "Fichier de configuration MCP crÃ©Ã©: $mcpConfigFile" -Level "SUCCESS"
}

# Copier les scripts de test dans le dossier MCP
$testScripts = @(
    "Run-AllManagerTests.ps1",
    "Run-SimplifiedTests.ps1",
    "Run-FixedTests.ps1",
    "Run-PerformanceTests.ps1",
    "Run-ParameterizedTests.ps1",
    "Run-MutationTests.ps1",
    "Generate-TestDocumentation.ps1"
)

foreach ($script in $testScripts) {
    $sourcePath = Join-Path -Path $PSScriptRoot -ChildPath $script
    $destinationPath = Join-Path -Path $mcpManagerTestsPath -ChildPath $script.Replace("Manager", "")
    
    if (Test-Path -Path $sourcePath) {
        if ($PSCmdlet.ShouldProcess($destinationPath, "Copier le script de test")) {
            Copy-Item -Path $sourcePath -Destination $destinationPath -Force
            Write-Log "Script de test copiÃ©: $destinationPath" -Level "SUCCESS"
        }
    }
    else {
        Write-Log "Script de test non trouvÃ©: $sourcePath" -Level "WARNING"
    }
}

Write-Log "Enregistrement des tests avec MCP Desktop Commander terminÃ©." -Level "SUCCESS"
Write-Log "Pour exÃ©cuter les tests, ouvrez MCP Desktop Commander et sÃ©lectionnez 'Tests du script manager' dans la liste des commandes." -Level "INFO"
