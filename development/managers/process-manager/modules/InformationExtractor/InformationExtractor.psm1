<#
.SYNOPSIS
    Module d'extraction d'informations pour le Process Manager.

.DESCRIPTION
    Ce module fournit des fonctions pour extraire des informations sur les gestionnaires
    enregistrÃ©s, leurs Ã©tats, et leurs configurations.

.NOTES
    Version: 1.0.0
    Auteur: Process Manager Team
    Date de crÃ©ation: 2025-05-15
#>

# Variables globales du module
$script:DefaultConfigPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent -Parent -Parent -Parent) -ChildPath "projet\config\managers\process-manager\process-manager.config.json"

# Fonction de journalisation
function Write-ExtractorLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    # DÃ©terminer la couleur en fonction du niveau
    $color = switch ($Level) {
        "Debug" { "Gray" }
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        default { "White" }
    }
    
    # Ã‰crire le message dans la console
    Write-Host "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] [InformationExtractor] [$Level] $Message" -ForegroundColor $color
}

<#
.SYNOPSIS
    Extrait les informations sur un gestionnaire enregistrÃ©.

.DESCRIPTION
    Cette fonction extrait les informations dÃ©taillÃ©es sur un gestionnaire enregistrÃ©
    dans le Process Manager, y compris son Ã©tat, sa configuration, et ses dÃ©pendances.

.PARAMETER Name
    Le nom du gestionnaire Ã  extraire.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration du Process Manager.

.EXAMPLE
    Get-ManagerInformation -Name "ModeManager"
    Extrait les informations sur le gestionnaire de modes.
#>
function Get-ManagerInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath
    )
    
    try {
        # VÃ©rifier que le fichier de configuration existe
        if (-not (Test-Path -Path $ConfigPath -PathType Leaf)) {
            Write-ExtractorLog -Message "Le fichier de configuration n'existe pas : $ConfigPath" -Level Error
            return $null
        }
        
        # Charger la configuration
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        
        # VÃ©rifier si le gestionnaire est enregistrÃ©
        if (-not $config.Managers.$Name) {
            Write-ExtractorLog -Message "Le gestionnaire '$Name' n'est pas enregistrÃ©." -Level Warning
            return $null
        }
        
        # Extraire les informations de base
        $managerInfo = $config.Managers.$Name
        
        # CrÃ©er l'objet d'information
        $information = [PSCustomObject]@{
            Name = $Name
            Path = $managerInfo.Path
            Enabled = $managerInfo.Enabled
            RegisteredAt = $managerInfo.RegisteredAt
            Version = $managerInfo.Version
            Status = "Unknown"
            LastRun = $managerInfo.LastRun
            Dependencies = @()
            Configuration = $null
            Manifest = $null
        }
        
        # Essayer de charger le manifeste si le module ManifestParser est disponible
        if (Get-Module -ListAvailable -Name "ManifestParser") {
            try {
                Import-Module -Name "ManifestParser" -ErrorAction Stop
                $manifest = Get-ManagerManifest -Path $managerInfo.Path
                
                if ($manifest) {
                    $information.Manifest = $manifest
                    
                    # Mettre Ã  jour les informations avec celles du manifeste
                    if ($manifest.Version) {
                        $information.Version = $manifest.Version
                    }
                    
                    if ($manifest.Dependencies) {
                        $information.Dependencies = $manifest.Dependencies
                    }
                }
            }
            catch {
                Write-ExtractorLog -Message "Erreur lors de l'extraction du manifeste : $_" -Level Warning
            }
        }
        
        # Essayer de dÃ©terminer l'Ã©tat du gestionnaire
        try {
            $managerProcess = Get-Process -Name $Name -ErrorAction SilentlyContinue
            
            if ($managerProcess) {
                $information.Status = "Running"
            }
            else {
                $information.Status = "Stopped"
            }
        }
        catch {
            Write-ExtractorLog -Message "Erreur lors de la dÃ©termination de l'Ã©tat du gestionnaire : $_" -Level Warning
        }
        
        # Essayer de charger la configuration spÃ©cifique du gestionnaire
        $managerConfigPath = Join-Path -Path (Split-Path -Path $ConfigPath -Parent) -ChildPath "$Name\$Name.config.json"
        
        if (Test-Path -Path $managerConfigPath -PathType Leaf) {
            try {
                $managerConfig = Get-Content -Path $managerConfigPath -Raw | ConvertFrom-Json
                $information.Configuration = $managerConfig
            }
            catch {
                Write-ExtractorLog -Message "Erreur lors du chargement de la configuration du gestionnaire : $_" -Level Warning
            }
        }
        
        Write-ExtractorLog -Message "Informations extraites pour le gestionnaire '$Name'." -Level Info
        return $information
    }
    catch {
        Write-ExtractorLog -Message "Erreur lors de l'extraction des informations : $_" -Level Error
        return $null
    }
}

<#
.SYNOPSIS
    Extrait les informations sur tous les gestionnaires enregistrÃ©s.

.DESCRIPTION
    Cette fonction extrait les informations dÃ©taillÃ©es sur tous les gestionnaires
    enregistrÃ©s dans le Process Manager.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration du Process Manager.

.EXAMPLE
    Get-AllManagersInformation
    Extrait les informations sur tous les gestionnaires enregistrÃ©s.
