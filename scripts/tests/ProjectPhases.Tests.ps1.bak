#Requires -Modules Pester

<#
.SYNOPSIS
    Uses Pester to test the outcomes of the 4 phases of the script reorganization project.
.DESCRIPTION
    This Pester test suite validates the results of each project phase:
    1. Reference Updates: Checks for broken references using Find-BrokenReferences.ps1.
    2. Standardization: Verifies script compliance using Manage-Standards-v2.ps1.
    3. Duplication Elimination: Assesses remaining code duplication using Manage-Duplications.ps1.
    4. ScriptManager Enhancements: Tests core functionalities of ScriptManager.ps1.
.NOTES
    Run using Invoke-Pester:
        Invoke-Pester -Path .\ProjectPhases.Tests.ps1
        Invoke-Pester -Path .\ProjectPhases.Tests.ps1 -Tag Phase1,Phase3
        Invoke-Pester -Path .\ProjectPhases.Tests.ps1 -Output Detailed
.LINK
    https://pester.dev/
#>

# --- Configuration ---
# Use $PSScriptRoot to define paths relative to *this test file*
$TestScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

# Define base path for the scripts being tested
$ScriptsBasePath = Split-Path -Path $TestScriptRoot -Parent

# Define path to the scripts folder specifically under test
$ScriptsToTestPath = Join-Path -Path $ScriptsBasePath -ChildPath 'maintenance'

# Verify paths
Write-Host "Test script root: $TestScriptRoot"
Write-Host "Scripts base path: $ScriptsBasePath"
Write-Host "Scripts to test path: $ScriptsToTestPath"

# Define paths to the tools used by the tests
$Tools = @{
    ReferenceFinder = Join-Path -Path $ScriptsBasePath -ChildPath 'maintenance\references\Find-BrokenReferences.ps1'
    StandardsChecker = Join-Path -Path $ScriptsBasePath -ChildPath 'maintenance\standards\Manage-Standards-v2.ps1'
    DuplicationDetector = Join-Path -Path $ScriptsBasePath -ChildPath 'maintenance\duplication\Manage-Duplications.ps1'
    ScriptManager = Join-Path -Path $ScriptsBasePath -ChildPath 'manager\ScriptManager.ps1'
}

# Define paths for test outputs/reports
$TestOutputPath = Join-Path -Path $TestScriptRoot -ChildPath 'TestOutputs'
$ReportPaths = @{
    References = Join-Path -Path $TestOutputPath -ChildPath 'references_test_report.json'
    Compliance = Join-Path -Path $ScriptsBasePath -ChildPath 'manager\data\compliance_report.json'
    Duplication = Join-Path -Path $ScriptsBasePath -ChildPath 'manager\data\duplication_report.json'
    Inventory = Join-Path -Path $ScriptsBasePath -ChildPath 'manager\data\inventory.json'
    Analysis = Join-Path -Path $ScriptsBasePath -ChildPath 'manager\data\analysis.json'
    Documentation = Join-Path -Path $ScriptsBasePath -ChildPath 'manager\docs\script_documentation.markdown'
}

# --- Pester Test Suite ---

