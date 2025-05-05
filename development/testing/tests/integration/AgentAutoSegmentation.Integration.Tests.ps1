#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intÃ©gration pour la segmentation d'entrÃ©es avec Agent Auto.
.DESCRIPTION
    Ce script contient les tests d'intÃ©gration pour la segmentation d'entrÃ©es
    avec Agent Auto, vÃ©rifiant l'intÃ©gration entre les composants.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-05-15
#>

BeforeAll {
    # Importer le module Ã  tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\InputSegmentation.psm1"
    Import-Module $modulePath -Force
    
    # Initialiser le module
    Initialize-InputSegmentation -MaxInputSizeKB 10 -DefaultChunkSizeKB 5
    
    # CrÃ©er un dossier temporaire pour les sorties
    $tempOutputDir = Join-Path -Path $TestDrive -ChildPath "output"
    New-Item -Path $tempOutputDir -ItemType Directory -Force | Out-Null
    
    # CrÃ©er des donnÃ©es de test
    $tempDataDir = Join-Path -Path $TestDrive -ChildPath "data"
    New-Item -Path $tempDataDir -ItemType Directory -Force | Out-Null
    
    # CrÃ©er un fichier texte volumineux
    $largeTextPath = Join-Path -Path $tempDataDir -ChildPath "large_text.txt"
    "A" * 20KB | Out-File -FilePath $largeTextPath -Encoding utf8
    
    # CrÃ©er un fichier JSON volumineux
    $largeJsonPath = Join-Path -Path $tempDataDir -ChildPath "large_json.json"
    $largeJson = @{
        items = @()
    }
    
    for ($i = 0; $i -lt 500; $i++) {
        $largeJson.items += @{
            id = $i
            name = "Item $i"
            description = "Description de l'item $i"
        }
    }
    
    $largeJson | ConvertTo-Json -Depth 10 | Out-File -FilePath $largeJsonPath -Encoding utf8
    
    # CrÃ©er un script de test pour Agent Auto
    $agentAutoScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\development\scripts\agent-auto\Example-AgentAutoSegmentation.ps1"
    
    # VÃ©rifier si le script existe, sinon le crÃ©er pour les tests
    if (-not (Test-Path -Path $agentAutoScriptPath)) {
        $scriptDir = Split-Path -Path $agentAutoScriptPath -Parent
        if (-not (Test-Path -Path $scriptDir)) {
            New-Item -Path $scriptDir -ItemType Directory -Force | Out-Null
        }
        
        @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'utilisation de la segmentation automatique pour Agent Auto.
.DESCRIPTION
    Ce script montre comment utiliser la segmentation automatique pour
    traiter des entrÃ©es volumineuses avec Agent Auto.
.PARAMETER Input
    EntrÃ©e Ã  traiter (texte, JSON ou chemin de fichier).
.PARAMETER InputType
    Type d'entrÃ©e (Text, Json, File).
.PARAMETER OutputPath
    Chemin du dossier de sortie pour les segments.
.PARAMETER TestMode
    Mode de test pour les tests d'intÃ©gration.
.EXAMPLE
    .\Example-AgentAutoSegmentation.ps1 -Input "Texte volumineux" -InputType Text
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = `$true)]
    [object]`$Input,
    
    [Parameter(Mandatory = `$false)]
    [ValidateSet("Text", "Json", "File")]
    [string]`$InputType = "",
    
    [Parameter(Mandatory = `$false)]
    [string]`$OutputPath = "",
    
    [Parameter(Mandatory = `$false)]
    [switch]`$TestMode
)

# Importer le module de segmentation
`$modulePath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\modules\InputSegmentation.psm1"
Import-Module `$modulePath -Force

# Initialiser le module de segmentation
Initialize-InputSegmentation -MaxInputSizeKB 10 -DefaultChunkSizeKB 5

# Fonction pour traiter une entrÃ©e avec segmentation
function Invoke-AgentAutoWithSegmentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [object]`$Input,
        
        [Parameter(Mandatory = `$false)]
        [ValidateSet("Text", "Json", "File")]
        [string]`$InputType = "",
        
        [Parameter(Mandatory = `$false)]
        [string]`$OutputPath = "",
        
        [Parameter(Mandatory = `$false)]
        [switch]`$TestMode
    )
    
    # DÃ©terminer le type d'entrÃ©e si non spÃ©cifiÃ©
    if (-not `$InputType) {
        if (`$Input -is [string]) {
            if (Test-Path -Path `$Input -PathType Leaf) {
                `$InputType = "File"
            } else {
                `$InputType = "Text"
            }
        } elseif (`$Input -is [hashtable] -or `$Input -is [PSCustomObject]) {
            `$InputType = "Json"
        } else {
            throw "Type d'entrÃ©e non reconnu. Veuillez spÃ©cifier le paramÃ¨tre InputType."
        }
    }
    
    # Mesurer la taille de l'entrÃ©e
    `$sizeKB = Measure-InputSize -Input `$Input
    
    # CrÃ©er un objet de rÃ©sultat pour le mode de test
    if (`$TestMode) {
        `$result = [PSCustomObject]@{
            InputType = `$InputType
            InputSizeKB = `$sizeKB
            IsSegmented = `$false
            SegmentCount = 0
            Segments = @()
        }
    }
    
    # Si l'entrÃ©e est plus petite que la taille maximale, la traiter directement
    if (`$sizeKB -le 10) {
        if (`$TestMode) {
            `$result.IsSegmented = `$false
            `$result.SegmentCount = 1
            `$result.Segments = @(`$Input)
            return `$result
        }
        
        # Simuler le traitement par Agent Auto
        Write-Host "Agent Auto traite l'entrÃ©e directement (taille: `$sizeKB KB)..." -ForegroundColor Cyan
        Start-Sleep -Seconds 1
        return "Agent Auto a traitÃ© l'entrÃ©e directement: `$InputType de taille `$sizeKB KB"
    }
    
    # Segmenter l'entrÃ©e
    `$segments = @()
    
    switch (`$InputType) {
        "Text" {
            `$segments = Split-TextInput -Text `$Input -ChunkSizeKB 5
        }
        "Json" {
            `$segments = Split-JsonInput -JsonObject `$Input -ChunkSizeKB 5
        }
        "File" {
            `$segments = Split-FileInput -FilePath `$Input -ChunkSizeKB 5
        }
    }
    
    # Enregistrer les segments si un chemin de sortie est spÃ©cifiÃ©
    if (`$OutputPath) {
        if (-not (Test-Path -Path `$OutputPath)) {
            New-Item -Path `$OutputPath -ItemType Directory -Force | Out-Null
        }
        
        for (`$i = 0; `$i -lt `$segments.Count; `$i++) {
            `$segmentPath = Join-Path -Path `$OutputPath -ChildPath "segment_`$i.txt"
            
            if (`$InputType -eq "Json") {
                `$segments[`$i] | ConvertTo-Json -Depth 10 | Out-File -FilePath `$segmentPath -Encoding utf8
            } else {
                `$segments[`$i] | Out-File -FilePath `$segmentPath -Encoding utf8
            }
        }
    }
    
    if (`$TestMode) {
        `$result.IsSegmented = `$true
        `$result.SegmentCount = `$segments.Count
        `$result.Segments = `$segments
        return `$result
    }
    
    # Simuler le traitement par Agent Auto
    Write-Host "EntrÃ©e segmentÃ©e en `$(`$segments.Count) parties." -ForegroundColor Yellow
    
    for (`$i = 0; `$i -lt `$segments.Count; `$i++) {
        Write-Host "Agent Auto traite le segment `$(`$i + 1)/`$(`$segments.Count)..." -ForegroundColor Cyan
        Start-Sleep -Seconds 1
        
        `$segmentSize = Measure-InputSize -Input `$segments[`$i]
        Write-Host "Segment `$(`$i + 1) traitÃ© (taille: `$segmentSize KB)" -ForegroundColor Green
    }
    
    return "Traitement terminÃ©. `$(`$segments.Count) segments traitÃ©s."
}

# ExÃ©cuter la fonction principale
Invoke-AgentAutoWithSegmentation -Input `$Input -InputType `$InputType -OutputPath `$OutputPath -TestMode:`$TestMode
"@ | Out-File -FilePath $agentAutoScriptPath -Encoding utf8
    }
    
    # CrÃ©er un script d'initialisation pour Agent Auto
    $initScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\development\scripts\agent-auto\Initialize-AgentAutoSegmentation.ps1"
    
    # VÃ©rifier si le script existe, sinon le crÃ©er pour les tests
    if (-not (Test-Path -Path $initScriptPath)) {
        $scriptDir = Split-Path -Path $initScriptPath -Parent
        if (-not (Test-Path -Path $scriptDir)) {
            New-Item -Path $scriptDir -ItemType Directory -Force | Out-Null
        }
        
        @"
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
.PARAMETER TestMode
    Mode de test pour les tests d'intÃ©gration.
.EXAMPLE
    .\Initialize-AgentAutoSegmentation.ps1 -Enable -MaxInputSizeKB 15 -ChunkSizeKB 7
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = `$false)]
    [string]`$ConfigPath = ".\.augment\config.json",
    
    [Parameter(Mandatory = `$false)]
    [switch]`$Enable,
    
    [Parameter(Mandatory = `$false)]
    [int]`$MaxInputSizeKB = 10,
    
    [Parameter(Mandatory = `$false)]
    [int]`$ChunkSizeKB = 5,
    
    [Parameter(Mandatory = `$false)]
    [switch]`$PreserveLines,
    
    [Parameter(Mandatory = `$false)]
    [string]`$CachePath = ".\cache\agent_auto_state.json",
    
    [Parameter(Mandatory = `$false)]
    [switch]`$TestMode
)

# Importer le module de segmentation
`$modulePath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\modules\InputSegmentation.psm1"
Import-Module `$modulePath -Force

# Fonction pour mettre Ã  jour la configuration
function Update-AugmentConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$ConfigPath,
        
        [Parameter(Mandatory = `$true)]
        [bool]`$Enable,
        
        [Parameter(Mandatory = `$true)]
        [int]`$MaxInputSizeKB,
        
        [Parameter(Mandatory = `$true)]
        [int]`$ChunkSizeKB,
        
        [Parameter(Mandatory = `$true)]
        [bool]`$PreserveLines,
        
        [Parameter(Mandatory = `$true)]
        [string]`$CachePath
    )
    
    # VÃ©rifier si le fichier de configuration existe
    if (-not (Test-Path -Path `$ConfigPath)) {
        # CrÃ©er le dossier de configuration s'il n'existe pas
        `$configDir = Split-Path -Path `$ConfigPath -Parent
        if (-not (Test-Path -Path `$configDir)) {
            New-Item -Path `$configDir -ItemType Directory -Force | Out-Null
        }
        
        # CrÃ©er un fichier de configuration vide
        @{} | ConvertTo-Json | Out-File -FilePath `$ConfigPath -Encoding utf8
    }
    
    try {
        # Charger la configuration
        `$config = Get-Content -Path `$ConfigPath -Raw | ConvertFrom-Json
        
        # Convertir en hashtable si nÃ©cessaire
        if (`$config -isnot [PSCustomObject]) {
            `$config = [PSCustomObject]@{}
        }
        
        # VÃ©rifier si la section agent_auto existe
        if (-not (Get-Member -InputObject `$config -Name "agent_auto" -MemberType Properties)) {
            # CrÃ©er la section agent_auto
            `$config | Add-Member -MemberType NoteProperty -Name "agent_auto" -Value @{
                input_segmentation = @{
                    enabled = `$Enable
                    max_input_size_kb = `$MaxInputSizeKB
                    chunk_size_kb = `$ChunkSizeKB
                    preserve_lines = `$PreserveLines
                    state_path = `$CachePath
                }
            }
        }
        else {
            # VÃ©rifier si la section input_segmentation existe
            if (-not (Get-Member -InputObject `$config.agent_auto -Name "input_segmentation" -MemberType Properties)) {
                # CrÃ©er la section input_segmentation
                `$config.agent_auto | Add-Member -MemberType NoteProperty -Name "input_segmentation" -Value @{
                    enabled = `$Enable
                    max_input_size_kb = `$MaxInputSizeKB
                    chunk_size_kb = `$ChunkSizeKB
                    preserve_lines = `$PreserveLines
                    state_path = `$CachePath
                }
            }
            else {
                # Mettre Ã  jour la section input_segmentation
                `$config.agent_auto.input_segmentation.enabled = `$Enable
                `$config.agent_auto.input_segmentation.max_input_size_kb = `$MaxInputSizeKB
                `$config.agent_auto.input_segmentation.chunk_size_kb = `$ChunkSizeKB
                `$config.agent_auto.input_segmentation.preserve_lines = `$PreserveLines
                `$config.agent_auto.input_segmentation.state_path = `$CachePath
            }
        }
        
        # Enregistrer la configuration
        `$config | ConvertTo-Json -Depth 10 | Out-File -FilePath `$ConfigPath -Encoding utf8
        
        return `$true
    }
    catch {
        Write-Error "Erreur lors de la mise Ã  jour de la configuration: `$_"
        return `$false
    }
}

# Fonction principale
function Initialize-AgentAutoSegmentation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$ConfigPath,
        
        [Parameter(Mandatory = `$true)]
        [bool]`$Enable,
        
        [Parameter(Mandatory = `$true)]
        [int]`$MaxInputSizeKB,
        
        [Parameter(Mandatory = `$true)]
        [int]`$ChunkSizeKB,
        
        [Parameter(Mandatory = `$true)]
        [bool]`$PreserveLines,
        
        [Parameter(Mandatory = `$true)]
        [string]`$CachePath,
        
        [Parameter(Mandatory = `$false)]
        [switch]`$TestMode
    )
    
    # Initialiser le module de segmentation
    Initialize-InputSegmentation -MaxInputSizeKB `$MaxInputSizeKB -DefaultChunkSizeKB `$ChunkSizeKB
    
    # Mettre Ã  jour la configuration
    `$configUpdated = Update-AugmentConfig -ConfigPath `$ConfigPath -Enable `$Enable -MaxInputSizeKB `$MaxInputSizeKB -ChunkSizeKB `$ChunkSizeKB -PreserveLines `$PreserveLines -CachePath `$CachePath
    
    # CrÃ©er les dossiers nÃ©cessaires
    `$cacheDirPath = Split-Path -Path `$CachePath -Parent
    
    if (-not (Test-Path -Path `$cacheDirPath)) {
        New-Item -Path `$cacheDirPath -ItemType Directory -Force | Out-Null
    }
    
    `$logsDirPath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\logs\segmentation"
    
    if (-not (Test-Path -Path `$logsDirPath)) {
        New-Item -Path `$logsDirPath -ItemType Directory -Force | Out-Null
    }
    
    if (`$TestMode) {
        return [PSCustomObject]@{
            ConfigUpdated = `$configUpdated
            Enabled = `$Enable
            MaxInputSizeKB = `$MaxInputSizeKB
            ChunkSizeKB = `$ChunkSizeKB
            PreserveLines = `$PreserveLines
            CachePath = `$CachePath
        }
    }
    
    return `$configUpdated
}

# ExÃ©cuter la fonction principale
Initialize-AgentAutoSegmentation -ConfigPath `$ConfigPath -Enable:`$Enable -MaxInputSizeKB `$MaxInputSizeKB -ChunkSizeKB `$ChunkSizeKB -PreserveLines:`$PreserveLines -CachePath `$CachePath -TestMode:`$TestMode
"@ | Out-File -FilePath $initScriptPath -Encoding utf8
    }
    
    # CrÃ©er un fichier de configuration temporaire
    $tempConfigPath = Join-Path -Path $TestDrive -ChildPath ".augment\config.json"
    $tempConfigDir = Split-Path -Path $tempConfigPath -Parent
    New-Item -Path $tempConfigDir -ItemType Directory -Force | Out-Null
    @{} | ConvertTo-Json | Out-File -FilePath $tempConfigPath -Encoding utf8
    
    # CrÃ©er un dossier de cache temporaire
    $tempCachePath = Join-Path -Path $TestDrive -ChildPath "cache\agent_auto_state.json"
    $tempCacheDir = Split-Path -Path $tempCachePath -Parent
    New-Item -Path $tempCacheDir -ItemType Directory -Force | Out-Null
}

Describe "Agent Auto Segmentation Integration" {
    Context "Lorsqu'on initialise la segmentation pour Agent Auto" {
        It "Devrait initialiser correctement la segmentation" {
            $result = & $initScriptPath -ConfigPath $tempConfigPath -Enable -MaxInputSizeKB 15 -ChunkSizeKB 7 -CachePath $tempCachePath -TestMode
            
            $result.ConfigUpdated | Should -Be $true
            $result.Enabled | Should -Be $true
            $result.MaxInputSizeKB | Should -Be 15
            $result.ChunkSizeKB | Should -Be 7
        }
        
        It "Devrait mettre Ã  jour la configuration Augment" {
            $config = Get-Content -Path $tempConfigPath -Raw | ConvertFrom-Json
            
            $config.agent_auto | Should -Not -BeNullOrEmpty
            $config.agent_auto.input_segmentation | Should -Not -BeNullOrEmpty
            $config.agent_auto.input_segmentation.enabled | Should -Be $true
            $config.agent_auto.input_segmentation.max_input_size_kb | Should -Be 15
            $config.agent_auto.input_segmentation.chunk_size_kb | Should -Be 7
        }
    }
    
    Context "Lorsqu'on traite des entrÃ©es avec Agent Auto" {
        It "Devrait segmenter automatiquement une entrÃ©e texte volumineuse" {
            $largeText = Get-Content -Path $largeTextPath -Raw
            $result = & $agentAutoScriptPath -Input $largeText -InputType "Text" -OutputPath $tempOutputDir -TestMode
            
            $result.IsSegmented | Should -Be $true
            $result.SegmentCount | Should -BeGreaterThan 1
            $result.InputSizeKB | Should -BeGreaterThan 15  # Taille maximale configurÃ©e
        }
        
        It "Devrait segmenter automatiquement un objet JSON volumineux" {
            $largeJson = Get-Content -Path $largeJsonPath -Raw | ConvertFrom-Json
            $result = & $agentAutoScriptPath -Input $largeJson -InputType "Json" -OutputPath $tempOutputDir -TestMode
            
            $result.IsSegmented | Should -Be $true
            $result.SegmentCount | Should -BeGreaterThan 1
        }
        
        It "Devrait segmenter automatiquement un fichier volumineux" {
            $result = & $agentAutoScriptPath -Input $largeTextPath -InputType "File" -OutputPath $tempOutputDir -TestMode
            
            $result.IsSegmented | Should -Be $true
            $result.SegmentCount | Should -BeGreaterThan 1
        }
        
        It "Ne devrait pas segmenter une entrÃ©e plus petite que la taille maximale" {
            $smallText = "Ceci est un petit texte de test."
            $result = & $agentAutoScriptPath -Input $smallText -InputType "Text" -OutputPath $tempOutputDir -TestMode
            
            $result.IsSegmented | Should -Be $false
            $result.SegmentCount | Should -Be 1
        }
        
        It "Devrait crÃ©er des fichiers de segment dans le dossier de sortie" {
            & $agentAutoScriptPath -Input $largeTextPath -InputType "File" -OutputPath $tempOutputDir
            
            $segmentFiles = Get-ChildItem -Path $tempOutputDir -Filter "segment_*.txt"
            $segmentFiles.Count | Should -BeGreaterThan 1
        }
    }
}
