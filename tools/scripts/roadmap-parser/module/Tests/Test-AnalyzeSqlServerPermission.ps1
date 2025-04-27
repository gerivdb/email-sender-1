# Tests pour la fonction Analyze-SqlServerPermission
# Nécessite Pester v5 ou supérieur

BeforeAll {
    # Importer la fonction à tester
    . "$PSScriptRoot\..\Functions\Public\Analyze-SqlServerPermission.ps1"

    # Créer un dossier temporaire pour les rapports
    $script:TempFolder = Join-Path -Path $env:TEMP -ChildPath "SqlPermissionReports"
    New-Item -Path $script:TempFolder -ItemType Directory -Force | Out-Null
}

Describe "Analyze-SqlServerPermission" {
    BeforeAll {
        # Mock pour Invoke-Sqlcmd - Rôles serveur
        Mock -CommandName Invoke-Sqlcmd -ParameterFilter { $Query -like "*sys.server_role_members*" } -MockWith {
            return @(
                [PSCustomObject]@{
                    RoleName         = "sysadmin"
                    MemberName       = "sa"
                    MemberType       = "SQL_LOGIN"
                    MemberCreateDate = (Get-Date).AddYears(-1)
                    IsDisabled       = $false
                },
                [PSCustomObject]@{
                    RoleName         = "sysadmin"
                    MemberName       = "DOMAIN\Administrator"
                    MemberType       = "WINDOWS_LOGIN"
                    MemberCreateDate = (Get-Date).AddYears(-1)
                    IsDisabled       = $false
                },
                [PSCustomObject]@{
                    RoleName         = "securityadmin"
                    MemberName       = "SecurityUser"
                    MemberType       = "SQL_LOGIN"
                    MemberCreateDate = (Get-Date).AddMonths(-6)
                    IsDisabled       = $true
                }
            )
        }

        # Mock pour Invoke-Sqlcmd - Permissions serveur
        Mock -CommandName Invoke-Sqlcmd -ParameterFilter { $Query -like "*sys.server_permissions*" } -MockWith {
            return @(
                [PSCustomObject]@{
                    GranteeName     = "sa"
                    GranteeType     = "SQL_LOGIN"
                    SecurableName   = "SERVER"
                    SecurableType   = "SERVER"
                    PermissionName  = "CONTROL SERVER"
                    PermissionState = "GRANT"
                },
                [PSCustomObject]@{
                    GranteeName     = "DOMAIN\Administrator"
                    GranteeType     = "WINDOWS_LOGIN"
                    SecurableName   = "SERVER"
                    SecurableType   = "SERVER"
                    PermissionName  = "ALTER ANY LOGIN"
                    PermissionState = "GRANT"
                },
                [PSCustomObject]@{
                    GranteeName     = "SecurityUser"
                    GranteeType     = "SQL_LOGIN"
                    SecurableName   = "SERVER"
                    SecurableType   = "SERVER"
                    PermissionName  = "VIEW SERVER STATE"
                    PermissionState = "GRANT"
                }
            )
        }

        # Mock pour Invoke-Sqlcmd - Logins serveur
        Mock -CommandName Invoke-Sqlcmd -ParameterFilter { $Query -like "*sys.server_principals*" -and $Query -like "*LOGINPROPERTY*" } -MockWith {
            return @(
                [PSCustomObject]@{
                    LoginName           = "sa"
                    LoginType           = "SQL_LOGIN"
                    CreateDate          = (Get-Date).AddYears(-1)
                    ModifyDate          = (Get-Date).AddDays(-30)
                    IsDisabled          = $false
                    PasswordLastSetTime = (Get-Date).AddDays(-30)
                    DaysUntilExpiration = 60
                    IsExpired           = 0
                    IsMustChange        = 0
                    LockoutTime         = $null
                    BadPasswordCount    = 0
                    IsLocked            = 0
                },
                [PSCustomObject]@{
                    LoginName           = "DOMAIN\Administrator"
                    LoginType           = "WINDOWS_LOGIN"
                    CreateDate          = (Get-Date).AddYears(-1)
                    ModifyDate          = (Get-Date).AddDays(-30)
                    IsDisabled          = $false
                    PasswordLastSetTime = $null
                    DaysUntilExpiration = $null
                    IsExpired           = $null
                    IsMustChange        = $null
                    LockoutTime         = $null
                    BadPasswordCount    = $null
                    IsLocked            = $null
                },
                [PSCustomObject]@{
                    LoginName           = "SecurityUser"
                    LoginType           = "SQL_LOGIN"
                    CreateDate          = (Get-Date).AddMonths(-6)
                    ModifyDate          = (Get-Date).AddDays(-90)
                    IsDisabled          = $true
                    PasswordLastSetTime = (Get-Date).AddDays(-90)
                    DaysUntilExpiration = -30
                    IsExpired           = 1
                    IsMustChange        = 0
                    LockoutTime         = $null
                    BadPasswordCount    = 0
                    IsLocked            = 0
                },
                [PSCustomObject]@{
                    LoginName           = "LockedUser"
                    LoginType           = "SQL_LOGIN"
                    CreateDate          = (Get-Date).AddMonths(-3)
                    ModifyDate          = (Get-Date).AddDays(-10)
                    IsDisabled          = $false
                    PasswordLastSetTime = (Get-Date).AddDays(-10)
                    DaysUntilExpiration = 80
                    IsExpired           = 0
                    IsMustChange        = 0
                    LockoutTime         = (Get-Date).AddHours(-1)
                    BadPasswordCount    = 3
                    IsLocked            = 1
                }
            )
        }

        # Mock pour Get-Module
        Mock -CommandName Get-Module -ParameterFilter { $Name -eq "SqlServer" -and $ListAvailable } -MockWith {
            return $true
        }

        # Mock pour Import-Module
        Mock -CommandName Import-Module -MockWith { return $true }
    }

    Context "Paramètres et validation" {
        It "Devrait accepter un paramètre ServerInstance obligatoire" {
            (Get-Command Analyze-SqlServerPermission).Parameters['ServerInstance'].Attributes |
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                Select-Object -ExpandProperty Mandatory |
                Should -Be $true
        }

        It "Devrait accepter un paramètre Credential optionnel" {
            (Get-Command Analyze-SqlServerPermission).Parameters['Credential'].Attributes |
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                Select-Object -ExpandProperty Mandatory |
                Should -Be $false
        }

        It "Devrait accepter un paramètre OutputPath optionnel" {
            (Get-Command Analyze-SqlServerPermission).Parameters['OutputPath'].Attributes |
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                Select-Object -ExpandProperty Mandatory |
                Should -Be $false
        }

        It "Devrait accepter un paramètre OutputFormat optionnel avec des valeurs valides" {
            $param = (Get-Command Analyze-SqlServerPermission).Parameters['OutputFormat']
            $param.Attributes |
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                Select-Object -ExpandProperty Mandatory |
                Should -Be $false

            $param.Attributes |
                Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] } |
                Select-Object -ExpandProperty ValidValues |
                Should -Contain "HTML"

            $param.Attributes |
                Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] } |
                Select-Object -ExpandProperty ValidValues |
                Should -Contain "CSV"

            $param.Attributes |
                Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] } |
                Select-Object -ExpandProperty ValidValues |
                Should -Contain "JSON"

            $param.Attributes |
                Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] } |
                Select-Object -ExpandProperty ValidValues |
                Should -Contain "XML"
        }
    }

    Context "Fonctionnalités de base" {
        It "Devrait retourner un objet avec les propriétés attendues" {
            $result = Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS"

            $result | Should -Not -BeNullOrEmpty
            $result.ServerInstance | Should -Be "localhost\SQLEXPRESS"
            $result.ServerRoles | Should -Not -BeNullOrEmpty
            $result.ServerPermissions | Should -Not -BeNullOrEmpty
            $result.ServerLogins | Should -Not -BeNullOrEmpty
            $result.PermissionAnomalies | Should -Not -BeNullOrEmpty
            $result.AnalysisDate | Should -BeOfType [DateTime]
        }

        It "Devrait détecter les anomalies de permissions" {
            $result = Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS"

            # Vérifier que les anomalies sont détectées
            $result.PermissionAnomalies | Should -Not -BeNullOrEmpty

            # Vérifier la détection des comptes désactivés avec des permissions
            $result.PermissionAnomalies | Where-Object { $_.AnomalyType -eq "DisabledLoginWithPermissions" -and $_.LoginName -eq "SecurityUser" } | Should -Not -BeNullOrEmpty

            # Vérifier la détection des comptes avec des privilèges élevés
            $result.PermissionAnomalies | Where-Object { $_.AnomalyType -eq "HighPrivilegeAccount" -and $_.LoginName -eq "sa" } | Should -Not -BeNullOrEmpty
            $result.PermissionAnomalies | Where-Object { $_.AnomalyType -eq "HighPrivilegeAccount" -and $_.LoginName -eq "DOMAIN\Administrator" } | Should -Not -BeNullOrEmpty

            # Vérifier la détection des comptes avec des mots de passe expirés
            $result.PermissionAnomalies | Where-Object { $_.AnomalyType -eq "ExpiredPassword" -and $_.LoginName -eq "SecurityUser" } | Should -Not -BeNullOrEmpty

            # Vérifier la détection des comptes verrouillés
            $result.PermissionAnomalies | Where-Object { $_.AnomalyType -eq "LockedAccount" -and $_.LoginName -eq "LockedUser" } | Should -Not -BeNullOrEmpty

            # Vérifier la détection des permissions CONTROL SERVER
            $result.PermissionAnomalies | Where-Object { $_.AnomalyType -eq "ControlServerPermission" -and $_.LoginName -eq "sa" } | Should -Not -BeNullOrEmpty
        }
    }

    Context "Génération de rapports" {
        It "Devrait générer un rapport HTML" {
            $outputPath = Join-Path -Path $script:TempFolder -ChildPath "SqlPermissions.html"

            Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -OutputPath $outputPath -OutputFormat "HTML"

            Test-Path -Path $outputPath | Should -Be $true
            Get-Content -Path $outputPath -Raw | Should -Match "<html>"
            Get-Content -Path $outputPath -Raw | Should -Match "Rapport de permissions SQL Server"
        }

        It "Devrait générer des rapports CSV" {
            $outputPath = Join-Path -Path $script:TempFolder -ChildPath "SqlPermissions.csv"

            Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -OutputPath $outputPath -OutputFormat "CSV"

            $anomaliesPath = Join-Path -Path $script:TempFolder -ChildPath "SqlPermissions.anomalies.csv"
            $rolesPath = Join-Path -Path $script:TempFolder -ChildPath "SqlPermissions.server_roles.csv"
            $permissionsPath = Join-Path -Path $script:TempFolder -ChildPath "SqlPermissions.server_permissions.csv"
            $loginsPath = Join-Path -Path $script:TempFolder -ChildPath "SqlPermissions.server_logins.csv"

            Test-Path -Path $anomaliesPath | Should -Be $true
            Test-Path -Path $rolesPath | Should -Be $true
            Test-Path -Path $permissionsPath | Should -Be $true
            Test-Path -Path $loginsPath | Should -Be $true
        }

        It "Devrait générer un rapport JSON" {
            $outputPath = Join-Path -Path $script:TempFolder -ChildPath "SqlPermissions.json"

            Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -OutputPath $outputPath -OutputFormat "JSON"

            Test-Path -Path $outputPath | Should -Be $true
            Get-Content -Path $outputPath -Raw | Should -Match "ServerInstance"
            Get-Content -Path $outputPath -Raw | Should -Match "ServerRoles"
            Get-Content -Path $outputPath -Raw | Should -Match "ServerPermissions"
        }

        It "Devrait générer un rapport XML" {
            $outputPath = Join-Path -Path $script:TempFolder -ChildPath "SqlPermissions.xml"

            Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -OutputPath $outputPath -OutputFormat "XML"

            Test-Path -Path $outputPath | Should -Be $true
        }
    }

    Context "Gestion des erreurs" {
        BeforeAll {
            # Mock pour simuler une erreur de connexion
            Mock -CommandName Invoke-Sqlcmd -ParameterFilter { $ServerInstance -eq "invalid-server" } -MockWith {
                throw "A network-related or instance-specific error occurred while establishing a connection to SQL Server."
            }
        }

        It "Devrait gérer les erreurs de connexion" {
            { Analyze-SqlServerPermission -ServerInstance "invalid-server" -ErrorAction Stop } | Should -Throw
        }
    }
}

AfterAll {
    # Nettoyer les fichiers temporaires
    if ($script:TempFolder -and (Test-Path -Path $script:TempFolder)) {
        Remove-Item -Path $script:TempFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
}
