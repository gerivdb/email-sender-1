<#
.SYNOPSIS
    Tests unitaires pour les exemples de dÃ©bogage des scÃ©narios courants d'accÃ¨s refusÃ©.
.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples de dÃ©bogage
    des scÃ©narios courants d'accÃ¨s refusÃ©.
.NOTES
    Auteur: Augment Code
    Date de crÃ©ation: 2023-11-15
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Certains tests pourraient ne pas fonctionner correctement."
}

# Importer le script Ã  tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\AccessExamples.ps1"
. $scriptPath

Describe "Debug-SystemFileAccess" {
    BeforeAll {
        # CrÃ©er un fichier temporaire pour simuler un fichier systÃ¨me protÃ©gÃ©
        $tempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString())
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        $protectedFile = Join-Path -Path $tempDir -ChildPath "protected.dat"
        Set-Content -Path $protectedFile -Value "Protected content"

        # Simuler un fichier protÃ©gÃ© en retirant les permissions
        $acl = Get-Acl -Path $protectedFile
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $currentUser,
            [System.Security.AccessControl.FileSystemRights]::Read,
            [System.Security.AccessControl.AccessControlType]::Deny
        )
        $acl.AddAccessRule($accessRule)
        Set-Acl -Path $protectedFile -AclObject $acl
    }

    AfterAll {
        # Nettoyer les fichiers temporaires
        $tempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString())
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Devrait dÃ©tecter un fichier inexistant" {
        $result = Debug-SystemFileAccess -FilePath "C:\CheMin_Qui_Nexiste_Pas_12345"
        $result.FileExists | Should -Be $false
        $result.Recommendations | Should -Contain "VÃ©rifiez que le chemin du fichier est correct."
    }

    It "Devrait analyser les permissions d'un fichier existant" {
        # Mock pour Ã©viter de rÃ©ellement tester les privilÃ¨ges systÃ¨me
        Mock -CommandName Test-PathPermissions -MockWith {
            return [PSCustomObject]@{
                Path = $Path
                Exists = $true
                IsContainer = $false
                IsReadOnly = $false
                IsHidden = $false
                IsSystem = $false
                Owner = "NT AUTHORITY\SYSTEM"
                CurrentUserAccess = @()
                ReadAccess = $false
                WriteAccess = $false
                ExecuteAccess = $false
                AllAccess = $false
                AccessControlEntries = @()
                Error = $null
                TestResults = @{}
            }
        }

        Mock -CommandName Format-PathPermissionsReport -MockWith {}

        Mock -CommandName Debug-UnauthorizedAccessException -MockWith {
            return [PSCustomObject]@{
                Success = $false
                Result = $null
                Error = [System.UnauthorizedAccessException]::new("Access denied")
                AccessDetails = [PSCustomObject]@{
                    IsUnauthorizedAccess = $true
                    Message = "Access denied"
                    Path = $Path
                    ProbableCause = "Permissions insuffisantes"
                    PossibleSolutions = @("Solution 1", "Solution 2")
                }
                PermissionsAnalysis = $null
            }
        }

        Mock -CommandName Format-UnauthorizedAccessReport -MockWith {}

        Mock -CommandName Enable-Privilege -MockWith { return $true }

        Mock -CommandName Copy-Item -MockWith {}

        Mock -CommandName Set-Acl -MockWith {}

        Mock -CommandName Edit-ProtectedFile -MockWith {
            return [PSCustomObject]@{
                Success = $true
                Message = "Le fichier a Ã©tÃ© modifiÃ© avec succÃ¨s."
                OriginalPath = $Path
                TempPath = "C:\Temp\file.tmp"
            }
        }

        $result = Debug-SystemFileAccess -FilePath "C:\Windows\System32\config\SAM"
        $result.FileExists | Should -Be $true
        $result.Recommendations.Count | Should -BeGreaterThan 0
    }
}

Describe "Debug-RegistryKeyAccess" {
    It "Devrait dÃ©tecter une clÃ© de registre inexistante" {
        $result = Debug-RegistryKeyAccess -RegistryPath "HKLM:\CleDeRegistre_Qui_Nexiste_Pas_12345"
        $result.KeyExists | Should -Be $false
        $result.Recommendations | Should -Contain "VÃ©rifiez que le chemin de la clÃ© de registre est correct."
    }

    It "Devrait analyser l'accÃ¨s Ã  une clÃ© de registre existante" {
        # Mock pour Ã©viter de rÃ©ellement tester les privilÃ¨ges systÃ¨me
        Mock -CommandName Debug-UnauthorizedAccessException -MockWith {
            return [PSCustomObject]@{
                Success = $false
                Result = $null
                Error = [System.UnauthorizedAccessException]::new("Access denied")
                AccessDetails = [PSCustomObject]@{
                    IsUnauthorizedAccess = $true
                    Message = "Access denied"
                    Path = $Path
                    ProbableCause = "Permissions insuffisantes"
                    PossibleSolutions = @("Solution 1", "Solution 2")
                }
                PermissionsAnalysis = $null
            }
        }

        Mock -CommandName Format-UnauthorizedAccessReport -MockWith {}

        Mock -CommandName Enable-Privilege -MockWith { return $true }

        Mock -CommandName Start-ElevatedProcess -MockWith { return 0 }

        # Mock pour simuler l'existence de la clÃ© de registre
        Mock -CommandName Test-Path -MockWith { return $true }

        $result = Debug-RegistryKeyAccess -RegistryPath "HKLM:\SECURITY\Policy"
        $result.KeyExists | Should -Be $true
        $result.Recommendations.Count | Should -BeGreaterThan 0
    }
}

