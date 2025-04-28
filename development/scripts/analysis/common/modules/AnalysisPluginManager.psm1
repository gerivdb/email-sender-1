#Requires -Version 5.1
<#
.SYNOPSIS
    Module de gestion des plugins d'analyse pour l'intÃ©gration avec des outils tiers.

.DESCRIPTION
    Ce module fournit des fonctions pour enregistrer, dÃ©couvrir et exÃ©cuter des plugins
    d'analyse qui intÃ¨grent des outils tiers comme PSScriptAnalyzer, ESLint, Pylint, etc.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  15/04/2025
#>

# Structure de donnÃ©es pour stocker les plugins enregistrÃ©s
$script:AnalysisPlugins = @{}

# RÃ©pertoire par dÃ©faut pour les plugins
$script:DefaultPluginDirectory = Join-Path -Path $PSScriptRoot -ChildPath "../plugins"

# Fonction pour enregistrer un nouveau plugin d'analyse
function Register-AnalysisPlugin {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $true)]
        [string]$Version,
        
        [Parameter(Mandatory = $true)]
        [string]$Author,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("PowerShell", "JavaScript", "Python", "Generic")]
        [string]$Language,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$AnalyzeFunction,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$ConvertFunction = $null,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Configuration = @{},
        
        [Parameter(Mandatory = $false)]
        [string[]]$Dependencies = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # VÃ©rifier si le plugin existe dÃ©jÃ 
    if ($script:AnalysisPlugins.ContainsKey($Name) -and -not $Force) {
        Write-Error "Un plugin avec le nom '$Name' existe dÃ©jÃ . Utilisez -Force pour remplacer."
        return $false
    }
    
    # CrÃ©er l'objet plugin
    $plugin = [PSCustomObject]@{
        Name = $Name
        Description = $Description
        Version = $Version
        Author = $Author
        Language = $Language
        AnalyzeFunction = $AnalyzeFunction
        ConvertFunction = $ConvertFunction
        Configuration = $Configuration
        Dependencies = $Dependencies
        Enabled = $true
        LastExecutionTime = $null
        ExecutionCount = 0
        AverageExecutionTime = 0
    }
    
    # Enregistrer le plugin
    if ($PSCmdlet.ShouldProcess("Plugin $Name", "Enregistrer")) {
        $script:AnalysisPlugins[$Name] = $plugin
        Write-Verbose "Plugin '$Name' enregistrÃ© avec succÃ¨s."
        return $true
    }
    
    return $false
}

# Fonction pour obtenir un plugin enregistrÃ©
function Get-AnalysisPlugin {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("PowerShell", "JavaScript", "Python", "Generic", "All")]
        [string]$Language = "All",
        
        [Parameter(Mandatory = $false)]
        [switch]$EnabledOnly
    )
    
    # Si un nom est spÃ©cifiÃ©, retourner ce plugin spÃ©cifique
    if ($Name) {
        if ($script:AnalysisPlugins.ContainsKey($Name)) {
            return $script:AnalysisPlugins[$Name]
        }
        else {
            Write-Warning "Aucun plugin trouvÃ© avec le nom '$Name'."
            return $null
        }
    }
    
    # Sinon, filtrer les plugins selon les critÃ¨res
    $plugins = $script:AnalysisPlugins.Values
    
    if ($Language -ne "All") {
        $plugins = $plugins | Where-Object { $_.Language -eq $Language }
    }
    
    if ($EnabledOnly) {
        $plugins = $plugins | Where-Object { $_.Enabled -eq $true }
    }
    
    return $plugins
}

# Fonction pour activer ou dÃ©sactiver un plugin
function Set-AnalysisPluginState {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [bool]$Enabled
    )
    
    if (-not $script:AnalysisPlugins.ContainsKey($Name)) {
        Write-Error "Aucun plugin trouvÃ© avec le nom '$Name'."
        return $false
    }
    
    if ($PSCmdlet.ShouldProcess("Plugin $Name", "DÃ©finir l'Ã©tat Ã  $Enabled")) {
        $script:AnalysisPlugins[$Name].Enabled = $Enabled
        Write-Verbose "Ã‰tat du plugin '$Name' dÃ©fini Ã  $Enabled."
        return $true
    }
    
    return $false
}

