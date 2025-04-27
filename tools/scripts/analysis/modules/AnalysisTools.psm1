#Requires -Version 5.1
<#
.SYNOPSIS
    Module fournissant des fonctions pour interagir avec diffÃ©rents outils d'analyse.

.DESCRIPTION
    Ce module fournit des fonctions pour exÃ©cuter des analyses avec diffÃ©rents outils
    comme PSScriptAnalyzer, ESLint, Pylint, SonarQube, etc. et convertir leurs rÃ©sultats
    vers un format unifiÃ©.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  15/04/2025
#>

# Importer les modules requis
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "UnifiedResultsFormat.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module -Name $modulePath -Force
} else {
    throw "Module UnifiedResultsFormat.psm1 introuvable."
}

# Fonction pour vÃ©rifier si un outil est disponible
function Test-AnalysisTool {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("PSScriptAnalyzer", "ESLint", "Pylint", "SonarQube")]
        [string]$ToolName
    )

    switch ($ToolName) {
        "PSScriptAnalyzer" {
            $module = Get-Module -Name PSScriptAnalyzer -ListAvailable
            return $null -ne $module
        }
        "ESLint" {
            $eslint = Get-Command -Name eslint -ErrorAction SilentlyContinue
            if ($null -eq $eslint) {
                $eslint = Get-Command -Name "node_modules\.bin\eslint.cmd" -ErrorAction SilentlyContinue
            }
            return $null -ne $eslint
        }
        "Pylint" {
            $pylint = Get-Command -Name pylint -ErrorAction SilentlyContinue
            if ($null -eq $pylint) {
                $pylint = Get-Command -Name "python" -ErrorAction SilentlyContinue
                if ($null -ne $pylint) {
                    try {
                        $output = & python -c "import pylint; print('OK')" 2>$null
                        return $output -eq "OK"
                    } catch {
                        return $false
                    }
                }
            }
            return $null -ne $pylint
        }
        "SonarQube" {
            $sonarScanner = Get-Command -Name "sonar-scanner" -ErrorAction SilentlyContinue
            return $null -ne $sonarScanner
        }
        default {
            return $false
        }
    }
}

# Fonction pour exÃ©cuter PSScriptAnalyzer
function Invoke-PSScriptAnalyzerTool {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string[]]$IncludeRule = @(),

        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeRule = @(),

        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warning", "Information", "All")]
        [string[]]$Severity = @("Error", "Warning", "Information"),

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$ReturnUnifiedFormat = $true
    )

    # VÃ©rifier si PSScriptAnalyzer est disponible
    if (-not (Test-AnalysisTool -ToolName "PSScriptAnalyzer")) {
        Write-Error "PSScriptAnalyzer n'est pas disponible. Installez-le avec 'Install-Module -Name PSScriptAnalyzer'."
        return $null
    }

    # Importer le module PSScriptAnalyzer
    Import-Module -Name PSScriptAnalyzer -Force

    # PrÃ©parer les paramÃ¨tres pour Invoke-ScriptAnalyzer
    $params = @{
        Path = $FilePath
    }

    if ($IncludeRule.Count -gt 0) {
        $params["IncludeRule"] = $IncludeRule
    }

    if ($ExcludeRule.Count -gt 0) {
        $params["ExcludeRule"] = $ExcludeRule
    }

    if ($Severity -notcontains "All") {
        $params["Severity"] = $Severity
    }

    if ($Recurse) {
        $params["Recurse"] = $true
    }

    # ExÃ©cuter PSScriptAnalyzer
    try {
        $results = Invoke-ScriptAnalyzer @params

        # Convertir les rÃ©sultats vers le format unifiÃ© si demandÃ©
        if ($ReturnUnifiedFormat) {
            return ConvertFrom-PSScriptAnalyzerResult -Results $results
        } else {
            return $results
        }
    } catch {
        Write-Error "Erreur lors de l'exÃ©cution de PSScriptAnalyzer: $_"
        return $null
    }
}