Describe "Debug-NetworkAccess" {
    It "Devrait dÃ©tecter un chemin rÃ©seau invalide" {
        $result = Debug-NetworkAccess -NetworkPath "chemin_invalide"
        $result.Recommendations | Should -Contain "Utilisez un chemin UNC valide au format \\server\share\..."
    }

    It "Devrait analyser un chemin rÃ©seau valide" {
        # Mock pour Ã©viter de rÃ©ellement tester les connexions rÃ©seau
        Mock -CommandName Test-Connection -MockWith { return $true }

        Mock -CommandName Test-Path -MockWith { return $true }

        Mock -CommandName Debug-UnauthorizedAccessException -MockWith {
            return [PSCustomObject]@{
                Success = $true
                Result = "Contenu du fichier"
                Error = $null
                AccessDetails = $null
                PermissionsAnalysis = $null
            }
        }

        # Mock pour simuler une connexion TCP rÃ©ussie
        Mock -CommandName New-Object -ParameterFilter { $TypeName -eq "System.Net.Sockets.TcpClient" } -MockWith {
            return [PSCustomObject]@{
                BeginConnect = { return [PSCustomObject]@{
                    AsyncWaitHandle = [PSCustomObject]@{
                        WaitOne = { return $true }
                    }
                }}
                EndConnect = {}
                Close = {}
            }
        }

        # Mock pour simuler les commandes net
        Mock -CommandName net -MockWith { return "Mocked net command output" }

        $result = Debug-NetworkAccess -NetworkPath "\\server\share\file.txt"
        $result.Server | Should -Be "server"
        $result.Share | Should -Be "share"
        $result.PathExists | Should -Be $true
        $result.DirectAccessResult | Should -Be "SuccÃ¨s"
    }
}

Describe "Debug-DatabaseAccess" {
    It "Devrait vÃ©rifier les paramÃ¨tres obligatoires" {
        { Debug-DatabaseAccess } | Should -Throw
        { Debug-DatabaseAccess -ServerInstance "localhost" } | Should -Throw
    }

    It "Devrait analyser une connexion Ã  une base de donnÃ©es" {
        # Mock pour Ã©viter de rÃ©ellement tester les connexions SQL
        Mock -CommandName Test-Connection -MockWith { return $true }

        # Mock pour simuler une connexion TCP rÃ©ussie
        Mock -CommandName New-Object -ParameterFilter { $TypeName -eq "System.Net.Sockets.TcpClient" } -MockWith {
            return [PSCustomObject]@{
                BeginConnect = { return [PSCustomObject]@{
                    AsyncWaitHandle = [PSCustomObject]@{
                        WaitOne = { return $true }
                    }
                }}
                EndConnect = {}
                Close = {}
            }
        }

        # Mock pour simuler une connexion SQL rÃ©ussie
        Mock -CommandName New-Object -ParameterFilter { $TypeName -eq "System.Data.SqlClient.SqlConnection" } -MockWith {
            return [PSCustomObject]@{
                Open = {}
                Close = {}
            }
        }

        # Mock pour simuler une commande SQL
        Mock -CommandName New-Object -ParameterFilter { $TypeName -eq "System.Data.SqlClient.SqlCommand" } -MockWith {
            return [PSCustomObject]@{
                ExecuteReader = {
                    return [PSCustomObject]@{
                        Read = { return $true }
                        Close = {}
                        Item = @{
                            "name" = "TestDB"
                            "principal_name" = "dbo"
                            "principal_type" = "SQL_USER"
                            "object_name" = "TestTable"
                            "object_type" = "USER_TABLE"
                            "permission_name" = "SELECT"
                            "permission_state" = "GRANT"
                            "DatabaseName" = "TestDB"
                            "CurrentUser" = "dbo"
                        }
                    }
                }
            }
        }

        # Mock pour simuler l'installation du module SqlServer
        Mock -CommandName Get-Module -MockWith { return $true }

        # Mock pour simuler un processus Ã©levÃ©
        Mock -CommandName Start-ElevatedProcess -MockWith { return 0 }

        $result = Debug-DatabaseAccess -ServerInstance "localhost\SQLEXPRESS" -Database "TestDB" -IntegratedSecurity
        $result.ServerInstance | Should -Be "localhost\SQLEXPRESS"
        $result.Database | Should -Be "TestDB"
        $result.ConnectionDiagnostics["PingResult"] | Should -Be $true
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $PSCommandPath -Verbose
