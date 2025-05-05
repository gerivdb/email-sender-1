BeforeAll {
    # Importer le module Ã  tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\MetricsCollector.psm1"
    Import-Module $modulePath -Force

    # Initialiser la configuration pour les tests
    Initialize-MetricsCollector -TopProcessCount 5
}

Describe "MetricsCollector" {
    Context "Configuration" {
        It "Should initialize the configuration correctly" {
            # VÃ©rifier que la fonction d'initialisation fonctionne correctement
            $config = Initialize-MetricsCollector -TopProcessCount 10
            $config | Should -Not -BeNullOrEmpty
            $config.TopProcessCount | Should -Be 10
        }
    }

    Context "Get-CPUMetrics" {
        It "Should return CPU metrics" {
            $metrics = Get-CPUMetrics
            $metrics | Should -Not -BeNullOrEmpty
            $metrics.Info | Should -Not -BeNullOrEmpty
            $metrics.Usage | Should -Not -BeNullOrEmpty
            $metrics.UsagePerCore | Should -Not -BeNullOrEmpty
            $metrics.TopProcesses | Should -Not -BeNullOrEmpty
        }

        It "Should return CPU metrics with expected properties" {
            $metrics = Get-CPUMetrics
            $metrics.Info.Keys | Should -Contain "Name"
            $metrics.Info.Keys | Should -Contain "Cores"
            $metrics.Info.Keys | Should -Contain "LogicalProcessors"
            $metrics.UsagePerCore | ForEach-Object {
                $_.Keys | Should -Contain "CoreID"
                $_.Keys | Should -Contain "Usage"
            }
            $metrics.TopProcesses | ForEach-Object {
                $_.Keys | Should -Contain "Name"
                $_.Keys | Should -Contain "ID"
                $_.Keys | Should -Contain "CPU"
            }
        }
    }

    Context "Get-MemoryMetrics" {
        It "Should return memory metrics" {
            $metrics = Get-MemoryMetrics
            $metrics | Should -Not -BeNullOrEmpty
            $metrics.Physical | Should -Not -BeNullOrEmpty
            $metrics.Virtual | Should -Not -BeNullOrEmpty
            $metrics.PageFile | Should -Not -BeNullOrEmpty
            $metrics.Performance | Should -Not -BeNullOrEmpty
            $metrics.TopProcesses | Should -Not -BeNullOrEmpty
        }

        It "Should return memory metrics with expected properties" {
            $metrics = Get-MemoryMetrics
            $metrics.Physical.Keys | Should -Contain "TotalMB"
            $metrics.Physical.Keys | Should -Contain "AvailableMB"
            $metrics.Physical.Keys | Should -Contain "UsedMB"
            $metrics.Physical.Keys | Should -Contain "UsagePercent"

            $metrics.Virtual.Keys | Should -Contain "TotalMB"
            $metrics.Virtual.Keys | Should -Contain "AvailableMB"

            $metrics.PageFile.Keys | Should -Contain "TotalMB"
            $metrics.PageFile.Keys | Should -Contain "UsedMB"

            $metrics.Performance.Keys | Should -Contain "PageFaultsPersec"

            $metrics.TopProcesses | ForEach-Object {
                $_.Keys | Should -Contain "Name"
                $_.Keys | Should -Contain "ID"
                $_.Keys | Should -Contain "WorkingSetMB"
            }
        }
    }

    Context "Get-DiskMetrics" {
        It "Should return disk metrics" {
            $metrics = Get-DiskMetrics
            $metrics | Should -Not -BeNullOrEmpty
            $metrics.LogicalDisks | Should -Not -BeNullOrEmpty
            $metrics.Performance | Should -Not -BeNullOrEmpty
            $metrics.Usage | Should -Not -BeNullOrEmpty
            $metrics.TopProcesses | Should -Not -BeNullOrEmpty
        }

        It "Should return disk metrics with expected properties" {
            $metrics = Get-DiskMetrics
            $metrics.LogicalDisks | ForEach-Object {
                $_.Keys | Should -Contain "Drive"
                $_.Keys | Should -Contain "Size"
                $_.Keys | Should -Contain "FreeSpace"
                $_.Keys | Should -Contain "UsedSpace"
                $_.Keys | Should -Contain "Usage"
            }

            $metrics.Performance.Total.Keys | Should -Contain "ReadMBPerSec"
            $metrics.Performance.Total.Keys | Should -Contain "WriteMBPerSec"
            $metrics.Performance.Total.Keys | Should -Contain "TotalIOPS"

            $metrics.Usage.Keys | Should -Contain "Average"
            $metrics.Usage.Keys | Should -Contain "ByDrive"

            $metrics.TopProcesses | ForEach-Object {
                $_.Keys | Should -Contain "Name"
                $_.Keys | Should -Contain "ID"
                $_.Keys | Should -Contain "IO"
            }
        }
    }

    Context "Get-NetworkMetrics" {
        It "Should return network metrics" {
            $metrics = Get-NetworkMetrics
            $metrics | Should -Not -BeNullOrEmpty
            $metrics.Interfaces | Should -Not -BeNullOrEmpty
            $metrics.Usage | Should -Not -BeNullOrEmpty
            $metrics.Connectivity | Should -Not -BeNullOrEmpty
            $metrics.Connections | Should -Not -BeNullOrEmpty
            $metrics.Performance | Should -Not -BeNullOrEmpty
        }

        It "Should return network metrics with expected properties" {
            $metrics = Get-NetworkMetrics
            $metrics.Interfaces | ForEach-Object {
                $_.Keys | Should -Contain "Name"
                $_.Keys | Should -Contain "BytesReceivedPerSec"
                $_.Keys | Should -Contain "BytesSentPerSec"
                $_.Keys | Should -Contain "Bandwidth"
            }

            $metrics.Usage.Keys | Should -Contain "BandwidthUsage"
            $metrics.Usage.Keys | Should -Contain "Throughput"

            $metrics.Connectivity.Keys | Should -Contain "PingResults"
            $metrics.Connectivity.Keys | Should -Contain "InternetQuality"

            $metrics.Connections.Keys | Should -Contain "TCP"

            $metrics.Performance.Keys | Should -Contain "ErrorRate"
        }
    }

    Context "Get-SystemMetrics" {
        It "Should return system metrics" {
            $metrics = Get-SystemMetrics
            $metrics | Should -Not -BeNullOrEmpty
            $metrics.CPU | Should -Not -BeNullOrEmpty
            $metrics.Memory | Should -Not -BeNullOrEmpty
            $metrics.Disk | Should -Not -BeNullOrEmpty
            $metrics.Network | Should -Not -BeNullOrEmpty
            $metrics.System | Should -Not -BeNullOrEmpty
        }

        It "Should return system metrics with expected properties" {
            $metrics = Get-SystemMetrics
            $metrics.CPU.Keys | Should -Contain "Usage"
            $metrics.Memory.Physical.Keys | Should -Contain "UsagePercent"
            $metrics.Disk.Usage.Keys | Should -Contain "Average"
            $metrics.Network.Usage.Keys | Should -Contain "BandwidthUsage"
            $metrics.System.Keys | Should -Contain "ComputerName"
            $metrics.System.Keys | Should -Contain "OperatingSystem"
        }
    }
}

AfterAll {
    # Nettoyer aprÃ¨s les tests
    Remove-Module MetricsCollector -ErrorAction SilentlyContinue
}