# Fonction pour exÃ©cuter ESLint
function Invoke-ESLintTool {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$ConfigFile = "",

        [Parameter(Mandatory = $false)]
        [switch]$Fix,

        [Parameter(Mandatory = $false)]
        [switch]$ReturnUnifiedFormat = $true
    )

    # VÃ©rifier si ESLint est disponible
    if (-not (Test-AnalysisTool -ToolName "ESLint")) {
        Write-Error "ESLint n'est pas disponible. Installez-le avec 'npm install -g eslint'."
        return $null
    }

    # PrÃ©parer la commande ESLint
    $eslintCommand = "eslint"
    $eslintArgs = @("--format", "json")

    if ($ConfigFile) {
        $eslintArgs += "--config"
        $eslintArgs += $ConfigFile
    }

    if ($Fix) {
        $eslintArgs += "--fix"
    }

    $eslintArgs += $FilePath

    # ExÃ©cuter ESLint
    try {
        $output = & $eslintCommand $eslintArgs 2>&1

        # VÃ©rifier si l'exÃ©cution a rÃ©ussi
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) {
            # ESLint retourne 1 s'il trouve des problÃ¨mes, ce qui est normal
            Write-Error "Erreur lors de l'exÃ©cution d'ESLint (code $LASTEXITCODE): $output"
            return $null
        }

        # Convertir la sortie JSON en objet PowerShell
        $results = $output | ConvertFrom-Json

        # Convertir les rÃ©sultats vers le format unifiÃ© si demandÃ©
        if ($ReturnUnifiedFormat) {
            return ConvertFrom-ESLintResult -Results $results
        } else {
            return $results
        }
    } catch {
        Write-Error "Erreur lors de l'exÃ©cution d'ESLint: $_"
        return $null
    }
}

# Fonction pour exÃ©cuter Pylint
function Invoke-PylintTool {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$ConfigFile = "",

        [Parameter(Mandatory = $false)]
        [string[]]$DisableRules = @(),

        [Parameter(Mandatory = $false)]
        [string[]]$EnableRules = @(),

        [Parameter(Mandatory = $false)]
        [switch]$ReturnUnifiedFormat = $true
    )

    # VÃ©rifier si Pylint est disponible
    if (-not (Test-AnalysisTool -ToolName "Pylint")) {
        Write-Error "Pylint n'est pas disponible. Installez-le avec 'pip install pylint'."
        return $null
    }

    # PrÃ©parer la commande Pylint
    $pylintCommand = "pylint"
    $pylintArgs = @("--output-format=text")

    if ($ConfigFile) {
        $pylintArgs += "--rcfile=$ConfigFile"
    }

    if ($DisableRules.Count -gt 0) {
        $pylintArgs += "--disable=$($DisableRules -join ',')"
    }

    if ($EnableRules.Count -gt 0) {
        $pylintArgs += "--enable=$($EnableRules -join ',')"
    }

    $pylintArgs += $FilePath

    # ExÃ©cuter Pylint
    try {
        $output = & $pylintCommand $pylintArgs 2>&1

        # Pylint retourne diffÃ©rents codes selon le nombre d'erreurs trouvÃ©es
        # 0 = pas d'erreur, 1-15 = erreurs, 16 = erreur fatale, 32 = erreur d'utilisation
        if ($LASTEXITCODE -gt 15) {
            Write-Error "Erreur lors de l'exÃ©cution de Pylint (code $LASTEXITCODE): $output"
            return $null
        }

        # Filtrer les lignes de sortie pour ne garder que les messages d'erreur
        $results = $output | Where-Object { $_ -match '.*?:\d+:\d+: \[.*?\]' }

        # Convertir les rÃ©sultats vers le format unifiÃ© si demandÃ©
        if ($ReturnUnifiedFormat) {
            return ConvertFrom-PylintResult -Results $results
        } else {
            return $results
        }
    } catch {
        Write-Error "Erreur lors de l'exÃ©cution de Pylint: $_"
        return $null
    }
}