# Fonction pour exÃ©cuter un plugin d'analyse
function Invoke-AnalysisPlugin {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalParameters = @{}
    )
    
    if (-not $script:AnalysisPlugins.ContainsKey($Name)) {
        Write-Error "Aucun plugin trouvÃ© avec le nom '$Name'."
        return $null
    }
    
    $plugin = $script:AnalysisPlugins[$Name]
    
    if (-not $plugin.Enabled) {
        Write-Warning "Le plugin '$Name' est dÃ©sactivÃ©."
        return $null
    }
    
    # VÃ©rifier les dÃ©pendances
    foreach ($dependency in $plugin.Dependencies) {
        if (-not (Get-Command -Name $dependency -ErrorAction SilentlyContinue)) {
            Write-Error "DÃ©pendance manquante pour le plugin '$Name': $dependency"
            return $null
        }
    }
    
    # ExÃ©cuter le plugin et mesurer le temps d'exÃ©cution
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $parameters = @{
            FilePath = $FilePath
        }
        
        # Ajouter les paramÃ¨tres supplÃ©mentaires
        foreach ($key in $AdditionalParameters.Keys) {
            $parameters[$key] = $AdditionalParameters[$key]
        }
        
        # Ajouter la configuration du plugin
        foreach ($key in $plugin.Configuration.Keys) {
            if (-not $parameters.ContainsKey($key)) {
                $parameters[$key] = $plugin.Configuration[$key]
            }
        }
        
        # ExÃ©cuter la fonction d'analyse
        $results = & $plugin.AnalyzeFunction @parameters
        
        # Convertir les rÃ©sultats si une fonction de conversion est dÃ©finie
        if ($null -ne $plugin.ConvertFunction -and $null -ne $results) {
            $results = & $plugin.ConvertFunction -Results $results
        }
        
        return $results
    }
    catch {
        Write-Error "Erreur lors de l'exÃ©cution du plugin '$Name': $_"
        return $null
    }
    finally {
        $stopwatch.Stop()
        
        # Mettre Ã  jour les statistiques d'exÃ©cution
        $plugin.LastExecutionTime = [datetime]::Now
        $plugin.ExecutionCount++
        
        # Calculer le temps d'exÃ©cution moyen
        $executionTime = $stopwatch.Elapsed.TotalMilliseconds
        $plugin.AverageExecutionTime = (($plugin.AverageExecutionTime * ($plugin.ExecutionCount - 1)) + $executionTime) / $plugin.ExecutionCount
        
        Write-Verbose "Plugin '$Name' exÃ©cutÃ© en $($stopwatch.Elapsed.TotalMilliseconds) ms."
    }
}

# Fonction pour dÃ©couvrir automatiquement les plugins dans un rÃ©pertoire
function Find-AnalysisPlugins {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$PluginDirectory = $script:DefaultPluginDirectory,
        
        [Parameter(Mandatory = $false)]
        [switch]$Register,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # VÃ©rifier si le rÃ©pertoire existe
    if (-not (Test-Path -Path $PluginDirectory -PathType Container)) {
        Write-Warning "Le rÃ©pertoire de plugins '$PluginDirectory' n'existe pas."
        
        # CrÃ©er le rÃ©pertoire si demandÃ©
        if ($Register) {
            try {
                New-Item -Path $PluginDirectory -ItemType Directory -Force | Out-Null
                Write-Verbose "RÃ©pertoire de plugins '$PluginDirectory' crÃ©Ã©."
            }
            catch {
                Write-Error "Impossible de crÃ©er le rÃ©pertoire de plugins '$PluginDirectory': $_"
                return @()
            }
        }
        else {
            return @()
        }
    }
    
    # Rechercher les fichiers de plugin
    $pluginFiles = Get-ChildItem -Path $PluginDirectory -Filter "*.ps1" -Recurse
    $discoveredPlugins = @()
    
    foreach ($file in $pluginFiles) {
        try {
            # Charger le script de plugin
            $pluginScript = Get-Content -Path $file.FullName -Raw
            
            # VÃ©rifier si le script contient un appel Ã  Register-AnalysisPlugin
            if ($pluginScript -match "Register-AnalysisPlugin") {
                Write-Verbose "Plugin trouvÃ©: $($file.Name)"
                
                # ExÃ©cuter le script pour enregistrer le plugin si demandÃ©
                if ($Register) {
                    $params = @{}
                    if ($Force) { $params["Force"] = $true }
                    
                    # ExÃ©cuter le script dans une nouvelle portÃ©e
                    $scriptBlock = [scriptblock]::Create($pluginScript)
                    $result = . $scriptBlock
                    
                    if ($result) {
                        $discoveredPlugins += $file.FullName
                    }
                }
                else {
                    $discoveredPlugins += $file.FullName
                }
            }
        }
        catch {
            Write-Warning "Erreur lors du chargement du plugin '$($file.FullName)': $_"
        }
    }
    
    return $discoveredPlugins
}

