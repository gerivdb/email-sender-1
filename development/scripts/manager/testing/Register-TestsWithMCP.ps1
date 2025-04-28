#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre les tests du script manager avec MCP Desktop Commander.
.DESCRIPTION
    Ce script enregistre les tests du script manager avec MCP Desktop Commander
    pour une exécution plus facile.
.PARAMETER MCPPath
    Chemin du dossier MCP Desktop Commander.
.EXAMPLE
    .\Register-TestsWithMCP.ps1 -MCPPath "D:\MCP"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-15
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [string]$MCPPath
)

# Fonction pour écrire dans le journal
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

# Vérifier si MCP Desktop Commander existe
if (-not (Test-Path -Path $MCPPath)) {
    Write-Log "MCP Desktop Commander n'existe pas à l'emplacement spécifié: $MCPPath" -Level "ERROR"
    exit 1
}

# Vérifier si le dossier de configuration MCP existe
$mcpConfigPath = Join-Path -Path $MCPPath -ChildPath "config"
if (-not (Test-Path -Path $mcpConfigPath)) {
    if ($PSCmdlet.ShouldProcess($mcpConfigPath, "Créer le dossier de configuration MCP")) {
        New-Item -Path $mcpConfigPath -ItemType Directory -Force | Out-Null
    }
}

# Vérifier si le dossier de scripts MCP existe
$mcpScriptsPath = Join-Path -Path $MCPPath -ChildPath "scripts"
if (-not (Test-Path -Path $mcpScriptsPath)) {
    if ($PSCmdlet.ShouldProcess($mcpScriptsPath, "Créer le dossier de scripts MCP")) {
        New-Item -Path $mcpScriptsPath -ItemType Directory -Force | Out-Null
    }
}

# Vérifier si le dossier de tests MCP existe
$mcpTestsPath = Join-Path -Path $mcpScriptsPath -ChildPath "tests"
if (-not (Test-Path -Path $mcpTestsPath)) {
    if ($PSCmdlet.ShouldProcess($mcpTestsPath, "Créer le dossier de tests MCP")) {
        New-Item -Path $mcpTestsPath -ItemType Directory -Force | Out-Null
    }
}

# Vérifier si le dossier de tests du script manager existe
$mcpManagerTestsPath = Join-Path -Path $mcpTestsPath -ChildPath "manager"
if (-not (Test-Path -Path $mcpManagerTestsPath)) {
    if ($PSCmdlet.ShouldProcess($mcpManagerTestsPath, "Créer le dossier de tests du script manager")) {
        New-Item -Path $mcpManagerTestsPath -ItemType Directory -Force | Out-Null
    }
}

# Créer le fichier de configuration MCP pour les tests du script manager
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
            description = "Exécute tous les tests du script manager"
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
                    description = "Génère un rapport HTML des résultats des tests"
                    type = "switch"
                    default = $false
                }
            )
        },
        @{
            name = "Run-SimplifiedTests"
            description = "Exécute les tests simplifiés du script manager"
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
                    description = "Génère un rapport HTML des résultats des tests"
                    type = "switch"
                    default = $false
                }
            )
        },
        @{
            name = "Run-FixedTests"
            description = "Exécute les tests corrigés du script manager"
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
                    description = "Génère un rapport HTML des résultats des tests"
                    type = "switch"
                    default = $false
                },
                @{
                    name = "TestName"
                    description = "Nom du test à exécuter"
                    type = "string"
                    default = ""
                }
            )
        },
        @{
            name = "Run-PerformanceTests"
            description = "Exécute des tests de performance pour le script manager"
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
                    description = "Nombre d'itérations pour chaque test de performance"
                    type = "int"
                    default = 5
                },
                @{
                    name = "GenerateHTML"
                    description = "Génère un rapport HTML des résultats des tests"
                    type = "switch"
                    default = $false
                }
            )
        },
        @{
            name = "Run-ParameterizedTests"
            description = "Exécute des tests paramétrés pour le script manager"
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
                    description = "Génère un rapport HTML des résultats des tests"
                    type = "switch"
                    default = $false
                }
            )
        },
        @{
            name = "Run-MutationTests"
            description = "Exécute des tests de mutation pour le script manager"
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
                    description = "Génère un rapport HTML des résultats des tests"
                    type = "switch"
                    default = $false
                },
                @{
                    name = "MaxMutations"
                    description = "Nombre maximum de mutations à effectuer"
                    type = "int"
                    default = 5
                }
            )
        },
        @{
            name = "Generate-TestDocumentation"
            description = "Génère la documentation des tests unitaires du script manager"
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

if ($PSCmdlet.ShouldProcess($mcpConfigFile, "Créer le fichier de configuration MCP")) {
    $mcpConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $mcpConfigFile -Encoding utf8
    Write-Log "Fichier de configuration MCP créé: $mcpConfigFile" -Level "SUCCESS"
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
            Write-Log "Script de test copié: $destinationPath" -Level "SUCCESS"
        }
    }
    else {
        Write-Log "Script de test non trouvé: $sourcePath" -Level "WARNING"
    }
}

Write-Log "Enregistrement des tests avec MCP Desktop Commander terminé." -Level "SUCCESS"
Write-Log "Pour exécuter les tests, ouvrez MCP Desktop Commander et sélectionnez 'Tests du script manager' dans la liste des commandes." -Level "INFO"