# Fonction pour exÃ©cuter SonarQube
function Invoke-SonarQubeTool {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectKey,

        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $true)]
        [string]$ProjectVersion,

        [Parameter(Mandatory = $true)]
        [string]$SourceDirectory,

        [Parameter(Mandatory = $false)]
        [string]$SonarQubeUrl = "http://localhost:9000",

        [Parameter(Mandatory = $false)]
        [string]$Token = "",

        [Parameter(Mandatory = $false)]
        [switch]$ReturnUnifiedFormat = $true
    )

    # VÃ©rifier si SonarQube Scanner est disponible
    if (-not (Test-AnalysisTool -ToolName "SonarQube")) {
        Write-Error "SonarQube Scanner n'est pas disponible. Installez-le et ajoutez-le au PATH."
        return $null
    }

    # PrÃ©parer la commande SonarQube Scanner
    $sonarScannerCommand = "sonar-scanner"
    $sonarScannerArgs = @(
        "-Dsonar.projectKey=$ProjectKey",
        "-Dsonar.projectName=$ProjectName",
        "-Dsonar.projectVersion=$ProjectVersion",
        "-Dsonar.sources=$SourceDirectory",
        "-Dsonar.host.url=$SonarQubeUrl"
    )

    if ($Token) {
        $sonarScannerArgs += "-Dsonar.login=$Token"
    }

    # ExÃ©cuter SonarQube Scanner
    try {
        $output = & $sonarScannerCommand $sonarScannerArgs 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Erreur lors de l'exÃ©cution de SonarQube Scanner (code $LASTEXITCODE): $output"
            return $null
        }

        # RÃ©cupÃ©rer les rÃ©sultats de l'analyse depuis l'API SonarQube
        $apiUrl = "$SonarQubeUrl/api/issues/search?projectKeys=$ProjectKey&resolved=false"
        $headers = @{}

        if ($Token) {
            $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Token}:"))
            $headers["Authorization"] = "Basic $base64Auth"
        }

        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get

        # Convertir les rÃ©sultats vers le format unifiÃ© si demandÃ©
        if ($ReturnUnifiedFormat) {
            return ConvertFrom-SonarQubeResult -Results $response
        } else {
            return $response
        }
    } catch {
        Write-Error "Erreur lors de l'exÃ©cution de SonarQube Scanner ou de la rÃ©cupÃ©ration des rÃ©sultats: $_"
        return $null
    }
}