# Fonction pour exporter un plugin vers un fichier
function Export-AnalysisPlugin {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputDirectory = $script:DefaultPluginDirectory,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    if (-not $script:AnalysisPlugins.ContainsKey($Name)) {
        Write-Error "Aucun plugin trouvÃ© avec le nom '$Name'."
        return $false
    }
    
    $plugin = $script:AnalysisPlugins[$Name]
    
    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputDirectory -PathType Container)) {
        try {
            New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        }
        catch {
            Write-Error "Impossible de crÃ©er le rÃ©pertoire de sortie '$OutputDirectory': $_"
            return $false
        }
    }
    
    # GÃ©nÃ©rer le nom de fichier
    $fileName = "$($Name -replace '[^\w\-]', '_').ps1"
    $filePath = Join-Path -Path $OutputDirectory -ChildPath $fileName
    
    # VÃ©rifier si le fichier existe dÃ©jÃ 
    if ((Test-Path -Path $filePath) -and -not $Force) {
        Write-Error "Le fichier '$filePath' existe dÃ©jÃ . Utilisez -Force pour remplacer."
        return $false
    }
    
    # GÃ©nÃ©rer le contenu du fichier
    $content = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Plugin d'analyse: $($plugin.Name)

.DESCRIPTION
    $($plugin.Description)

.NOTES
    Version:        $($plugin.Version)
    Author:         $($plugin.Author)
    Language:       $($plugin.Language)
    Dependencies:   $($plugin.Dependencies -join ", ")
#>

# Fonction d'analyse
`$analyzeFunction = {
$($plugin.AnalyzeFunction.ToString())
}

# Fonction de conversion (si dÃ©finie)
`$convertFunction = $(if ($null -ne $plugin.ConvertFunction) { "{`n$($plugin.ConvertFunction.ToString())`n}" } else { "`$null" })

# Configuration
`$configuration = @{
$(
    $configLines = @()
    foreach ($key in $plugin.Configuration.Keys) {
        $value = $plugin.Configuration[$key]
        if ($value -is [string]) {
            $configLines += "    $key = '$value'"
        }
        else {
            $configLines += "    $key = $value"
        }
    }
    $configLines -join "`n"
)
}

# Enregistrer le plugin
Register-AnalysisPlugin -Name '$($plugin.Name)' `
                       -Description '$($plugin.Description)' `
                       -Version '$($plugin.Version)' `
                       -Author '$($plugin.Author)' `
                       -Language '$($plugin.Language)' `
                       -AnalyzeFunction `$analyzeFunction `
                       -ConvertFunction `$convertFunction `
                       -Configuration `$configuration `
                       -Dependencies @('$($plugin.Dependencies -join "', '")') `
                       -Force
"@
    
    # Ã‰crire le fichier
    if ($PSCmdlet.ShouldProcess("Plugin $Name", "Exporter vers $filePath")) {
        try {
            $content | Out-File -FilePath $filePath -Encoding utf8 -Force
            Write-Verbose "Plugin '$Name' exportÃ© vers '$filePath'."
            return $true
        }
        catch {
            Write-Error "Erreur lors de l'exportation du plugin '$Name': $_"
            return $false
        }
    }
    
    return $false
}

