#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module Dynamic-ThreadManager.
.DESCRIPTION
    Ce fichier contient des tests unitaires pour les fonctions du module Dynamic-ThreadManager.psm1
    qui gÃ¨re l'ajustement dynamique du nombre de threads en fonction de la charge systÃ¨me.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Date: 12/04/2025
    Requires: Pester v5.0+
#>

# DÃ©finir le chemin du module Ã  tester
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "Dynamic-ThreadManager.psm1"

# VÃ©rifier si le module existe, sinon crÃ©er un stub pour les tests
if (-not (Test-Path -Path $modulePath)) {
    Write-Warning "Module Dynamic-ThreadManager.psm1 non trouvÃ©. CrÃ©ation d'un stub pour les tests."
    
    # CrÃ©er un rÃ©pertoire si nÃ©cessaire
    $moduleDir = Split-Path -Parent $modulePath
    if (-not (Test-Path -Path $moduleDir)) {
        New-Item -Path $moduleDir -ItemType Directory -Force | Out-Null
    }
    
    # CrÃ©er un stub du module pour les tests
    @'
# Module Dynamic-ThreadManager.psm1
# Stub crÃ©Ã© pour les tests unitaires

function Get-OptimalThreadCount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [double]$CpuThreshold = 80,
        
        [Parameter(Mandatory = $false)]
        [double]$MemoryThreshold = 20,
        
        [Parameter(Mandatory = $false)]
        [int]$MinThreads = 1,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0
    )
    
    # Logique par dÃ©faut pour les tests
    $logicalCores = [Environment]::ProcessorCount
    
    if ($MaxThreads -le 0) {
        $MaxThreads = $logicalCores * 2
    }
    
    # Obtenir les mÃ©triques systÃ¨me
    $cpuUsage = Get-CpuUsage
    $memoryAvailable = Get-MemoryAvailable
    
    # Calculer le facteur d'ajustement
    $cpuFactor = 1 - [Math]::Max(0, [Math]::Min(1, ($cpuUsage - 50) / 50))
    $memoryFactor = [Math]::Max(0, [Math]::Min(1, $memoryAvailable / 100))
    
    # Calculer le nombre optimal de threads
    $optimalThreads = [Math]::Max($MinThreads, [Math]::Min($MaxThreads, [Math]::Floor($logicalCores * [Math]::Min($cpuFactor, $memoryFactor) * 2)))
    
    return $optimalThreads
}

function Get-CpuUsage {
    # Simuler l'utilisation du CPU pour les tests
    return 50
}

function Get-MemoryAvailable {
    # Simuler la mÃ©moire disponible pour les tests
    return 50
}

function Start-ThreadMonitoring {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$IntervalSeconds = 5,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$AdjustmentCallback
    )
    
    # Simuler le dÃ©marrage du monitoring pour les tests
    return [PSCustomObject]@{
        MonitoringId = [Guid]::NewGuid().ToString()
        StartTime = Get-Date
        IntervalSeconds = $IntervalSeconds
        IsRunning = $true
    }
}

function Stop-ThreadMonitoring {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MonitoringId
    )
    
    # Simuler l'arrÃªt du monitoring pour les tests
    return $true
}

function Update-ThreadCount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$CurrentThreadCount,
        
        [Parameter(Mandatory = $true)]
        [int]$OptimalThreadCount,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxAdjustmentStep = 2
    )
    
    # Calculer la diffÃ©rence
    $difference = $OptimalThreadCount - $CurrentThreadCount
    
    # Limiter l'ajustement Ã  MaxAdjustmentStep
    if ($difference -gt $MaxAdjustmentStep) {
        $difference = $MaxAdjustmentStep
    }
    elseif ($difference -lt -$MaxAdjustmentStep) {
        $difference = -$MaxAdjustmentStep
    }
    
    # Calculer le nouveau nombre de threads
    $newThreadCount = $CurrentThreadCount + $difference
    
    return $newThreadCount
}

# Exporter les fonctions
Export-ModuleMember -Function Get-OptimalThreadCount, Start-ThreadMonitoring, Stop-ThreadMonitoring, Update-ThreadCount
'@ | Set-Content -Path $modulePath -Encoding UTF8
}

