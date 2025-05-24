#Requires -Version 5.1
<#
.SYNOPSIS
    Initialise la segmentation automatique pour Agent Auto.
.DESCRIPTION
    Ce script configure et initialise la segmentation automatique des entrÃ©es
    pour Agent Auto, Ã©vitant ainsi les interruptions dues aux limites de taille d'entrÃ©e.
.PARAMETER ConfigPath
    Chemin du fichier de configuration Augment.
.PARAMETER Enable
    Active la segmentation automatique.
.PARAMETER MaxInputSizeKB
    Taille maximale d'entrÃ©e en KB (par dÃ©faut: 10).
.PARAMETER ChunkSizeKB
    Taille des segments en KB (par dÃ©faut: 5).
.PARAMETER PreserveLines
    PrÃ©serve les sauts de ligne lors de la segmentation de texte.
.PARAMETER CachePath
    Chemin du dossier de cache pour les Ã©tats de segmentation.
.EXAMPLE
    .\Initialize-AgentAutoSegmentation.ps1 -Enable -MaxInputSizeKB 15 -ChunkSizeKB 7
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-17
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = ".\.augment\config.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$Enable,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxInputSizeKB = 10,
    
    [Parameter(Mandatory = $false)]
    [int]$ChunkSizeKB = 5,
    
    [Parameter(Mandatory = $false)]
    [switch]$PreserveLines,
    
    [Parameter(Mandatory = $false)]
    [string]$CachePath = ".\cache\agent_auto_state.json"
)

# Importer le module de segmentation
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\InputSegmentation.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module de segmentation introuvable: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Fonction pour Ã©crire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "TITLE" { "Cyan" }
    }
    
    Write-Host "[$timestamp] " -NoNewline
    Write-Host "[$Level] " -NoNewline -ForegroundColor $color
    Write-Host $Message
}

