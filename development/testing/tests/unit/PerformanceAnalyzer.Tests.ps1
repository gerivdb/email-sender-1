# Tests unitaires pour le module PerformanceAnalyzer
# Utilise Pester 5.x

BeforeAll {
    # Chemin du module Ã  tester
    $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PerformanceAnalyzer.psm1"
    $MetricsCollectorPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\MetricsCollector.psm1"

    # VÃ©rifier si les modules existent
    $ModuleExists = Test-Path -Path $ModulePath
    $CollectorExists = Test-Path -Path $MetricsCollectorPath

    Write-Host "Module PerformanceAnalyzer exists: $ModuleExists"
    Write-Host "Module MetricsCollector exists: $CollectorExists"
    Write-Host "Module path: $ModulePath"

    # Importer les modules s'ils existent
    if ($ModuleExists) {
        Import-Module -Name $ModulePath -Force -Verbose
    }

    if ($CollectorExists) {
        Import-Module -Name $MetricsCollectorPath -Force -Verbose
    }

    # CrÃ©er des donnÃ©es de test
    $TestMetrics = @{
        CPU         = @{
            Usage         = 45.5
            UserTime      = 30.2
            SystemTime    = 15.3
            InterruptTime = 5.8
            DPCTime       = 2.1
            UsagePerCore  = @(40.2, 50.8, 45.3, 46.1)
            QueueLength   = 2
            TopProcesses  = @(
                @{Name = "Process1"; CPU = 15.2; WorkingSet = 1024 },
                @{Name = "Process2"; CPU = 10.5; WorkingSet = 512 },
                @{Name = "Process3"; CPU = 8.3; WorkingSet = 256 }
            )
            Temperature   = 65.0
            Anomalies     = @()
        }
        Memory      = @{
            Usage         = 65.3
            Available     = @{
                MB      = 4096
                Percent = 25.0
            }
            Performance   = @{
                PageFaultsPersec  = 120
                PagesInputPersec  = 45
                PagesOutputPersec = 30
                CommitPercent     = 70.5
            }
            TopProcesses  = @(
                @{Name = "Process1"; WorkingSet = 1024 },
                @{Name = "Process2"; WorkingSet = 512 },
                @{Name = "Process3"; WorkingSet = 256 }
            )
            LeakDetection = @{
                LeakDetected = $false
                LeakSuspects = @()
                MemoryGrowth = 0.5
            }
            Anomalies     = @()
        }
        Disk        = @{
            Usage         = @{
                Average = 75.2
                ByDrive = @(
                    @{Drive = "C:"; Usage = 85.5 },
                    @{Drive = "D:"; Usage = 65.0 }
                )
            }
            Performance   = @{
                LogicalDisks = @(
                    @{
                        Drive                  = "C:"
                        DiskReadBytesPersec    = 5.2
                        DiskWriteBytesPersec   = 3.1
                        DiskReadsPersec        = 120
                        DiskWritesPersec       = 80
                        CurrentDiskQueueLength = 1
                        AvgDiskSecPerTransfer  = 0.008
                    },
                    @{
                        Drive                  = "D:"
                        DiskReadBytesPersec    = 2.5
                        DiskWriteBytesPersec   = 1.8
                        DiskReadsPersec        = 60
                        DiskWritesPersec       = 40
                        CurrentDiskQueueLength = 0
                        AvgDiskSecPerTransfer  = 0.005
                    }
                )
                Total        = @{
                    ReadMBPerSec   = 7.7
                    WriteMBPerSec  = 4.9
                    ReadIOPS       = 180
                    WriteIOPS      = 120
                    TotalIOPS      = 300
                    QueueLength    = 1
                    ResponseTimeMS = 8.5
                    SplitIOPerSec  = 5
                }
            }
            TopProcesses  = @(
                @{Name = "Process1"; IOPS = 120 },
                @{Name = "Process2"; IOPS = 80 },
                @{Name = "Process3"; IOPS = 50 }
            )
            PhysicalDisks = @(
                @{
                    Index     = 0
                    Model     = "Samsung SSD 970 EVO 1TB"
                    SizeGB    = 1000
                    MediaType = "SSD"
                    Health    = @{Status = "OK" }
                }
            )
            Fragmentation = @(
                @{Drive = "C:"; FragmentationPercent = 5 },
                @{Drive = "D:"; FragmentationPercent = 12 }
            )
            Anomalies     = @()
        }
        Network     = @{
            BandwidthUsage = 35.8
            Throughput     = @{InMbps = 25.6; OutMbps = 10.2 }
            Latency        = 45.3
            Performance    = @{
                ErrorRate        = 0.2
                TotalErrors      = 15
                TotalPackets     = 7500
                DiscardedPackets = 5
            }
            Connections    = @{
                TCP      = @{
                    ByState   = @(
                        @{State = "Established"; Count = 95 },
                        @{State = "TimeWait"; Count = 20 },
                        @{State = "Listen"; Count = 10 }
                    )
                    ByProcess = @(
                        @{Process = "chrome"; Count = 45 },
                        @{Process = "firefox"; Count = 30 },
                        @{Process = "edge"; Count = 20 }
                    )
                    Total     = 125
                }
                TCPStats = @{
                    ConnectionFailures          = 5
                    ConnectionsActive           = 125
                    ConnectionsEstablished      = 95
                    ConnectionsPassive          = 30
                    ConnectionsReset            = 10
                    SegmentsReceivedPersec      = 450
                    SegmentsRetransmittedPersec = 15
                    SegmentsSentPersec          = 380
                }
                UDPStats = @{
                    DatagramsPersec         = 120
                    DatagramsReceivedErrors = 3
                    DatagramsReceivedPersec = 75
                    DatagramsSentPersec     = 45
                }
            }
            Anomalies      = @()
        }
        Application = @{
            ScriptExecutionTime   = @{
                "Script1.ps1" = 1250
                "Script2.ps1" = 850
                "Script3.ps1" = 1500
            }
            FunctionExecutionTime = @{
                "Function1" = 250
                "Function2" = 180
                "Function3" = 320
            }
            APIResponseTime       = @{
                "API1" = 450
                "API2" = 380
                "API3" = 520
            }
            ErrorRate             = 1.2
            ConcurrentOperations  = 45
        }
        Timestamp   = Get-Date
    }

    # CrÃ©er des mocks pour les fonctions externes
    function Get-CPUMetrics { return $TestMetrics.CPU }
    function Get-MemoryMetrics { return $TestMetrics.Memory }
    function Get-DiskMetrics { return $TestMetrics.Disk }
    function Get-NetworkMetrics { return $TestMetrics.Network }
    function Get-ApplicationMetrics { return $TestMetrics.Application }
}

