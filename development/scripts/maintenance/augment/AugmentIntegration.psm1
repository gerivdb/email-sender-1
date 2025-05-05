# Module d'intÃ©gration avec Augment Code
# Fournit des fonctions pour interagir avec Augment Code

# Importer les dÃ©pendances
$scriptPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
. "$scriptPath\AugmentMemoriesManager.ps1"

function Invoke-AugmentMode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("ARCHI", "CHECK", "C-BREAK", "DEBUG", "DEV-R", "GRAN", "OPTI", "PREDIC", "REVIEW", "TEST")]
        [string]$Mode,

        [Parameter()]
        [string]$FilePath,

        [Parameter()]
        [string]$TaskIdentifier,

        [Parameter()]
        [switch]$UpdateMemories
    )

    $integrationPath = Join-Path -Path $scriptPath -ChildPath "mode-manager-augment-integration.ps1"
    
    $params = @{
        Mode = $Mode
    }
    
    if ($FilePath) {
        $params.FilePath = $FilePath
    }
    
    if ($TaskIdentifier) {
        $params.TaskIdentifier = $TaskIdentifier
    }
    
    if ($UpdateMemories) {
        $params.UpdateMemories = $true
    }
    
    & $integrationPath @params
    return $LASTEXITCODE -eq 0
}

function Start-AugmentMCPServers {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$LogPath = "logs\mcp"
    )
    
    $startPath = Join-Path -Path $scriptPath -ChildPath "start-mcp-servers.ps1"
    & $startPath -LogPath $LogPath
}

function Stop-AugmentMCPServers {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$LogPath = "logs\mcp"
    )
    
    $stopPath = Join-Path -Path $scriptPath -ChildPath "stop-mcp-servers.ps1"
    if (Test-Path $stopPath) {
        & $stopPath -LogPath $LogPath
    } else {
        Write-Warning "Script d'arrÃªt introuvable : $stopPath"
    }
}

function Update-AugmentMemoriesForMode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("ARCHI", "CHECK", "C-BREAK", "DEBUG", "DEV-R", "GRAN", "OPTI", "PREDIC", "REVIEW", "TEST", "ALL")]
        [string]$Mode,
        
        [Parameter()]
        [string]$OutputPath
    )
    
    $optimizePath = Join-Path -Path $scriptPath -ChildPath "optimize-augment-memories.ps1"
    
    $params = @{
        Mode = $Mode
    }
    
    if ($OutputPath) {
        $params.OutputPath = $OutputPath
    }
    
    & $optimizePath @params
}

function Split-AugmentInput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Input,
        
        [Parameter()]
        [int]$MaxSize = 3000
    )
    
    Split-LargeInput -Input $Input -MaxSize $MaxSize
}

function Measure-AugmentInputSize {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Input
    )
    
    $byteCount = [System.Text.Encoding]::UTF8.GetByteCount($Input)
    $kiloBytes = [math]::Round($byteCount / 1024, 2)
    
    return @{
        Bytes = $byteCount
        KiloBytes = $kiloBytes
        IsOverLimit = $byteCount > 5120
        IsNearLimit = $byteCount > 4096
    }
}

function Get-AugmentModeDescription {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("ARCHI", "CHECK", "C-BREAK", "DEBUG", "DEV-R", "GRAN", "OPTI", "PREDIC", "REVIEW", "TEST")]
        [string]$Mode
    )
    
    $descriptions = @{
        "ARCHI" = "Structurer, modÃ©liser, anticiper les dÃ©pendances"
        "CHECK" = "VÃ©rifier l'Ã©tat d'avancement des tÃ¢ches"
        "C-BREAK" = "DÃ©tecter et rÃ©soudre les dÃ©pendances circulaires"
        "DEBUG" = "Isoler, comprendre, corriger les anomalies"
        "DEV-R" = "ImplÃ©menter ce qui est dans la roadmap"
        "GRAN" = "DÃ©composer les blocs complexes"
        "OPTI" = "RÃ©duire complexitÃ©, taille ou temps d'exÃ©cution"
        "PREDIC" = "Anticiper performances, dÃ©tecter anomalies, analyser tendances"
        "REVIEW" = "VÃ©rifier lisibilitÃ©, standards, documentation"
        "TEST" = "Maximiser couverture et fiabilitÃ©"
    }
    
    return $descriptions[$Mode]
}

function Initialize-AugmentIntegration {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]$StartServers
    )
    
    $configurePath = Join-Path -Path $scriptPath -ChildPath "configure-augment-mcp.ps1"
    
    $params = @{}
    if ($StartServers) {
        $params.StartServers = $true
    }
    
    & $configurePath @params
}

function Analyze-AugmentPerformance {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$LogPath = "logs\augment\augment.log",
        
        [Parameter()]
        [string]$OutputPath = "reports\augment\performance.html"
    )
    
    $analyzePath = Join-Path -Path $scriptPath -ChildPath "analyze-augment-performance.ps1"
    & $analyzePath -LogPath $LogPath -OutputPath $OutputPath
}

# Exporter les fonctions
Export-ModuleMember -Function Invoke-AugmentMode
Export-ModuleMember -Function Start-AugmentMCPServers
Export-ModuleMember -Function Stop-AugmentMCPServers
Export-ModuleMember -Function Update-AugmentMemoriesForMode
Export-ModuleMember -Function Split-AugmentInput
Export-ModuleMember -Function Measure-AugmentInputSize
Export-ModuleMember -Function Get-AugmentModeDescription
Export-ModuleMember -Function Initialize-AugmentIntegration
Export-ModuleMember -Function Analyze-AugmentPerformance