# Fonction pour analyser un fichier avec l'outil appropriÃ© en fonction de son extension
function Invoke-FileAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Auto", "PSScriptAnalyzer", "ESLint", "Pylint")]
        [string]$Tool = "Auto",

        [Parameter(Mandatory = $false)]
        [hashtable]$ToolParameters = @{},

        [Parameter(Mandatory = $false)]
        [switch]$ReturnUnifiedFormat = $true
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        return $null
    }

    # DÃ©terminer l'outil Ã  utiliser en fonction de l'extension du fichier si Auto
    if ($Tool -eq "Auto") {
        $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

        switch ($extension) {
            { $_ -in ".ps1", ".psm1", ".psd1" } {
                $Tool = "PSScriptAnalyzer"
            }
            { $_ -in ".js", ".jsx", ".ts", ".tsx", ".vue" } {
                $Tool = "ESLint"
            }
            { $_ -in ".py" } {
                $Tool = "Pylint"
            }
            default {
                Write-Warning "Extension de fichier '$extension' non reconnue. Utilisation de PSScriptAnalyzer par dÃ©faut."
                $Tool = "PSScriptAnalyzer"
            }
        }
    }

    # ExÃ©cuter l'outil appropriÃ©
    switch ($Tool) {
        "PSScriptAnalyzer" {
            $params = @{
                FilePath            = $FilePath
                ReturnUnifiedFormat = $ReturnUnifiedFormat
            }

            # Ajouter les paramÃ¨tres spÃ©cifiques Ã  PSScriptAnalyzer
            foreach ($key in $ToolParameters.Keys) {
                if ($key -in @("IncludeRule", "ExcludeRule", "Severity", "Recurse")) {
                    $params[$key] = $ToolParameters[$key]
                }
            }

            return Invoke-PSScriptAnalyzerTool @params
        }
        "ESLint" {
            $params = @{
                FilePath            = $FilePath
                ReturnUnifiedFormat = $ReturnUnifiedFormat
            }

            # Ajouter les paramÃ¨tres spÃ©cifiques Ã  ESLint
            foreach ($key in $ToolParameters.Keys) {
                if ($key -in @("ConfigFile", "Fix")) {
                    $params[$key] = $ToolParameters[$key]
                }
            }

            return Invoke-ESLintTool @params
        }
        "Pylint" {
            $params = @{
                FilePath            = $FilePath
                ReturnUnifiedFormat = $ReturnUnifiedFormat
            }

            # Ajouter les paramÃ¨tres spÃ©cifiques Ã  Pylint
            foreach ($key in $ToolParameters.Keys) {
                if ($key -in @("ConfigFile", "DisableRules", "EnableRules")) {
                    $params[$key] = $ToolParameters[$key]
                }
            }

            return Invoke-PylintTool @params
        }
        default {
            Write-Error "Outil d'analyse '$Tool' non pris en charge."
            return $null
        }
    }
}

# Fonction pour analyser un rÃ©pertoire avec les outils appropriÃ©s
function Invoke-DirectoryAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath,

        [Parameter(Mandatory = $false)]
        [string[]]$Include = @("*.ps1", "*.psm1", "*.psd1", "*.js", "*.jsx", "*.ts", "*.tsx", "*.vue", "*.py"),

        [Parameter(Mandatory = $false)]
        [string[]]$Exclude = @(),

        [Parameter(Mandatory = $false)]
        [hashtable]$ToolParameters = @{},

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$ReturnUnifiedFormat = $true
    )

    # VÃ©rifier si le rÃ©pertoire existe
    if (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
        Write-Error "Le rÃ©pertoire '$DirectoryPath' n'existe pas."
        return $null
    }

    # RÃ©cupÃ©rer tous les fichiers Ã  analyser
    $getChildItemParams = @{
        Path    = $DirectoryPath
        Include = $Include
        File    = $true
    }

    if ($Recurse) {
        $getChildItemParams["Recurse"] = $true
    }

    $files = Get-ChildItem @getChildItemParams

    # Filtrer les fichiers exclus
    if ($Exclude.Count -gt 0) {
        $files = $files | Where-Object {
            $file = $_
            -not ($Exclude | Where-Object { $file.FullName -like $_ })
        }
    }

    # Analyser chaque fichier
    $results = @()

    foreach ($file in $files) {
        Write-Verbose "Analyse du fichier: $($file.FullName)"

        $fileResults = Invoke-FileAnalysis -FilePath $file.FullName -Tool "Auto" -ToolParameters $ToolParameters -ReturnUnifiedFormat $ReturnUnifiedFormat

        if ($null -ne $fileResults) {
            $results += $fileResults
        }
    }

    return $results
}

# Exporter les fonctions du module
Export-ModuleMember -Function Test-AnalysisTool
Export-ModuleMember -Function Invoke-PSScriptAnalyzerTool
Export-ModuleMember -Function Invoke-ESLintTool
Export-ModuleMember -Function Invoke-PylintTool
Export-ModuleMember -Function Invoke-SonarQubeTool
Export-ModuleMember -Function Invoke-FileAnalysis
Export-ModuleMember -Function Invoke-DirectoryAnalysis