#>
function Get-AllManagersInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath
    )
    
    try {
        # VÃ©rifier que le fichier de configuration existe
        if (-not (Test-Path -Path $ConfigPath -PathType Leaf)) {
            Write-ExtractorLog -Message "Le fichier de configuration n'existe pas : $ConfigPath" -Level Error
            return $null
        }
        
        # Charger la configuration
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        
        # Initialiser le tableau des informations
        $allInformation = @()
        
        # Extraire les informations pour chaque gestionnaire
        foreach ($managerName in $config.Managers.PSObject.Properties.Name) {
            $information = Get-ManagerInformation -Name $managerName -ConfigPath $ConfigPath
            
            if ($information) {
                $allInformation += $information
            }
        }
        
        Write-ExtractorLog -Message "Informations extraites pour tous les gestionnaires." -Level Info
        return $allInformation
    }
    catch {
        Write-ExtractorLog -Message "Erreur lors de l'extraction des informations : $_" -Level Error
        return $null
    }
}

<#
.SYNOPSIS
    Extrait les statistiques sur les gestionnaires enregistrÃ©s.

.DESCRIPTION
    Cette fonction extrait des statistiques sur les gestionnaires enregistrÃ©s
    dans le Process Manager, comme le nombre de gestionnaires, leur Ã©tat, etc.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration du Process Manager.

.EXAMPLE
    Get-ManagersStatistics
    Extrait les statistiques sur les gestionnaires enregistrÃ©s.
#>
function Get-ManagersStatistics {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath
    )
    
    try {
        # Extraire les informations sur tous les gestionnaires
        $allInformation = Get-AllManagersInformation -ConfigPath $ConfigPath
        
        if (-not $allInformation) {
            Write-ExtractorLog -Message "Aucune information disponible pour calculer les statistiques." -Level Warning
            return $null
        }
        
        # Calculer les statistiques
        $totalManagers = $allInformation.Count
        $enabledManagers = ($allInformation | Where-Object { $_.Enabled -eq $true }).Count
        $disabledManagers = $totalManagers - $enabledManagers
        $runningManagers = ($allInformation | Where-Object { $_.Status -eq "Running" }).Count
        $stoppedManagers = ($allInformation | Where-Object { $_.Status -eq "Stopped" }).Count
        $unknownStatusManagers = $totalManagers - $runningManagers - $stoppedManagers
        
        # CrÃ©er l'objet de statistiques
        $statistics = [PSCustomObject]@{
            TotalManagers = $totalManagers
            EnabledManagers = $enabledManagers
            DisabledManagers = $disabledManagers
            RunningManagers = $runningManagers
            StoppedManagers = $stoppedManagers
            UnknownStatusManagers = $unknownStatusManagers
            LastUpdated = Get-Date
        }
        
        Write-ExtractorLog -Message "Statistiques calculÃ©es pour les gestionnaires." -Level Info
        return $statistics
    }
    catch {
        Write-ExtractorLog -Message "Erreur lors du calcul des statistiques : $_" -Level Error
        return $null
    }
}

<#
.SYNOPSIS
    Extrait les dÃ©pendances entre les gestionnaires.

.DESCRIPTION
    Cette fonction extrait les dÃ©pendances entre les gestionnaires enregistrÃ©s
    dans le Process Manager et gÃ©nÃ¨re un graphe de dÃ©pendances.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration du Process Manager.

.PARAMETER OutputFormat
    Le format de sortie du graphe de dÃ©pendances (Text, JSON, DOT).

.EXAMPLE
    Get-ManagerDependencyGraph -OutputFormat "DOT"
    Extrait le graphe de dÃ©pendances au format DOT.
#>
function Get-ManagerDependencyGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "JSON", "DOT")]
        [string]$OutputFormat = "Text"
    )
    
    try {
        # Extraire les informations sur tous les gestionnaires
        $allInformation = Get-AllManagersInformation -ConfigPath $ConfigPath
        
        if (-not $allInformation) {
            Write-ExtractorLog -Message "Aucune information disponible pour gÃ©nÃ©rer le graphe de dÃ©pendances." -Level Warning
            return $null
        }
        
        # CrÃ©er le graphe de dÃ©pendances
        $dependencyGraph = @{}
        
        foreach ($manager in $allInformation) {
            $dependencies = @()
            
            if ($manager.Dependencies) {
                foreach ($dependency in $manager.Dependencies) {
                    $dependencies += $dependency.Name
                }
            }
            
            $dependencyGraph[$manager.Name] = $dependencies
        }
        
        # GÃ©nÃ©rer la sortie selon le format demandÃ©
        switch ($OutputFormat) {
            "Text" {
                $output = "Graphe de dÃ©pendances des gestionnaires :`n"
                
                foreach ($manager in $dependencyGraph.Keys) {
                    $output += "`n$manager dÃ©pend de :`n"
                    
                    if ($dependencyGraph[$manager].Count -eq 0) {
                        $output += "  Aucune dÃ©pendance`n"
                    }
                    else {
                        foreach ($dependency in $dependencyGraph[$manager]) {
                            $output += "  - $dependency`n"
                        }
                    }
                }
                
                return $output
            }
            "JSON" {
                return $dependencyGraph | ConvertTo-Json -Depth 10
            }
            "DOT" {
                $output = "digraph ManagerDependencies {`n"
                $output += "  rankdir=LR;`n"
                $output += "  node [shape=box, style=filled, fillcolor=lightblue];`n"
                
                foreach ($manager in $dependencyGraph.Keys) {
                    if ($dependencyGraph[$manager].Count -eq 0) {
                        $output += "  `"$manager`";`n"
                    }
                    else {
                        foreach ($dependency in $dependencyGraph[$manager]) {
                            $output += "  `"$manager`" -> `"$dependency`";`n"
                        }
                    }
                }
                
                $output += "}"
                return $output
            }
        }
    }
    catch {
        Write-ExtractorLog -Message "Erreur lors de la gÃ©nÃ©ration du graphe de dÃ©pendances : $_" -Level Error
        return $null
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-ManagerInformation, Get-AllManagersInformation, Get-ManagersStatistics, Get-ManagerDependencyGraph