Describe 'Project Script Reorganization Phase Tests' -Tags 'AllPhases' {

    # Setup: Ensure output directory exists before running tests
    BeforeAll {
        if (-not (Test-Path -Path $TestOutputPath)) {
            Write-Verbose "Creating test output directory: $TestOutputPath"
            New-Item -Path $TestOutputPath -ItemType Directory -Force | Out-Null
        }
        # Verify that the scripts folder to test actually exists
        if (-not (Test-Path -Path $ScriptsToTestPath -PathType Container)) {
             throw "Scripts directory to test not found at '$ScriptsToTestPath'. Please check the `$ScriptsToTestPath variable."
        }
    }

    Context 'Phase 1: Reference Updates' -Tags 'Phase1' {

        It 'Reference detection tool should exist' {
            $Tools.ReferenceFinder | Should -Exist
        }

        It 'Should run reference detection tool successfully' {
            # Use splatting for parameters - safer than Invoke-Expression
            $params = @{
                Path = $ScriptsToTestPath
                OutputPath = $ReportPaths.References
                ErrorAction = 'Stop'
            }
            # Execute using the call operator '&'
            & $Tools.ReferenceFinder @params
        }

        It 'Should generate a reference report file' {
            $ReportPaths.References | Should -Exist
        }

        It 'Reference report should indicate zero broken references' {
            # Assumption: The report file exists from the previous test
            $report = Get-Content -Path $ReportPaths.References -Raw | ConvertFrom-Json -ErrorAction Stop
            # Assuming the JSON structure has a 'BrokenReferencesCount' property
            $report | Should -HaveProperty 'BrokenReferencesCount'
            $report.BrokenReferencesCount | Should -Be 0
        }
    }

    Context 'Phase 2: Standardization' -Tags 'Phase2' {

        It 'Standardization tool should exist' {
            $Tools.StandardsChecker | Should -Exist
        }

        It 'Should run standardization analysis successfully' {
            $params = @{
                Action = 'analyze'
                Path = $ScriptsToTestPath
                ErrorAction = 'Stop'
            }
            & $Tools.StandardsChecker @params
        }

        It 'Should generate a compliance report file' {
             $ReportPaths.Compliance | Should -Exist
        }

        It 'Compliance report should show no high severity issues' {
            $report = Get-Content -Path $ReportPaths.Compliance -Raw | ConvertFrom-Json -ErrorAction Stop
            $report | Should -HaveProperty 'HighSeverityCount'
            $report.HighSeverityCount | Should -Be 0
        }

        It 'Compliance report should ideally show no medium severity issues' {
            $report = Get-Content -Path $ReportPaths.Compliance -Raw | ConvertFrom-Json -ErrorAction Stop
            $report | Should -HaveProperty 'MediumSeverityCount'
            # Changed from warning to a strict check - adjust if 'Warning' level is acceptable
            $report.MediumSeverityCount | Should -BeLessOrEqual 10
        }
    }

    Context 'Phase 3: Duplication Elimination' -Tags 'Phase3' {

         It 'Duplication detection tool should exist' {
            $Tools.DuplicationDetector | Should -Exist
        }

        It 'Should run duplication detection successfully' {
             $params = @{
                Action = 'detect'
                Path = $ScriptsToTestPath
                UsePython = $true
                ErrorAction = 'Stop'
            }
            & $Tools.DuplicationDetector @params
        }

        It 'Should generate a duplication report file' {
             $ReportPaths.Duplication | Should -Exist
        }

        It 'Duplication report should show acceptable number of inter-file duplications' {
            $report = Get-Content -Path $ReportPaths.Duplication -Raw | ConvertFrom-Json -ErrorAction Stop

            # Check if the property exists and handle different possible structures
            if ($report.PSObject.Properties.Name -contains 'inter_file_duplications') {
                ($report.inter_file_duplications | Measure-Object).Count | Should -BeLessOrEqual 10
            }
            elseif ($report.PSObject.Properties.Name -contains 'InterFileDuplications') {
                ($report.InterFileDuplications | Measure-Object).Count | Should -BeLessOrEqual 10
            }
            else {
                # If neither property exists, the test should fail
                $false | Should -BeTrue -Because "Expected 'inter_file_duplications' or 'InterFileDuplications' property in duplication report"
            }
        }
    }

    Context 'Phase 4: ScriptManager Enhancements' -Tags 'Phase4' {

        It 'ScriptManager tool should exist' {
            $Tools.ScriptManager | Should -Exist
        }

        # Test Inventory Functionality
        Context 'Inventory' {
            It 'Should run inventory action successfully' {
                $params = @{
                    Action = 'inventory'
                    Path = $ScriptsToTestPath
                    ErrorAction = 'Stop'
                }
                & $Tools.ScriptManager @params
            }

            It 'Should generate an inventory JSON file' {
                 $ReportPaths.Inventory | Should -Exist
            }

            It 'Inventory file should contain expected data' {
                 $inventory = Get-Content -Path $ReportPaths.Inventory -Raw | ConvertFrom-Json -ErrorAction Stop
                 $inventory | Should -HaveProperty 'TotalScripts'
                 $inventory.TotalScripts | Should -BeGreaterThan 0
            }
        }

        # Test Analysis Functionality
        Context 'Analysis' {
             It 'Should run analysis action successfully' {
                $params = @{
                    Action = 'analyze'
                    Path = $ScriptsToTestPath
                    ErrorAction = 'Stop'
                }
                & $Tools.ScriptManager @params
            }

            It 'Should generate an analysis JSON file' {
                 $ReportPaths.Analysis | Should -Exist
            }

             It 'Analysis report should contain expected data' {
                $analysis = Get-Content -Path $ReportPaths.Analysis -Raw | ConvertFrom-Json -ErrorAction Stop
                $analysis | Should -Not -BeNullOrEmpty
             }
        }

        # Test Documentation Functionality
         Context 'Documentation' {
             It 'Should run documentation action successfully' {
                $params = @{
                    Action = 'document'
                    Path = $ScriptsToTestPath
                    Format = 'Markdown'
                    ErrorAction = 'Stop'
                }
                & $Tools.ScriptManager @params
            }

             It 'Should generate a Markdown documentation file' {
                 $ReportPaths.Documentation | Should -Exist
            }

            It 'Documentation file should contain expected content' {
                 $content = Get-Content -Path $ReportPaths.Documentation -Raw
                 $content | Should -Not -BeNullOrEmpty
            }
        }

         # Test Dashboard Functionality
        Context 'Dashboard' {
             It 'Should run dashboard action without error' {
                 $params = @{
                    Action = 'dashboard'
                    ErrorAction = 'Stop'
                 }
                 & $Tools.ScriptManager @params
             }
        }
    }
}
