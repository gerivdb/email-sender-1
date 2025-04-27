# Test-SqlServerPermissionGaps.ps1
# Tests unitaires pour l'algorithme de détection des permissions manquantes au niveau serveur

# Importer le module de test
$testModulePath = Join-Path -Path $PSScriptRoot -ChildPath "Test-Module.psm1"
Import-Module $testModulePath -Force

# Importer le module principal
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\RoadmapParser.psm1"
Import-Module $modulePath -Force

# Charger directement les fichiers nécessaires pour les tests
$missingPermissionModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Functions\Private\SqlPermissionModels\MissingPermissionModel.ps1"
. $missingPermissionModelPath

$permissionComparisonFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Functions\Private\SqlPermissionModels\PermissionComparisonFunctions.ps1"
. $permissionComparisonFunctionsPath

$sqlServerPermissionGapsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Functions\Private\SqlPermissionGap\Find-SqlServerPermissionGaps.ps1"
. $sqlServerPermissionGapsPath

Describe "SqlServerPermissionGaps" {
    Context "Get-SqlServerPermissionImpact" {
        It "Should return specific impact for known permissions" {
            $impact = Get-SqlServerPermissionImpact -PermissionName "CONNECT SQL" -LoginName "TestUser"
            $impact | Should -Match "TestUser"
            $impact | Should -Match "CONNECT SQL"
            $impact | Should -Match "ne peut pas se connecter"
        }
        
        It "Should return generic impact for unknown permissions" {
            $impact = Get-SqlServerPermissionImpact -PermissionName "UNKNOWN_PERMISSION" -LoginName "TestUser"
            $impact | Should -Match "TestUser"
            $impact | Should -Match "UNKNOWN_PERMISSION"
            $impact | Should -Match "ne dispose pas"
        }
    }
    
    Context "Get-SqlServerPermissionRecommendation" {
        It "Should return specific recommendation for known permissions" {
            $recommendation = Get-SqlServerPermissionRecommendation -PermissionName "CONNECT SQL" -LoginName "TestUser"
            $recommendation | Should -Match "TestUser"
            $recommendation | Should -Match "CONNECT SQL"
            $recommendation | Should -Match "Accorder la permission"
        }
        
        It "Should return generic recommendation for unknown permissions" {
            $recommendation = Get-SqlServerPermissionRecommendation -PermissionName "UNKNOWN_PERMISSION" -LoginName "TestUser"
            $recommendation | Should -Match "TestUser"
            $recommendation | Should -Match "UNKNOWN_PERMISSION"
            $recommendation | Should -Match "Accorder la permission"
        }
    }
    
    Context "Find-SqlServerPermissionGaps" {
        BeforeAll {
            # Créer un modèle de référence
            $referenceModel = [PSCustomObject]@{
                ModelName = "TestModel"
                ServerPermissions = @(
                    [PSCustomObject]@{
                        PermissionName = "CONNECT SQL"
                        LoginName = "AppUser"
                        PermissionState = "GRANT"
                    },
                    [PSCustomObject]@{
                        PermissionName = "VIEW SERVER STATE"
                        LoginName = "MonitorUser"
                        PermissionState = "GRANT"
                    },
                    [PSCustomObject]@{
                        PermissionName = "ALTER ANY LOGIN"
                        LoginName = "AdminUser"
                        PermissionState = "GRANT"
                    }
                )
            }
            
            # Créer les permissions actuelles (avec certaines permissions manquantes)
            $currentPermissions = @(
                [PSCustomObject]@{
                    PermissionName = "CONNECT SQL"
                    LoginName = "AppUser"
                    PermissionState = "GRANT"
                },
                [PSCustomObject]@{
                    PermissionName = "ALTER ANY LOGIN"
                    LoginName = "AdminUser"
                    PermissionState = "GRANT"
                }
                # VIEW SERVER STATE pour MonitorUser est manquant
            )
            
            # Mock de la fonction Get-SqlServerPermissions
            Mock Get-SqlServerPermissions {
                return $currentPermissions
            }
        }
        
        It "Should detect missing server permissions from provided permissions" {
            $result = Find-SqlServerPermissionGaps `
                -CurrentPermissions $currentPermissions `
                -ReferenceModel $referenceModel `
                -ServerInstance "TestServer"
            
            $result | Should -Not -BeNullOrEmpty
            $result.ServerPermissions.Count | Should -Be 1
            $result.ServerPermissions[0].PermissionName | Should -Be "VIEW SERVER STATE"
            $result.ServerPermissions[0].LoginName | Should -Be "MonitorUser"
        }
        
        It "Should detect missing server permissions from server instance" {
            $result = Find-SqlServerPermissionGaps `
                -ServerInstance "TestServer" `
                -ReferenceModel $referenceModel
            
            $result | Should -Not -BeNullOrEmpty
            $result.ServerPermissions.Count | Should -Be 1
            $result.ServerPermissions[0].PermissionName | Should -Be "VIEW SERVER STATE"
            $result.ServerPermissions[0].LoginName | Should -Be "MonitorUser"
        }
        
        It "Should include impact information when requested" {
            $result = Find-SqlServerPermissionGaps `
                -CurrentPermissions $currentPermissions `
                -ReferenceModel $referenceModel `
                -ServerInstance "TestServer" `
                -IncludeImpact
            
            $result | Should -Not -BeNullOrEmpty
            $result.ServerPermissions[0].Impact | Should -Not -BeNullOrEmpty
            $result.ServerPermissions[0].Impact | Should -Match "MonitorUser"
            $result.ServerPermissions[0].Impact | Should -Match "VIEW SERVER STATE"
        }
        
        It "Should include recommendations when requested" {
            $result = Find-SqlServerPermissionGaps `
                -CurrentPermissions $currentPermissions `
                -ReferenceModel $referenceModel `
                -ServerInstance "TestServer" `
                -IncludeRecommendations
            
            $result | Should -Not -BeNullOrEmpty
            $result.ServerPermissions[0].RecommendedAction | Should -Not -BeNullOrEmpty
            $result.ServerPermissions[0].RecommendedAction | Should -Match "MonitorUser"
            $result.ServerPermissions[0].RecommendedAction | Should -Match "VIEW SERVER STATE"
        }
        
        It "Should generate fix script when requested" {
            $result = Find-SqlServerPermissionGaps `
                -CurrentPermissions $currentPermissions `
                -ReferenceModel $referenceModel `
                -ServerInstance "TestServer" `
                -GenerateFixScript
            
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain "FixScript"
            $result.FixScript | Should -Match "GRANT VIEW SERVER STATE TO \[MonitorUser\]"
        }
        
        It "Should respect the ExcludeLogins parameter" {
            $result = Find-SqlServerPermissionGaps `
                -CurrentPermissions $currentPermissions `
                -ReferenceModel $referenceModel `
                -ServerInstance "TestServer" `
                -ExcludeLogins @("MonitorUser")
            
            $result | Should -Not -BeNullOrEmpty
            $result.ServerPermissions.Count | Should -Be 0
        }
        
        It "Should respect the IncludeLogins parameter" {
            $result = Find-SqlServerPermissionGaps `
                -CurrentPermissions $currentPermissions `
                -ReferenceModel $referenceModel `
                -ServerInstance "TestServer" `
                -IncludeLogins @("MonitorUser")
            
            $result | Should -Not -BeNullOrEmpty
            $result.ServerPermissions.Count | Should -Be 1
            $result.ServerPermissions[0].LoginName | Should -Be "MonitorUser"
        }
        
        It "Should respect the ExcludePermissions parameter" {
            $result = Find-SqlServerPermissionGaps `
                -CurrentPermissions $currentPermissions `
                -ReferenceModel $referenceModel `
                -ServerInstance "TestServer" `
                -ExcludePermissions @("VIEW SERVER STATE")
            
            $result | Should -Not -BeNullOrEmpty
            $result.ServerPermissions.Count | Should -Be 0
        }
        
        It "Should respect the IncludePermissions parameter" {
            $result = Find-SqlServerPermissionGaps `
                -CurrentPermissions $currentPermissions `
                -ReferenceModel $referenceModel `
                -ServerInstance "TestServer" `
                -IncludePermissions @("VIEW SERVER STATE")
            
            $result | Should -Not -BeNullOrEmpty
            $result.ServerPermissions.Count | Should -Be 1
            $result.ServerPermissions[0].PermissionName | Should -Be "VIEW SERVER STATE"
        }
        
        It "Should apply custom severity map" {
            $customSeverityMap = @{
                "VIEW SERVER STATE" = "Critique"
                "DEFAULT" = "Moyenne"
            }
            
            $result = Find-SqlServerPermissionGaps `
                -CurrentPermissions $currentPermissions `
                -ReferenceModel $referenceModel `
                -ServerInstance "TestServer" `
                -SeverityMap $customSeverityMap
            
            $result | Should -Not -BeNullOrEmpty
            $result.ServerPermissions[0].Severity | Should -Be "Critique"
        }
    }
    
    Context "New-SqlServerPermissionComplianceReport" {
        BeforeAll {
            # Créer un modèle de référence
            $referenceModel = [PSCustomObject]@{
                ModelName = "TestModel"
                ServerPermissions = @(
                    [PSCustomObject]@{
                        PermissionName = "CONNECT SQL"
                        LoginName = "AppUser"
                        PermissionState = "GRANT"
                    },
                    [PSCustomObject]@{
                        PermissionName = "VIEW SERVER STATE"
                        LoginName = "MonitorUser"
                        PermissionState = "GRANT"
                    },
                    [PSCustomObject]@{
                        PermissionName = "ALTER ANY LOGIN"
                        LoginName = "AdminUser"
                        PermissionState = "GRANT"
                    }
                )
            }
            
            # Créer les permissions actuelles (avec certaines permissions manquantes)
            $currentPermissions = @(
                [PSCustomObject]@{
                    PermissionName = "CONNECT SQL"
                    LoginName = "AppUser"
                    PermissionState = "GRANT"
                },
                [PSCustomObject]@{
                    PermissionName = "ALTER ANY LOGIN"
                    LoginName = "AdminUser"
                    PermissionState = "GRANT"
                }
                # VIEW SERVER STATE pour MonitorUser est manquant
            )
            
            # Créer un ensemble de permissions manquantes
            $missingPermissions = Find-SqlServerPermissionGaps `
                -CurrentPermissions $currentPermissions `
                -ReferenceModel $referenceModel `
                -ServerInstance "TestServer" `
                -IncludeImpact `
                -IncludeRecommendations
        }
        
        It "Should generate a text report" {
            $report = New-SqlServerPermissionComplianceReport `
                -MissingPermissions $missingPermissions `
                -ReferenceModel $referenceModel `
                -Format "Text"
            
            $report | Should -Not -BeNullOrEmpty
            $report | Should -Match "Rapport de conformité"
            $report | Should -Match "TestServer"
            $report | Should -Match "TestModel"
            $report | Should -Match "Score de conformité"
            $report | Should -Match "VIEW SERVER STATE"
            $report | Should -Match "MonitorUser"
        }
        
        It "Should generate an HTML report" {
            $report = New-SqlServerPermissionComplianceReport `
                -MissingPermissions $missingPermissions `
                -ReferenceModel $referenceModel `
                -Format "HTML"
            
            $report | Should -Not -BeNullOrEmpty
            $report | Should -Match "<html>"
            $report | Should -Match "<title>Rapport de conformité"
            $report | Should -Match "TestServer"
            $report | Should -Match "TestModel"
            $report | Should -Match "<td>VIEW SERVER STATE</td>"
            $report | Should -Match "<td>MonitorUser</td>"
        }
        
        It "Should generate a CSV report" {
            $report = New-SqlServerPermissionComplianceReport `
                -MissingPermissions $missingPermissions `
                -ReferenceModel $referenceModel `
                -Format "CSV"
            
            $report | Should -Not -BeNullOrEmpty
            $report | Should -Match "Instance,ModelName,ComparisonDate,ComplianceScore"
            $report | Should -Match "TestServer,TestModel"
            $report | Should -Match "PermissionName,LoginName,PermissionState,Severity"
            $report | Should -Match "VIEW SERVER STATE,MonitorUser,GRANT"
        }
        
        It "Should generate a JSON report" {
            $report = New-SqlServerPermissionComplianceReport `
                -MissingPermissions $missingPermissions `
                -ReferenceModel $referenceModel `
                -Format "JSON"
            
            $report | Should -Not -BeNullOrEmpty
            $reportObj = $report | ConvertFrom-Json
            $reportObj.Instance | Should -Be "TestServer"
            $reportObj.ModelName | Should -Be "TestModel"
            $reportObj.MissingPermissionDetails.Count | Should -Be 1
            $reportObj.MissingPermissionDetails[0].PermissionName | Should -Be "VIEW SERVER STATE"
            $reportObj.MissingPermissionDetails[0].LoginName | Should -Be "MonitorUser"
        }
        
        It "Should include fix script when requested" {
            $report = New-SqlServerPermissionComplianceReport `
                -MissingPermissions $missingPermissions `
                -ReferenceModel $referenceModel `
                -Format "Text" `
                -IncludeFixScript
            
            $report | Should -Not -BeNullOrEmpty
            $report | Should -Match "Script de correction"
            $report | Should -Match "GRANT VIEW SERVER STATE TO \[MonitorUser\]"
        }
        
        It "Should not include fix script when not requested" {
            $report = New-SqlServerPermissionComplianceReport `
                -MissingPermissions $missingPermissions `
                -ReferenceModel $referenceModel `
                -Format "Text" `
                -IncludeFixScript:$false
            
            $report | Should -Not -BeNullOrEmpty
            $report | Should -Not -Match "Script de correction"
            $report | Should -Not -Match "GRANT VIEW SERVER STATE TO \[MonitorUser\]"
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