# Fonction pour importer un plugin depuis un fichier
function Import-AnalysisPlugin {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-Error "Le fichier '$Path' n'existe pas."
        return $false
    }
    
    # Charger le script de plugin
    try {
        $pluginScript = Get-Content -Path $Path -Raw
        
        # VÃ©rifier si le script contient un appel Ã  Register-AnalysisPlugin
        if ($pluginScript -match "Register-AnalysisPlugin") {
            # ExÃ©cuter le script pour enregistrer le plugin
            $params = @{}
            if ($Force) { $params["Force"] = $true }
            
            if ($PSCmdlet.ShouldProcess("Plugin $Path", "Importer")) {
                # ExÃ©cuter le script dans une nouvelle portÃ©e
                $scriptBlock = [scriptblock]::Create($pluginScript)
                $result = . $scriptBlock
                
                if ($result) {
                    Write-Verbose "Plugin importÃ© avec succÃ¨s depuis '$Path'."
                    return $true
                }
                else {
                    Write-Warning "Ã‰chec de l'importation du plugin depuis '$Path'."
                    return $false
                }
            }
        }
        else {
            Write-Error "Le fichier '$Path' ne semble pas Ãªtre un plugin d'analyse valide."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors de l'importation du plugin depuis '$Path': $_"
        return $false
    }
    
    return $false
}

# Fonction pour supprimer un plugin
function Remove-AnalysisPlugin {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    if (-not $script:AnalysisPlugins.ContainsKey($Name)) {
        Write-Error "Aucun plugin trouvÃ© avec le nom '$Name'."
        return $false
    }
    
    if ($PSCmdlet.ShouldProcess("Plugin $Name", "Supprimer")) {
        $script:AnalysisPlugins.Remove($Name)
        Write-Verbose "Plugin '$Name' supprimÃ©."
        return $true
    }
    
    return $false
}

# Fonction pour obtenir les statistiques d'exÃ©cution des plugins
function Get-AnalysisPluginStatistics {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name
    )
    
    if ($Name) {
        if (-not $script:AnalysisPlugins.ContainsKey($Name)) {
            Write-Error "Aucun plugin trouvÃ© avec le nom '$Name'."
            return $null
        }
        
        $plugin = $script:AnalysisPlugins[$Name]
        
        return [PSCustomObject]@{
            Name = $plugin.Name
            ExecutionCount = $plugin.ExecutionCount
            AverageExecutionTime = $plugin.AverageExecutionTime
            LastExecutionTime = $plugin.LastExecutionTime
        }
    }
    else {
        $stats = @()
        
        foreach ($plugin in $script:AnalysisPlugins.Values) {
            $stats += [PSCustomObject]@{
                Name = $plugin.Name
                ExecutionCount = $plugin.ExecutionCount
                AverageExecutionTime = $plugin.AverageExecutionTime
                LastExecutionTime = $plugin.LastExecutionTime
            }
        }
        
        return $stats
    }
}

# CrÃ©er le rÃ©pertoire de plugins par dÃ©faut s'il n'existe pas
if (-not (Test-Path -Path $script:DefaultPluginDirectory -PathType Container)) {
    try {
        New-Item -Path $script:DefaultPluginDirectory -ItemType Directory -Force | Out-Null
        Write-Verbose "RÃ©pertoire de plugins par dÃ©faut '$script:DefaultPluginDirectory' crÃ©Ã©."
    }
    catch {
        Write-Warning "Impossible de crÃ©er le rÃ©pertoire de plugins par dÃ©faut '$script:DefaultPluginDirectory': $_"
    }
}

# Exporter les fonctions du module
Export-ModuleMember -Function Register-AnalysisPlugin
Export-ModuleMember -Function Get-AnalysisPlugin
Export-ModuleMember -Function Set-AnalysisPluginState
Export-ModuleMember -Function Invoke-AnalysisPlugin
Export-ModuleMember -Function Find-AnalysisPlugins
Export-ModuleMember -Function Export-AnalysisPlugin
Export-ModuleMember -Function Import-AnalysisPlugin
Export-ModuleMember -Function Remove-AnalysisPlugin
Export-ModuleMember -Function Get-AnalysisPluginStatistics
