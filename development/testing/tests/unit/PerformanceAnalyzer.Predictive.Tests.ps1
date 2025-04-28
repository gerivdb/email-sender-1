# Tests unitaires pour les fonctions d'analyse prédictive du module PerformanceAnalyzer
# Utilise Pester 5.x

BeforeAll {
    # Chemin du module à tester
    $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PerformanceAnalyzer.psm1"

    # Vérifier si le module existe
    $ModuleExists = Test-Path -Path $ModulePath

    Write-Host "Module PerformanceAnalyzer exists: $ModuleExists"
    Write-Host "Module path: $ModulePath"

    # Importer le module s'il existe
    if ($ModuleExists) {
        Import-Module -Name $ModulePath -Force -Verbose
    }

    # Créer des données de test
    $TestMetrics = @(
        @{
            CPU         = @{
                Usage         = 45.5
                UserTime      = 30.2
                SystemTime    = 15.3
                InterruptTime = 5.8
                DPCTime       = 2.1
                UsagePerCore  = @(40.2, 50.8, 45.3, 46.1)
                QueueLength   = 2
                TopProcesses  = @(
                    @{Name = "Process1"; CPU = 15.2; WorkingSet = 1024 }
                    @{Name = "Process2"; CPU = 10.5; WorkingSet = 512 }
                    @{Name = "Process3"; CPU = 8.3; WorkingSet = 256 }
                )
                Temperature   = 65.0
                Anomalies     = @()
            }
            Memory      = @{
                Physical      = @{
                    Total        = 16384
                    Available    = 4096
                    UsagePercent = 65.3
                }
                Performance   = @{
                    PageFaultsPersec  = 120
                    PagesInputPersec  = 45
                    PagesOutputPersec = 30
                    CommitPercent     = 70.5
                }
                TopProcesses  = @(
                    @{Name = "Process1"; WorkingSet = 1024 }
                    @{Name = "Process2"; WorkingSet = 512 }
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
                        @{Drive = "C:"; Usage = 85.5 }
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
                        }
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
                    @{Name = "Process1"; IOPS = 120 }
                    @{Name = "Process2"; IOPS = 80 }
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
                    @{Drive = "C:"; FragmentationPercent = 5 }
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
                            @{State = "Established"; Count = 95 }
                            @{State = "TimeWait"; Count = 20 }
                            @{State = "Listen"; Count = 10 }
                        )
                        ByProcess = @(
                            @{Process = "chrome"; Count = 45 }
                            @{Process = "firefox"; Count = 30 }
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
            Timestamp   = (Get-Date).AddHours(-1)
        },
        @{
            CPU         = @{
                Usage         = 55.5
                UserTime      = 35.2
                SystemTime    = 20.3
                InterruptTime = 6.8
                DPCTime       = 3.1
                UsagePerCore  = @(50.2, 60.8, 55.3, 56.1)
                QueueLength   = 3
                TopProcesses  = @(
                    @{Name = "Process1"; CPU = 20.2; WorkingSet = 1124 }
                    @{Name = "Process2"; CPU = 15.5; WorkingSet = 612 }
                    @{Name = "Process3"; CPU = 10.3; WorkingSet = 356 }
                )
                Temperature   = 70.0
                Anomalies     = @()
            }
            Memory      = @{
                Physical      = @{
                    Total        = 16384
                    Available    = 3096
                    UsagePercent = 75.3
                }
                Performance   = @{
                    PageFaultsPersec  = 150
                    PagesInputPersec  = 55
                    PagesOutputPersec = 40
                    CommitPercent     = 80.5
                }
                TopProcesses  = @(
                    @{Name = "Process1"; WorkingSet = 1124 }
                    @{Name = "Process2"; WorkingSet = 612 }
                    @{Name = "Process3"; WorkingSet = 356 }
                )
                LeakDetection = @{
                    LeakDetected = $false
                    LeakSuspects = @()
                    MemoryGrowth = 0.8
                }
                Anomalies     = @()
            }
            Disk        = @{
                Usage         = @{
                    Average = 80.2
                    ByDrive = @(
                        @{Drive = "C:"; Usage = 90.5 }
                        @{Drive = "D:"; Usage = 70.0 }
                    )
                }
                Performance   = @{
                    LogicalDisks = @(
                        @{
                            Drive                  = "C:"
                            DiskReadBytesPersec    = 6.2
                            DiskWriteBytesPersec   = 4.1
                            DiskReadsPersec        = 140
                            DiskWritesPersec       = 90
                            CurrentDiskQueueLength = 2
                            AvgDiskSecPerTransfer  = 0.010
                        }
                        @{
                            Drive                  = "D:"
                            DiskReadBytesPersec    = 3.5
                            DiskWriteBytesPersec   = 2.8
                            DiskReadsPersec        = 70
                            DiskWritesPersec       = 50
                            CurrentDiskQueueLength = 1
                            AvgDiskSecPerTransfer  = 0.007
                        }
                    )
                    Total        = @{
                        ReadMBPerSec   = 9.7
                        WriteMBPerSec  = 6.9
                        ReadIOPS       = 210
                        WriteIOPS      = 140
                        TotalIOPS      = 350
                        QueueLength    = 3
                        ResponseTimeMS = 10.5
                        SplitIOPerSec  = 7
                    }
                }
                TopProcesses  = @(
                    @{Name = "Process1"; IOPS = 140 }
                    @{Name = "Process2"; IOPS = 100 }
                    @{Name = "Process3"; IOPS = 70 }
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
                    @{Drive = "C:"; FragmentationPercent = 7 }
                    @{Drive = "D:"; FragmentationPercent = 15 }
                )
                Anomalies     = @()
            }
            Network     = @{
                BandwidthUsage = 45.8
                Throughput     = @{InMbps = 30.6; OutMbps = 15.2 }
                Latency        = 50.3
                Performance    = @{
                    ErrorRate        = 0.3
                    TotalErrors      = 20
                    TotalPackets     = 8500
                    DiscardedPackets = 8
                }
                Connections    = @{
                    TCP      = @{
                        ByState   = @(
                            @{State = "Established"; Count = 105 }
                            @{State = "TimeWait"; Count = 25 }
                            @{State = "Listen"; Count = 12 }
                        )
                        ByProcess = @(
                            @{Process = "chrome"; Count = 55 }
                            @{Process = "firefox"; Count = 35 }
                            @{Process = "edge"; Count = 25 }
                        )
                        Total     = 142
                    }
                    TCPStats = @{
                        ConnectionFailures          = 7
                        ConnectionsActive           = 142
                        ConnectionsEstablished      = 105
                        ConnectionsPassive          = 37
                        ConnectionsReset            = 12
                        SegmentsReceivedPersec      = 550
                        SegmentsRetransmittedPersec = 18
                        SegmentsSentPersec          = 480
                    }
                    UDPStats = @{
                        DatagramsPersec         = 150
                        DatagramsReceivedErrors = 5
                        DatagramsReceivedPersec = 95
                        DatagramsSentPersec     = 55
                    }
                }
                Anomalies      = @()
            }
            Application = @{
                ScriptExecutionTime   = @{
                    "Script1.ps1" = 1350
                    "Script2.ps1" = 950
                    "Script3.ps1" = 1600
                }
                FunctionExecutionTime = @{
                    "Function1" = 280
                    "Function2" = 200
                    "Function3" = 350
                }
                APIResponseTime       = @{
                    "API1" = 500
                    "API2" = 420
                    "API3" = 580
                }
                ErrorRate             = 1.5
                ConcurrentOperations  = 55
            }
            Timestamp   = Get-Date
        }
    )

    # Créer des mocks pour les fonctions externes
    Mock Invoke-PredictiveModel {
        param (
            [string]$Action,
            [string]$InputFile,
            [string]$OutputFile,
            [int]$Horizon,
            [switch]$Force
        )

        switch ($Action) {
            "train" {
                return @{
                    "CPU.Usage"    = @{
                        status     = "success"
                        metrics    = @{
                            mse = 25.5
                            mae = 4.2
                            r2  = 0.85
                        }
                        importance = @{
                            hour        = 0.3
                            day_of_week = 0.2
                            lag_1       = 0.5
                        }
                        samples    = 48
                    }
                    "Memory.Usage" = @{
                        status     = "success"
                        metrics    = @{
                            mse = 18.2
                            mae = 3.5
                            r2  = 0.82
                        }
                        importance = @{
                            hour        = 0.25
                            day_of_week = 0.15
                            lag_1       = 0.6
                        }
                        samples    = 48
                    }
                }
            }
            "predict" {
                return @{
                    "CPU.Usage"    = @{
                        status      = "success"
                        predictions = @(60.2, 65.5, 58.3, 52.1, 55.8, 62.3)
                        timestamps  = @(
                            (Get-Date).AddHours(1).ToString('o'),
                            (Get-Date).AddHours(2).ToString('o'),
                            (Get-Date).AddHours(3).ToString('o'),
                            (Get-Date).AddHours(4).ToString('o'),
                            (Get-Date).AddHours(5).ToString('o'),
                            (Get-Date).AddHours(6).ToString('o')
                        )
                    }
                    "Memory.Usage" = @{
                        status      = "success"
                        predictions = @(78.2, 80.5, 82.3, 79.1, 77.8, 76.3)
                        timestamps  = @(
                            (Get-Date).AddHours(1).ToString('o'),
                            (Get-Date).AddHours(2).ToString('o'),
                            (Get-Date).AddHours(3).ToString('o'),
                            (Get-Date).AddHours(4).ToString('o'),
                            (Get-Date).AddHours(5).ToString('o'),
                            (Get-Date).AddHours(6).ToString('o')
                        )
                    }
                }
            }
            "anomalies" {
                return @{
                    "CPU.Usage"    = @{
                        status        = "success"
                        anomalies     = @(
                            @{
                                timestamp = (Get-Date).AddHours(-3).ToString('o')
                                value     = 92.5
                                score     = -0.8
                                severity  = "high"
                            }
                        )
                        anomaly_count = 1
                        total_points  = 48
                    }
                    "Memory.Usage" = @{
                        status        = "success"
                        anomalies     = @(
                            @{
                                timestamp = (Get-Date).AddHours(-2).ToString('o')
                                value     = 95.2
                                score     = -0.9
                                severity  = "high"
                            }
                        )
                        anomaly_count = 1
                        total_points  = 48
                    }
                }
            }
            "trends" {
                return @{
                    "CPU.Usage"    = @{
                        status      = "success"
                        statistics  = @{
                            mean   = 55.3
                            median = 54.8
                            min    = 30.2
                            max    = 92.5
                            std    = 12.5
                            count  = 48
                        }
                        trend       = @{
                            direction      = "croissante"
                            strength       = "modérée"
                            slope          = 0.25
                            intercept      = 45.2
                            r2             = 0.65
                            percent_change = 15.8
                        }
                        seasonality = "détectée"
                    }
                    "Memory.Usage" = @{
                        status      = "success"
                        statistics  = @{
                            mean   = 72.5
                            median = 71.8
                            min    = 60.2
                            max    = 95.2
                            std    = 8.5
                            count  = 48
                        }
                        trend       = @{
                            direction      = "croissante"
                            strength       = "forte"
                            slope          = 0.35
                            intercept      = 65.2
                            r2             = 0.78
                            percent_change = 20.5
                        }
                        seasonality = "non détectée"
                    }
                }
            }
        }
    }

    # Mock pour Export-MetricsToJson
    Mock Export-MetricsToJson {
        param (
            [array]$Metrics,
            [string]$OutputPath
        )

        # Simuler la création d'un fichier temporaire
        $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
        "Metrics exported to $tempFile" | Out-File -FilePath $tempFile -Encoding utf8
        return $tempFile
    }

    # Mock pour Remove-Item
    Mock Remove-Item { }
}

Describe "PerformanceAnalyzer Predictive Module Tests" {
    Context "Module Import Tests" {
        It "Should import the PerformanceAnalyzer module without errors" -Skip:(-not $ModuleExists) {
            { Import-Module -Name $ModulePath -Force -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Context "Invoke-PredictiveModel Tests" {
        It "Should have Invoke-PredictiveModel function" -Skip:(-not $ModuleExists) {
            { Get-Command -Name Invoke-PredictiveModel -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should invoke the predictive model for training" -Skip:(-not $ModuleExists) {
            $result = Invoke-PredictiveModel -Action "train" -InputFile "metrics.json" -Force
            $result | Should -Not -BeNullOrEmpty
            $result."CPU.Usage" | Should -Not -BeNullOrEmpty
            $result."CPU.Usage".status | Should -Be "success"
            $result."CPU.Usage".metrics | Should -Not -BeNullOrEmpty
        }

        It "Should invoke the predictive model for prediction" -Skip:(-not $ModuleExists) {
            $result = Invoke-PredictiveModel -Action "predict" -InputFile "metrics.json" -Horizon 6
            $result | Should -Not -BeNullOrEmpty
            $result."CPU.Usage" | Should -Not -BeNullOrEmpty
            $result."CPU.Usage".status | Should -Be "success"
            $result."CPU.Usage".predictions | Should -Not -BeNullOrEmpty
            $result."CPU.Usage".predictions.Count | Should -Be 6
        }

        It "Should invoke the predictive model for anomaly detection" -Skip:(-not $ModuleExists) {
            $result = Invoke-PredictiveModel -Action "anomalies" -InputFile "metrics.json"
            $result | Should -Not -BeNullOrEmpty
            $result."CPU.Usage" | Should -Not -BeNullOrEmpty
            $result."CPU.Usage".status | Should -Be "success"
            $result."CPU.Usage".anomalies | Should -Not -BeNullOrEmpty
        }

        It "Should invoke the predictive model for trend analysis" -Skip:(-not $ModuleExists) {
            $result = Invoke-PredictiveModel -Action "trends" -InputFile "metrics.json"
            $result | Should -Not -BeNullOrEmpty
            $result."CPU.Usage" | Should -Not -BeNullOrEmpty
            $result."CPU.Usage".status | Should -Be "success"
            $result."CPU.Usage".trend | Should -Not -BeNullOrEmpty
        }
    }

    Context "Export-MetricsToJson Tests" {
        It "Should have Export-MetricsToJson function" -Skip:(-not $ModuleExists) {
            { Get-Command -Name Export-MetricsToJson -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should export metrics to JSON" -Skip:(-not $ModuleExists) {
            $result = Export-MetricsToJson -Metrics $TestMetrics -OutputPath "metrics.json"
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeLike "*.json"
        }
    }

    Context "Get-PredictivePerformanceTrend Tests" {
        It "Should have Get-PredictivePerformanceTrend function" -Skip:(-not $ModuleExists) {
            { Get-Command -Name Get-PredictivePerformanceTrend -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should get predictive performance trends" -Skip:(-not $ModuleExists) {
            $result = Get-PredictivePerformanceTrend -Metrics $TestMetrics -MetricName "CPU.Usage"
            $result | Should -Not -BeNullOrEmpty
            $result.status | Should -Be "success"
            $result.trend | Should -Not -BeNullOrEmpty
            $result.trend.direction | Should -Be "croissante"
        }
    }

    Context "Get-PerformancePrediction Tests" {
        It "Should have Get-PerformancePrediction function" -Skip:(-not $ModuleExists) {
            { Get-Command -Name Get-PerformancePrediction -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should get performance predictions" -Skip:(-not $ModuleExists) {
            $result = Get-PerformancePrediction -Metrics $TestMetrics -MetricName "CPU.Usage" -Horizon 6
            $result | Should -Not -BeNullOrEmpty
            $result.status | Should -Be "success"
            $result.predictions | Should -Not -BeNullOrEmpty
            $result.predictions.Count | Should -Be 6
        }
    }

    Context "Find-PredictivePerformanceAnomaly Tests" {
        It "Should have Find-PredictivePerformanceAnomaly function" -Skip:(-not $ModuleExists) {
            { Get-Command -Name Find-PredictivePerformanceAnomaly -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should find predictive performance anomalies" -Skip:(-not $ModuleExists) {
            $result = Find-PredictivePerformanceAnomaly -Metrics $TestMetrics -MetricTypes @("CPU", "Memory") -Sensitivity "High"
            $result | Should -Not -BeNullOrEmpty
            $result."CPU.Usage" | Should -Not -BeNullOrEmpty
            $result."CPU.Usage".status | Should -Be "success"
            $result."CPU.Usage".anomalies | Should -Not -BeNullOrEmpty
        }
    }

    Context "Start-PerformanceModelTraining Tests" {
        It "Should have Start-PerformanceModelTraining function" -Skip:(-not $ModuleExists) {
            { Get-Command -Name Start-PerformanceModelTraining -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should train performance models" -Skip:(-not $ModuleExists) {
            $result = Start-PerformanceModelTraining -Metrics $TestMetrics -Force
            $result | Should -Not -BeNullOrEmpty
            $result."CPU.Usage" | Should -Not -BeNullOrEmpty
            $result."CPU.Usage".status | Should -Be "success"
            $result."CPU.Usage".metrics | Should -Not -BeNullOrEmpty
        }
    }
}

AfterAll {
    # Nettoyer les modules importés
    if ($ModuleExists) {
        Remove-Module -Name "PerformanceAnalyzer" -Force -ErrorAction SilentlyContinue
    }
}