Describe "PerformanceAnalyzer Module Tests" {
    Context "Module Import Tests" {
        It "Should import the PerformanceAnalyzer module without errors" -Skip:(-not $ModuleExists) {
            { Import-Module -Name $ModulePath -Force -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should import the MetricsCollector module without errors" -Skip:(-not $CollectorExists) {
            { Import-Module -Name $MetricsCollectorPath -Force -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Context "Initialize-PerformanceAnalyzer Tests" {
        It "Should have Initialize-PerformanceAnalyzer function" -Skip:(-not $ModuleExists) {
            { Get-Command -Name Initialize-PerformanceAnalyzer -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should initialize the module with default parameters" -Skip:(-not $ModuleExists) {
            { Initialize-PerformanceAnalyzer } | Should -Not -Throw
        }

        It "Should initialize the module with custom parameters" -Skip:(-not $ModuleExists) {
            { Initialize-PerformanceAnalyzer -ConfigPath "TestConfig.json" -LogPath "TestLog.log" -Enabled $true } | Should -Not -Throw
        }
    }

    Context "Initialize-MetricsCollector Tests" {
        It "Should have Initialize-MetricsCollector function" -Skip:(-not $CollectorExists) {
            { Get-Command -Name Initialize-MetricsCollector -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should initialize the collector with default parameters" -Skip:(-not $CollectorExists) {
            { Initialize-MetricsCollector } | Should -Not -Throw
        }

        It "Should initialize the collector with custom parameters" -Skip:(-not $CollectorExists) {
            { Initialize-MetricsCollector -CollectionInterval 10 -StoragePath "TestStorage" -Enabled $true } | Should -Not -Throw
        }
    }

    Context "Get-CPUMetrics Tests" {
        BeforeAll {
            # Mock pour Get-CimInstance
            Mock Get-CimInstance {
                if ($ClassName -eq 'Win32_Processor') {
                    return @(
                        [PSCustomObject]@{
                            Name              = "Intel(R) Core(TM) i7-9700K CPU @ 3.60GHz"
                            LoadPercentage    = 45
                            NumberOfCores     = 4
                            ThreadCount       = 8
                            CurrentClockSpeed = 3600
                            MaxClockSpeed     = 4600
                        }
                    )
                } elseif ($ClassName -eq 'Win32_PerfFormattedData_PerfOS_Processor') {
                    return @(
                        [PSCustomObject]@{
                            Name                 = "_Total"
                            PercentProcessorTime = 45.5
                            PercentIdleTime      = 54.5
                        },
                        [PSCustomObject]@{
                            Name                 = "0"
                            PercentProcessorTime = 40.2
                            PercentIdleTime      = 59.8
                        },
                        [PSCustomObject]@{
                            Name                 = "1"
                            PercentProcessorTime = 50.8
                            PercentIdleTime      = 49.2
                        },
                        [PSCustomObject]@{
                            Name                 = "2"
                            PercentProcessorTime = 45.3
                            PercentIdleTime      = 54.7
                        },
                        [PSCustomObject]@{
                            Name                 = "3"
                            PercentProcessorTime = 46.1
                            PercentIdleTime      = 53.9
                        }
                    )
                } elseif ($ClassName -eq 'Win32_PerfFormattedData_PerfOS_System') {
                    return [PSCustomObject]@{
                        ProcessorQueueLength = 2
                    }
                }
            }

            # Mock pour Get-Process
            Mock Get-Process {
                return @(
                    [PSCustomObject]@{
                        Name       = "Process1"
                        CPU        = 15.2
                        WorkingSet = 1073741824  # 1 GB
                    },
                    [PSCustomObject]@{
                        Name       = "Process2"
                        CPU        = 10.5
                        WorkingSet = 536870912  # 512 MB
                    },
                    [PSCustomObject]@{
                        Name       = "Process3"
                        CPU        = 8.3
                        WorkingSet = 268435456  # 256 MB
                    }
                )
            }
        }

        It "Should have Get-CPUMetrics function" -Skip:(-not $CollectorExists) {
            { Get-Command -Name Get-CPUMetrics -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should return CPU metrics" -Skip:(-not $CollectorExists) {
            $Result = Get-CPUMetrics
            $Result | Should -Not -BeNullOrEmpty
            $Result.Usage | Should -Be 45.5
            $Result.UsagePerCore.Count | Should -Be 4
            $Result.QueueLength | Should -Be 2
            $Result.TopProcesses.Count | Should -BeGreaterOrEqual 3
        }
    }

    Context "Get-MemoryMetrics Tests" {
        BeforeAll {
            # Mock pour Get-CimInstance
            Mock Get-CimInstance {
                if ($ClassName -eq 'Win32_OperatingSystem') {
                    return [PSCustomObject]@{
                        TotalVisibleMemorySize = 16384  # 16 GB
                        FreePhysicalMemory     = 4096      # 4 GB
                    }
                } elseif ($ClassName -eq 'Win32_PerfFormattedData_PerfOS_Memory') {
                    return [PSCustomObject]@{
                        PercentCommittedBytesInUse = 65.3
                        AvailableMBytes            = 4096
                        PageFaultsPersec           = 120
                    }
                }
            }
        }

        It "Should have Get-MemoryMetrics function" -Skip:(-not $CollectorExists) {
            { Get-Command -Name Get-MemoryMetrics -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should return memory metrics" -Skip:(-not $CollectorExists) {
            $Result = Get-MemoryMetrics
            $Result | Should -Not -BeNullOrEmpty
            $Result.Usage | Should -Be 65.3
            $Result.Available | Should -Be 4096
            $Result.PageFaults | Should -Be 120
            $Result.TopProcesses.Count | Should -BeGreaterOrEqual 3
        }
    }

    Context "Get-DiskMetrics Tests" {
        BeforeAll {
            # Mock pour Get-CimInstance
            Mock Get-CimInstance {
                if ($ClassName -eq 'Win32_LogicalDisk') {
                    return @(
                        [PSCustomObject]@{
                            DeviceID  = "C:"
                            Size      = 256000000000  # 256 GB
                            FreeSpace = 64000000000  # 64 GB
                        },
                        [PSCustomObject]@{
                            DeviceID  = "D:"
                            Size      = 512000000000  # 512 GB
                            FreeSpace = 128000000000  # 128 GB
                        }
                    )
                } elseif ($ClassName -eq 'Win32_PerfFormattedData_PerfDisk_LogicalDisk') {
                    return @(
                        [PSCustomObject]@{
                            Name                   = "_Total"
                            DiskReadBytesPersec    = 5000000
                            DiskWriteBytesPersec   = 2000000
                            CurrentDiskQueueLength = 1
                            AvgDiskSecPerTransfer  = 0.0085
                        }
                    )
                }
            }
        }

        It "Should have Get-DiskMetrics function" -Skip:(-not $CollectorExists) {
            { Get-Command -Name Get-DiskMetrics -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should return disk metrics" -Skip:(-not $CollectorExists) {
            $Result = Get-DiskMetrics
            $Result | Should -Not -BeNullOrEmpty
            $Result.Usage | Should -Be 75.2
            $Result.IOOperations | Should -Be 250
            $Result.QueueLength | Should -Be 1
            $Result.ResponseTime | Should -Be 8.5
            $Result.TopProcesses.Count | Should -BeGreaterOrEqual 3
        }
    }

    Context "Get-NetworkMetrics Tests" {
        BeforeAll {
            # Mock pour Get-CimInstance
            Mock Get-CimInstance {
                if ($ClassName -eq 'Win32_PerfFormattedData_Tcpip_NetworkInterface') {
                    return @(
                        [PSCustomObject]@{
                            Name                = "Ethernet"
                            BytesTotalPersec    = 35800000
                            BytesReceivedPersec = 25600000
                            BytesSentPersec     = 10200000
                            CurrentBandwidth    = 100000000
                        }
                    )
                }
            }

            # Mock pour Test-Connection
            Mock Test-Connection {
                return [PSCustomObject]@{
                    Destination = "8.8.8.8"
                    Latency     = 45.3
                }
            }

            # Mock pour Get-NetTCPConnection
            Mock Get-NetTCPConnection {
                return @(1..125 | ForEach-Object {
                        [PSCustomObject]@{
                            LocalAddress  = "192.168.1.100"
                            LocalPort     = (1000 + $_)
                            RemoteAddress = "192.168.1.1"
                            RemotePort    = 80
                            State         = "Established"
                        }
                    })
            }
        }

        It "Should have Get-NetworkMetrics function" -Skip:(-not $CollectorExists) {
            { Get-Command -Name Get-NetworkMetrics -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should return network metrics" -Skip:(-not $CollectorExists) {
            $Result = Get-NetworkMetrics
            $Result | Should -Not -BeNullOrEmpty
            $Result.BandwidthUsage | Should -Be 35.8
            $Result.Throughput.In | Should -Be 25.6
            $Result.Throughput.Out | Should -Be 10.2
            $Result.Latency | Should -Be 45.3
            $Result.Connections | Should -Be 125
        }
    }

    Context "Start-PerformanceAnalysis Tests" {
        It "Should have Start-PerformanceAnalysis function" -Skip:(-not $ModuleExists) {
            { Get-Command -Name Start-PerformanceAnalysis -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should start performance analysis" -Skip:(-not $ModuleExists) {
            { Start-PerformanceAnalysis } | Should -Not -Throw
        }

        It "Should start performance analysis with custom parameters" -Skip:(-not $ModuleExists) {
            { Start-PerformanceAnalysis -Duration 60 -CollectionInterval 5 -OutputPath "TestOutput" } | Should -Not -Throw
        }
    }

    Context "Get-PerformanceReport Tests" {
        It "Should have Get-PerformanceReport function" -Skip:(-not $ModuleExists) {
            { Get-Command -Name Get-PerformanceReport -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should generate a performance report" -Skip:(-not $ModuleExists) {
            $Report = Get-PerformanceReport
            $Report | Should -Not -BeNullOrEmpty
            $Report.CPU | Should -Not -BeNullOrEmpty
            $Report.Memory | Should -Not -BeNullOrEmpty
            $Report.Disk | Should -Not -BeNullOrEmpty
            $Report.Network | Should -Not -BeNullOrEmpty
        }

        It "Should generate a performance report with custom parameters" -Skip:(-not $ModuleExists) {
            $Report = Get-PerformanceReport -ReportType "Detailed" -TimeRange "Last1Hour" -Format "HTML"
            $Report | Should -Not -BeNullOrEmpty
        }
    }

    Context "Export-PerformanceData Tests" {
        It "Should have Export-PerformanceData function" -Skip:(-not $ModuleExists) {
            { Get-Command -Name Export-PerformanceData -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should export performance data to CSV" -Skip:(-not $ModuleExists) {
            $TempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.csv'
            { Export-PerformanceData -OutputPath $TempFile -Format "CSV" } | Should -Not -Throw
            Test-Path -Path $TempFile | Should -BeTrue
            Remove-Item -Path $TempFile -Force
        }

        It "Should export performance data to JSON" -Skip:(-not $ModuleExists) {
            $TempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
            { Export-PerformanceData -OutputPath $TempFile -Format "JSON" } | Should -Not -Throw
            Test-Path -Path $TempFile | Should -BeTrue
            Remove-Item -Path $TempFile -Force
        }
    }

    Context "Set-PerformanceThreshold Tests" {
        It "Should have Set-PerformanceThreshold function" -Skip:(-not $ModuleExists) {
            { Get-Command -Name Set-PerformanceThreshold -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should set a performance threshold" -Skip:(-not $ModuleExists) {
            { Set-PerformanceThreshold -MetricName "CPU.Usage" -Threshold 90 -Duration 300 } | Should -Not -Throw
        }

        It "Should validate threshold parameters" -Skip:(-not $ModuleExists) {
            { Set-PerformanceThreshold -MetricName "InvalidMetric" -Threshold 90 -Duration 300 } | Should -Throw
            { Set-PerformanceThreshold -MetricName "CPU.Usage" -Threshold 101 -Duration 300 } | Should -Throw
            { Set-PerformanceThreshold -MetricName "CPU.Usage" -Threshold 90 -Duration -10 } | Should -Throw
        }
    }

    Context "Get-PerformanceTrend Tests" {
        It "Should have Get-PerformanceTrend function" -Skip:(-not $ModuleExists) {
            { Get-Command -Name Get-PerformanceTrend -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should get performance trends" -Skip:(-not $ModuleExists) {
            $Trend = Get-PerformanceTrend -MetricName "CPU.Usage" -TimeRange "Last24Hours"
            $Trend | Should -Not -BeNullOrEmpty
            $Trend.MetricName | Should -Be "CPU.Usage"
            $Trend.Trend | Should -Not -BeNullOrEmpty
        }
    }

    Context "Find-PerformanceAnomaly Tests" {
        It "Should have Find-PerformanceAnomaly function" -Skip:(-not $ModuleExists) {
            { Get-Command -Name Find-PerformanceAnomaly -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should find performance anomalies" -Skip:(-not $ModuleExists) {
            $Anomalies = Find-PerformanceAnomaly -TimeRange "Last24Hours"
            $Anomalies | Should -Not -BeNullOrEmpty
        }
    }

    Context "Get-OptimizationRecommendation Tests" {
        It "Should have Get-OptimizationRecommendation function" -Skip:(-not $ModuleExists) {
            { Get-Command -Name Get-OptimizationRecommendation -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should get optimization recommendations" -Skip:(-not $ModuleExists) {
            $Recommendations = Get-OptimizationRecommendation
            $Recommendations | Should -Not -BeNullOrEmpty
            $Recommendations.Count | Should -BeGreaterThan 0
        }
    }
}

Context "Measure-CPUMetrics Tests" {
    It "Should have Measure-CPUMetrics function" {
        { Get-Command -Name Measure-CPUMetrics -ErrorAction Stop } | Should -Not -Throw
    }

    It "Should analyze CPU metrics correctly" {
        # CrÃ©er un tableau de mÃ©triques CPU pour simuler plusieurs Ã©chantillons
        $cpuMetrics = @($TestMetrics.CPU, $TestMetrics.CPU, $TestMetrics.CPU)

        # Modifier quelques valeurs pour simuler des variations
        $cpuMetrics[1].Usage = 82.5  # DÃ©passe le seuil
        $cpuMetrics[1].QueueLength = 6  # DÃ©passe le seuil
        $cpuMetrics[2].InterruptTime = 12.0  # DÃ©passe le seuil

        $result = Measure-CPUMetrics -CPUMetrics $cpuMetrics

        # VÃ©rifier la structure du rÃ©sultat
        $result | Should -Not -BeNullOrEmpty
        $result.Usage | Should -Not -BeNullOrEmpty
        $result.Usage.Average | Should -BeOfType [double]
        $result.Usage.Maximum | Should -BeOfType [double]
        $result.Usage.Trend | Should -BeIn @("Croissante", "DÃ©croissante", "Stable")

        # VÃ©rifier les anomalies
        $result.Anomalies | Should -Not -BeNullOrEmpty
        $result.Anomalies.Count | Should -BeGreaterThan 0

        # VÃ©rifier les recommandations
        $result.Recommendations | Should -Not -BeNullOrEmpty
        $result.Recommendations.Count | Should -BeGreaterThan 0
    }
}

Context "Measure-MemoryMetrics Tests" {
    It "Should have Measure-MemoryMetrics function" {
        { Get-Command -Name Measure-MemoryMetrics -ErrorAction Stop } | Should -Not -Throw
    }

    It "Should analyze memory metrics correctly" {
        # CrÃ©er un tableau de mÃ©triques mÃ©moire pour simuler plusieurs Ã©chantillons
        $memoryMetrics = @($TestMetrics.Memory, $TestMetrics.Memory, $TestMetrics.Memory)

        # Modifier quelques valeurs pour simuler des variations
        $memoryMetrics[1].Usage = 87.5  # DÃ©passe le seuil
        $memoryMetrics[1].Available.MB = 450  # Sous le seuil
        $memoryMetrics[2].Performance.PageFaultsPersec = 1200  # DÃ©passe le seuil

        $result = Measure-MemoryMetrics -MemoryMetrics $memoryMetrics

        # VÃ©rifier la structure du rÃ©sultat
        $result | Should -Not -BeNullOrEmpty
        $result.Usage | Should -Not -BeNullOrEmpty
        $result.Available | Should -Not -BeNullOrEmpty
        $result.PageFaults | Should -Not -BeNullOrEmpty

        # VÃ©rifier les anomalies
        $result.Anomalies | Should -Not -BeNullOrEmpty
        $result.Anomalies.Count | Should -BeGreaterThan 0

        # VÃ©rifier les recommandations
        $result.Recommendations | Should -Not -BeNullOrEmpty
        $result.Recommendations.Count | Should -BeGreaterThan 0
    }
}

Context "Measure-DiskMetrics Tests" {
    It "Should have Measure-DiskMetrics function" {
        { Get-Command -Name Measure-DiskMetrics -ErrorAction Stop } | Should -Not -Throw
    }

    It "Should analyze disk metrics correctly" {
        # CrÃ©er un tableau de mÃ©triques disque pour simuler plusieurs Ã©chantillons
        $diskMetrics = @($TestMetrics.Disk, $TestMetrics.Disk, $TestMetrics.Disk)

        # Modifier quelques valeurs pour simuler des variations
        $diskMetrics[1].Usage.Average = 92.5  # DÃ©passe le seuil
        $diskMetrics[1].Performance.Total.ResponseTimeMS = 25.0  # DÃ©passe le seuil
        $diskMetrics[2].Performance.Total.QueueLength = 3  # DÃ©passe le seuil

        $result = Measure-DiskMetrics -DiskMetrics $diskMetrics

        # VÃ©rifier la structure du rÃ©sultat
        $result | Should -Not -BeNullOrEmpty
        $result.Usage | Should -Not -BeNullOrEmpty
        $result.IOPS | Should -Not -BeNullOrEmpty
        $result.ResponseTime | Should -Not -BeNullOrEmpty
        $result.QueueLength | Should -Not -BeNullOrEmpty

        # VÃ©rifier les anomalies
        $result.Anomalies | Should -Not -BeNullOrEmpty
        $result.Anomalies.Count | Should -BeGreaterThan 0

        # VÃ©rifier les recommandations
        $result.Recommendations | Should -Not -BeNullOrEmpty
        $result.Recommendations.Count | Should -BeGreaterThan 0
    }
}

Context "Measure-NetworkMetrics Tests" {
    It "Should have Measure-NetworkMetrics function" {
        { Get-Command -Name Measure-NetworkMetrics -ErrorAction Stop } | Should -Not -Throw
    }

    It "Should analyze network metrics correctly" {
        # CrÃ©er un tableau de mÃ©triques rÃ©seau pour simuler plusieurs Ã©chantillons
        $networkMetrics = @($TestMetrics.Network, $TestMetrics.Network, $TestMetrics.Network)

        # Modifier quelques valeurs pour simuler des variations
        $networkMetrics[1].BandwidthUsage = 85.5  # DÃ©passe le seuil
        $networkMetrics[1].Latency = 120.0  # DÃ©passe le seuil
        $networkMetrics[2].Performance.ErrorRate = 0.15  # DÃ©passe le seuil

        $result = Measure-NetworkMetrics -NetworkMetrics $networkMetrics

        # VÃ©rifier la structure du rÃ©sultat
        $result | Should -Not -BeNullOrEmpty
        $result.BandwidthUsage | Should -Not -BeNullOrEmpty
        $result.Throughput | Should -Not -BeNullOrEmpty
        $result.Latency | Should -Not -BeNullOrEmpty
        $result.ErrorRate | Should -Not -BeNullOrEmpty

        # VÃ©rifier les anomalies
        $result.Anomalies | Should -Not -BeNullOrEmpty
        $result.Anomalies.Count | Should -BeGreaterThan 0

        # VÃ©rifier les recommandations
        $result.Recommendations | Should -Not -BeNullOrEmpty
        $result.Recommendations.Count | Should -BeGreaterThan 0
    }
}

Context "Measure-Metrics Tests" {
    It "Should have Measure-Metrics function" {
        { Get-Command -Name Measure-Metrics -ErrorAction Stop } | Should -Not -Throw
    }

    It "Should analyze all metrics correctly" {
        # CrÃ©er un tableau de mÃ©triques pour simuler plusieurs Ã©chantillons
        $metrics = @(
            @{
                CPU       = $TestMetrics.CPU
                Memory    = $TestMetrics.Memory
                Disk      = $TestMetrics.Disk
                Network   = $TestMetrics.Network
                Timestamp = (Get-Date).AddMinutes(-10)
            },
            @{
                CPU       = $TestMetrics.CPU
                Memory    = $TestMetrics.Memory
                Disk      = $TestMetrics.Disk
                Network   = $TestMetrics.Network
                Timestamp = (Get-Date).AddMinutes(-5)
            },
            @{
                CPU       = $TestMetrics.CPU
                Memory    = $TestMetrics.Memory
                Disk      = $TestMetrics.Disk
                Network   = $TestMetrics.Network
                Timestamp = Get-Date
            }
        )

        # Modifier quelques valeurs pour simuler des variations
        $metrics[1].CPU.Usage = 85.0  # DÃ©passe le seuil
        $metrics[1].Memory.Usage = 90.0  # DÃ©passe le seuil
        $metrics[2].Disk.Usage.Average = 95.0  # DÃ©passe le seuil
        $metrics[2].Network.BandwidthUsage = 85.0  # DÃ©passe le seuil

        $result = Measure-Metrics -Metrics $metrics

        # VÃ©rifier la structure du rÃ©sultat
        $result | Should -Not -BeNullOrEmpty
        $result.CPU | Should -Not -BeNullOrEmpty
        $result.Memory | Should -Not -BeNullOrEmpty
        $result.Disk | Should -Not -BeNullOrEmpty
        $result.Network | Should -Not -BeNullOrEmpty

        # VÃ©rifier les problÃ¨mes
        $result.Issues | Should -Not -BeNullOrEmpty
        $result.Issues.Count | Should -BeGreaterThan 0

        # VÃ©rifier les recommandations
        $result.Recommendations | Should -Not -BeNullOrEmpty
        $result.Recommendations.Count | Should -BeGreaterThan 0
    }
}

Context "Get-MetricTrend Tests" {
    It "Should have Get-MetricTrend function" {
        { Get-Command -Name Get-MetricTrend -ErrorAction Stop } | Should -Not -Throw
    }

    It "Should calculate trend correctly for increasing values" {
        $values = @(10, 20, 30, 40, 50)
        $result = Get-MetricTrend -Values $values
        $result | Should -Be "Croissante"
    }

    It "Should calculate trend correctly for decreasing values" {
        $values = @(50, 40, 30, 20, 10)
        $result = Get-MetricTrend -Values $values
        $result | Should -Be "DÃ©croissante"
    }

    It "Should calculate trend correctly for stable values" {
        $values = @(30, 31, 29, 30, 31)
        $result = Get-MetricTrend -Values $values
        $result | Should -Be "Stable"
    }

    It "Should handle single value correctly" {
        $values = @(30)
        $result = Get-MetricTrend -Values $values
        $result | Should -Be "Stable"
    }

    It "Should handle empty array correctly" {
        $values = @()
        $result = Get-MetricTrend -Values $values
        $result | Should -Be "Stable"
    }
}

AfterAll {
    # Nettoyer les modules importÃ©s
    if ($ModuleExists) {
        Remove-Module -Name "PerformanceAnalyzer" -Force -ErrorAction SilentlyContinue
    }

    if ($CollectorExists) {
        Remove-Module -Name "MetricsCollector" -Force -ErrorAction SilentlyContinue
    }
}