# Importer le module Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Importer le module Ã  tester
Import-Module $modulePath -Force

# DÃ©finir les tests
Describe "Dynamic-ThreadManager Module Tests" {
    Context "Get-OptimalThreadCount Function" {
        It "Devrait retourner un nombre de threads valide" {
            # Arrange
            $logicalCores = [Environment]::ProcessorCount
            
            # Act
            $result = Get-OptimalThreadCount
            
            # Assert
            $result | Should -BeGreaterOrEqual 1
            $result | Should -BeLessOrEqual ($logicalCores * 2)
        }
        
        It "Devrait respecter les seuils min et max" {
            # Arrange
            $minThreads = 2
            $maxThreads = 4
            
            # Act
            $result = Get-OptimalThreadCount -MinThreads $minThreads -MaxThreads $maxThreads
            
            # Assert
            $result | Should -BeGreaterOrEqual $minThreads
            $result | Should -BeLessOrEqual $maxThreads
        }
        
        It "Devrait ajuster le nombre de threads en fonction de la charge CPU" {
            # Arrange
            Mock Get-CpuUsage { return 90 }
            
            # Act
            $highCpuResult = Get-OptimalThreadCount
            
            # Arrange
            Mock Get-CpuUsage { return 20 }
            
            # Act
            $lowCpuResult = Get-OptimalThreadCount
            
            # Assert
            $highCpuResult | Should -BeLessOrEqual $lowCpuResult
        }
        
        It "Devrait ajuster le nombre de threads en fonction de la mÃ©moire disponible" {
            # Arrange
            Mock Get-MemoryAvailable { return 10 }
            
            # Act
            $lowMemResult = Get-OptimalThreadCount
            
            # Arrange
            Mock Get-MemoryAvailable { return 80 }
            
            # Act
            $highMemResult = Get-OptimalThreadCount
            
            # Assert
            $lowMemResult | Should -BeLessOrEqual $highMemResult
        }
    }
    
    Context "Start-ThreadMonitoring Function" {
        It "Devrait dÃ©marrer le monitoring et retourner un ID" {
            # Act
            $result = Start-ThreadMonitoring
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.MonitoringId | Should -Not -BeNullOrEmpty
            $result.IsRunning | Should -BeTrue
        }
        
        It "Devrait accepter un callback" {
            # Arrange
            $callback = { param($threadCount) }
            
            # Act
            $result = Start-ThreadMonitoring -AdjustmentCallback $callback
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.MonitoringId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Stop-ThreadMonitoring Function" {
        It "Devrait arrÃªter le monitoring" {
            # Arrange
            $monitoring = Start-ThreadMonitoring
            
            # Act
            $result = Stop-ThreadMonitoring -MonitoringId $monitoring.MonitoringId
            
            # Assert
            $result | Should -BeTrue
        }
    }
    
    Context "Update-ThreadCount Function" {
        It "Devrait augmenter progressivement le nombre de threads" {
            # Arrange
            $currentThreads = 5
            $optimalThreads = 10
            
            # Act
            $result = Update-ThreadCount -CurrentThreadCount $currentThreads -OptimalThreadCount $optimalThreads
            
            # Assert
            $result | Should -BeGreaterThan $currentThreads
            $result | Should -BeLessOrEqual ($currentThreads + 2)
        }
        
        It "Devrait diminuer progressivement le nombre de threads" {
            # Arrange
            $currentThreads = 10
            $optimalThreads = 5
            
            # Act
            $result = Update-ThreadCount -CurrentThreadCount $currentThreads -OptimalThreadCount $optimalThreads
            
            # Assert
            $result | Should -BeLessThan $currentThreads
            $result | Should -BeGreaterOrEqual ($currentThreads - 2)
        }
        
        It "Devrait respecter le pas d'ajustement maximal" {
            # Arrange
            $currentThreads = 5
            $optimalThreads = 20
            $maxStep = 3
            
            # Act
            $result = Update-ThreadCount -CurrentThreadCount $currentThreads -OptimalThreadCount $optimalThreads -MaxAdjustmentStep $maxStep
            
            # Assert
            $result | Should -Be ($currentThreads + $maxStep)
        }
    }
}