# Fonction pour mettre Ã  jour la configuration
function Update-AugmentConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $true)]
        [bool]$Enable,
        
        [Parameter(Mandatory = $true)]
        [int]$MaxInputSizeKB,
        
        [Parameter(Mandatory = $true)]
        [int]$ChunkSizeKB,
        
        [Parameter(Mandatory = $true)]
        [bool]$PreserveLines,
        
        [Parameter(Mandatory = $true)]
        [string]$CachePath
    )
    
    Write-Log "Mise Ã  jour de la configuration Augment..." -Level "INFO"
    
    # VÃ©rifier si le fichier de configuration existe
    if (-not (Test-Path -Path $ConfigPath)) {
        Write-Log "Le fichier de configuration n'existe pas: $ConfigPath" -Level "ERROR"
        return $false
    }
    
    try {
        # Charger la configuration
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        
        # VÃ©rifier si la section agent_auto existe
        if (-not (Get-Member -InputObject $config -Name "agent_auto" -MemberType Properties)) {
            # CrÃ©er la section agent_auto
            $config | Add-Member -MemberType NoteProperty -Name "agent_auto" -Value @{
                input_segmentation = @{
                    enabled = $Enable
                    max_input_size_kb = $MaxInputSizeKB
                    chunk_size_kb = $ChunkSizeKB
                    preserve_lines = $PreserveLines
                    state_path = $CachePath
                }
                error_prevention = @{
                    cycle_detection = @{
                        enabled = $true
                        max_recursion_depth = 10
                        logs_path = '${workspace_root}/logs/cycles'
                    }
                }
            }
        }
        else {
            # VÃ©rifier si la section input_segmentation existe
            if (-not (Get-Member -InputObject $config.agent_auto -Name "input_segmentation" -MemberType Properties)) {
                # CrÃ©er la section input_segmentation
                $config.agent_auto | Add-Member -MemberType NoteProperty -Name "input_segmentation" -Value @{
                    enabled = $Enable
                    max_input_size_kb = $MaxInputSizeKB
                    chunk_size_kb = $ChunkSizeKB
                    preserve_lines = $PreserveLines
                    state_path = $CachePath
                }
            }
            else {
                # Mettre Ã  jour la section input_segmentation
                $config.agent_auto.input_segmentation.enabled = $Enable
                $config.agent_auto.input_segmentation.max_input_size_kb = $MaxInputSizeKB
                $config.agent_auto.input_segmentation.chunk_size_kb = $ChunkSizeKB
                $config.agent_auto.input_segmentation.preserve_lines = $PreserveLines
                $config.agent_auto.input_segmentation.state_path = $CachePath
            }
            
            # VÃ©rifier si la section error_prevention existe
            if (-not (Get-Member -InputObject $config.agent_auto -Name "error_prevention" -MemberType Properties)) {
                # CrÃ©er la section error_prevention
                $config.agent_auto | Add-Member -MemberType NoteProperty -Name "error_prevention" -Value @{
                    cycle_detection = @{
                        enabled = $true
                        max_recursion_depth = 10
                        logs_path = '${workspace_root}/logs/cycles'
                    }
                }
            }
        }
        
        # Enregistrer la configuration
        $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding utf8
        
        Write-Log "Configuration mise Ã  jour avec succÃ¨s." -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erreur lors de la mise Ã  jour de la configuration: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour crÃ©er un hook PowerShell pour Agent Auto
function New-AgentAutoHook {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$MaxInputSizeKB,
        
        [Parameter(Mandatory = $true)]
        [int]$ChunkSizeKB,
        
        [Parameter(Mandatory = $true)]
        [bool]$PreserveLines
    )
    
    Write-Log "CrÃ©ation du hook PowerShell pour Agent Auto..." -Level "INFO"
    
    $hookPath = Join-Path -Path $PSScriptRoot -ChildPath "AgentAutoHook.ps1"
    
    $hookContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Hook PowerShell pour la segmentation automatique des entrÃ©es Agent Auto.
.DESCRIPTION
    Ce script intercepte les entrÃ©es destinÃ©es Ã  Agent Auto et les segmente
    automatiquement si elles dÃ©passent la taille maximale autorisÃ©e.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: $(Get-Date -Format "yyyy-MM-dd")
#>

# Importer le module de segmentation
Import-Module "$PSScriptRoot\..\..\modules\InputSegmentation.psm1" -Force

# Initialiser le module de segmentation
Initialize-InputSegmentation -MaxInputSizeKB $MaxInputSizeKB -DefaultChunkSizeKB $ChunkSizeKB

# Fonction pour traiter une entrÃ©e
function Invoke-AgentAutoInput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true, ValueFromPipeline = `$true)]
        [object]`$Input
    )
    
    process {
        # Mesurer la taille de l'entrÃ©e
        `$sizeKB = Measure-InputSize -Input `$Input
        
        # Si l'entrÃ©e est plus petite que la taille maximale, la retourner telle quelle
        if (`$sizeKB -le $MaxInputSizeKB) {
            return `$Input
        }
        
        # Segmenter l'entrÃ©e
        `$segments = Split-Input -Input `$Input -ChunkSizeKB $ChunkSizeKB -PreserveLines:`$$PreserveLines
        
        # CrÃ©er un identifiant unique pour cette segmentation
        `$segmentationId = [guid]::NewGuid().ToString()
        
        # Sauvegarder l'Ã©tat de segmentation
        Save-SegmentationState -Id `$segmentationId -Segments `$segments -CurrentIndex 0
        
        # Retourner le premier segment avec des mÃ©tadonnÃ©es
        return [PSCustomObject]@{
            Content = `$segments[0]
            IsSegmented = `$true
            SegmentationId = `$segmentationId
            SegmentIndex = 0
            TotalSegments = `$segments.Count
            OriginalSizeKB = `$sizeKB
            Message = "EntrÃ©e segmentÃ©e en `$(`$segments.Count) parties. Utilisez Get-NextSegment -Id `$segmentationId pour obtenir les segments suivants."
        }
    }
}

# Fonction pour obtenir le segment suivant
function Get-NextSegment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Id
    )
    
    # Charger l'Ã©tat de segmentation
    `$state = Get-SegmentationState -Id `$Id
    
    if (-not `$state) {
        Write-Error "Ã‰tat de segmentation introuvable pour l'ID: `$Id"
        return `$null
    }
    
    # VÃ©rifier s'il reste des segments
    if (`$state.CurrentIndex -ge `$state.TotalSegments - 1) {
        Write-Warning "Tous les segments ont dÃ©jÃ  Ã©tÃ© traitÃ©s pour l'ID: `$Id"
        return `$null
    }
    
    # IncrÃ©menter l'index
    `$nextIndex = `$state.CurrentIndex + 1
    
    # Mettre Ã  jour l'Ã©tat
    Save-SegmentationState -Id `$Id -Segments `$state.Segments -CurrentIndex `$nextIndex
    
    # Retourner le segment suivant avec des mÃ©tadonnÃ©es
    return [PSCustomObject]@{
        Content = `$state.Segments[`$nextIndex]
        IsSegmented = `$true
        SegmentationId = `$Id
        SegmentIndex = `$nextIndex
        TotalSegments = `$state.TotalSegments
        RemainingSegments = `$state.TotalSegments - `$nextIndex - 1
        Message = "Segment `$(`$nextIndex + 1)/`$(`$state.TotalSegments). Reste `$(`$state.TotalSegments - `$nextIndex - 1) segment(s)."
    }
}

# Exporter les fonctions
Export-ModuleMember -function Invoke-AgentAutoInput, Get-NextSegment
"@
    
    try {
        $hookContent | Out-File -FilePath $hookPath -Encoding utf8
        Write-Log "Hook PowerShell crÃ©Ã©: $hookPath" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erreur lors de la crÃ©ation du hook PowerShell: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour crÃ©er un exemple d'utilisation
function New-UsageExample {
    [CmdletBinding()]
    param ()
    
    Write-Log "CrÃ©ation d'un exemple d'utilisation..." -Level "INFO"
    
    $examplePath = Join-Path -Path $PSScriptRoot -ChildPath "Example-AgentAutoSegmentation.ps1"
    
    $exampleContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'utilisation de la segmentation automatique pour Agent Auto.
.DESCRIPTION
    Ce script montre comment utiliser la segmentation automatique pour
    traiter des entrÃ©es volumineuses avec Agent Auto.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: $(Get-Date -Format "yyyy-MM-dd")
#>

# Importer le hook Agent Auto
Import-Module "$PSScriptRoot\AgentAutoHook.ps1" -Force

# Fonction pour simuler Agent Auto
function Invoke-AgentAuto {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [object]`$Input
    )
    
    Write-Host "Agent Auto traite l'entrÃ©e..." -ForegroundColor Cyan
    
    # Simuler un traitement
    Start-Sleep -Seconds 1
    
    # Retourner une rÃ©ponse
    return "Agent Auto a traitÃ© l'entrÃ©e: `$(`$Input.GetType().Name) de taille `$((Measure-InputSize -Input `$Input)) KB"
}

# Fonction pour traiter une entrÃ©e avec segmentation
function Invoke-AgentAutoWithSegmentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [object]`$Input
    )
    
    # Traiter l'entrÃ©e avec segmentation
    `$processedInput = `$Input | Invoke-AgentAutoInput
    
    # VÃ©rifier si l'entrÃ©e a Ã©tÃ© segmentÃ©e
    if (`$processedInput.IsSegmented) {
        Write-Host "EntrÃ©e segmentÃ©e en `$(`$processedInput.TotalSegments) parties." -ForegroundColor Yellow
        
        # Traiter le premier segment
        `$result = Invoke-AgentAuto -Input `$processedInput.Content
        Write-Host "Segment 1/`$(`$processedInput.TotalSegments) traitÃ©: `$result" -ForegroundColor Green
        
        # Traiter les segments restants
        for (`$i = 1; `$i -lt `$processedInput.TotalSegments; `$i++) {
            `$nextSegment = Get-NextSegment -Id `$processedInput.SegmentationId
            
            if (`$nextSegment) {
                `$result = Invoke-AgentAuto -Input `$nextSegment.Content
                Write-Host "Segment `$(`$i + 1)/`$(`$processedInput.TotalSegments) traitÃ©: `$result" -ForegroundColor Green
            }
        }
        
        return "Traitement terminÃ©. `$(`$processedInput.TotalSegments) segments traitÃ©s."
    }
    else {
        # Traiter l'entrÃ©e directement
        return Invoke-AgentAuto -Input `$processedInput
    }
}

# Exemple 1: EntrÃ©e de petite taille
Write-Host "`nExemple 1: EntrÃ©e de petite taille" -ForegroundColor Magenta
`$smallInput = "Ceci est une petite entrÃ©e de test."
Invoke-AgentAutoWithSegmentation -Input `$smallInput

# Exemple 2: EntrÃ©e de grande taille (texte)
Write-Host "`nExemple 2: EntrÃ©e de grande taille (texte)" -ForegroundColor Magenta
`$largeText = ""
for (`$i = 0; `$i -lt 500; `$i++) {
    `$largeText += "Ligne `$i : Ceci est une ligne de test pour la segmentation d'entrÃ©e. " * 5
    `$largeText += "`n"
}
Invoke-AgentAutoWithSegmentation -Input `$largeText

# Exemple 3: EntrÃ©e de grande taille (JSON)
Write-Host "`nExemple 3: EntrÃ©e de grande taille (JSON)" -ForegroundColor Magenta
`$largeJson = @{
    items = @()
}
for (`$i = 0; `$i -lt 200; `$i++) {
    `$largeJson.items += @{
        id = `$i
        name = "Item `$i"
        description = "Description de l'item `$i. " * 10
        properties = @{
            prop1 = "Valeur 1"
            prop2 = "Valeur 2"
            prop3 = "Valeur 3"
            prop4 = "Valeur 4"
            prop5 = "Valeur 5"
        }
    }
}
Invoke-AgentAutoWithSegmentation -Input `$largeJson
"@
    
    try {
        $exampleContent | Out-File -FilePath $examplePath -Encoding utf8
        Write-Log "Exemple d'utilisation crÃ©Ã©: $examplePath" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erreur lors de la crÃ©ation de l'exemple d'utilisation: $_" -Level "ERROR"
        return $false
    }
}

# Fonction principale
function Initialize-AgentAutoSegmentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $true)]
        [bool]$Enable,
        
        [Parameter(Mandatory = $true)]
        [int]$MaxInputSizeKB,
        
        [Parameter(Mandatory = $true)]
        [int]$ChunkSizeKB,
        
        [Parameter(Mandatory = $true)]
        [bool]$PreserveLines,
        
        [Parameter(Mandatory = $true)]
        [string]$CachePath
    )
    
    Write-Log "Initialisation de la segmentation automatique pour Agent Auto..." -Level "TITLE"
    
    # Initialiser le module de segmentation
    Initialize-InputSegmentation -MaxInputSizeKB $MaxInputSizeKB -DefaultChunkSizeKB $ChunkSizeKB
    
    # Mettre Ã  jour la configuration
    $configUpdated = Update-AugmentConfig -ConfigPath $ConfigPath -Enable $Enable -MaxInputSizeKB $MaxInputSizeKB -ChunkSizeKB $ChunkSizeKB -PreserveLines $PreserveLines -CachePath $CachePath
    
    if (-not $configUpdated) {
        Write-Log "Ã‰chec de la mise Ã  jour de la configuration." -Level "ERROR"
        return $false
    }
    
    # CrÃ©er le hook PowerShell
    $hookCreated = New-AgentAutoHook -MaxInputSizeKB $MaxInputSizeKB -ChunkSizeKB $ChunkSizeKB -PreserveLines $PreserveLines
    
    if (-not $hookCreated) {
        Write-Log "Ã‰chec de la crÃ©ation du hook PowerShell." -Level "ERROR"
        return $false
    }
    
    # CrÃ©er l'exemple d'utilisation
    $exampleCreated = New-UsageExample
    
    if (-not $exampleCreated) {
        Write-Log "Ã‰chec de la crÃ©ation de l'exemple d'utilisation." -Level "WARNING"
    }
    
    # CrÃ©er les dossiers nÃ©cessaires
    $cacheDirPath = Split-Path -Path $CachePath -Parent
    
    if (-not (Test-Path -Path $cacheDirPath)) {
        New-Item -Path $cacheDirPath -ItemType Directory -Force | Out-Null
        Write-Log "Dossier de cache crÃ©Ã©: $cacheDirPath" -Level "INFO"
    }
    
    $logsDirPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\logs\segmentation"
    
    if (-not (Test-Path -Path $logsDirPath)) {
        New-Item -Path $logsDirPath -ItemType Directory -Force | Out-Null
        Write-Log "Dossier de logs crÃ©Ã©: $logsDirPath" -Level "INFO"
    }
    
    Write-Log "Initialisation terminÃ©e." -Level "SUCCESS"
    Write-Log "La segmentation automatique pour Agent Auto est maintenant $(if ($Enable) { 'activÃ©e' } else { 'dÃ©sactivÃ©e' })." -Level $(if ($Enable) { "SUCCESS" } else { "WARNING" })
    Write-Log "Taille maximale d'entrÃ©e: $MaxInputSizeKB KB" -Level "INFO"
    Write-Log "Taille des segments: $ChunkSizeKB KB" -Level "INFO"
    Write-Log "PrÃ©servation des lignes: $PreserveLines" -Level "INFO"
    Write-Log "Chemin du cache: $CachePath" -Level "INFO"
    
    return $true
}

# ExÃ©cuter la fonction principale
Initialize-AgentAutoSegmentation -ConfigPath $ConfigPath -Enable $Enable -MaxInputSizeKB $MaxInputSizeKB -ChunkSizeKB $ChunkSizeKB -PreserveLines $PreserveLines -CachePath $CachePath

