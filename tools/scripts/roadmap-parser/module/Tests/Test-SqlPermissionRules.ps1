# Test-SqlPermissionRules.ps1
# Tests unitaires pour les rÃ¨gles de dÃ©tection d'anomalies SQL Server

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
Import-Module $modulePath -Force

Describe "Tests des rÃ¨gles de dÃ©tection d'anomalies SQL Server" {
    Context "Fonction Get-SqlPermissionRules" {
        It "Devrait retourner des rÃ¨gles de niveau serveur" {
            $rules = Get-SqlPermissionRules -RuleType "Server"
            $rules | Should -Not -BeNullOrEmpty
            $rules.Count | Should -BeGreaterThan 0
            $rules | ForEach-Object { $_.RuleType | Should -Be "Server" }
        }

        It "Devrait retourner des rÃ¨gles de niveau base de donnÃ©es" {
            $rules = Get-SqlPermissionRules -RuleType "Database"
            $rules | Should -Not -BeNullOrEmpty
            $rules.Count | Should -BeGreaterThan 0
            $rules | ForEach-Object { $_.RuleType | Should -Be "Database" }
        }

        It "Devrait retourner des rÃ¨gles de niveau objet" {
            $rules = Get-SqlPermissionRules -RuleType "Object"
            $rules | Should -Not -BeNullOrEmpty
            $rules.Count | Should -BeGreaterThan 0
            $rules | ForEach-Object { $_.RuleType | Should -Be "Object" }
        }

        It "Devrait filtrer les rÃ¨gles par sÃ©vÃ©ritÃ©" {
            $allRules = Get-SqlPermissionRules -RuleType "Server" -Severity "All"
            $highRules = Get-SqlPermissionRules -RuleType "Server" -Severity "Ã‰levÃ©e"
            $mediumRules = Get-SqlPermissionRules -RuleType "Server" -Severity "Moyenne"
            
            $highRules.Count | Should -BeLessThan $allRules.Count
            $highRules | ForEach-Object { $_.Severity | Should -Be "Ã‰levÃ©e" }
            $mediumRules | ForEach-Object { $_.Severity | Should -Be "Moyenne" }
        }
    }

    Context "Fonctions de dÃ©tection d'anomalies" {
        # DonnÃ©es de test pour les logins serveur
        $mockServerLogins = @(
            [PSCustomObject]@{
                LoginName = "disabled_login"
                IsDisabled = $true
                LoginType = "SQL_LOGIN"
                IsPolicyChecked = 1
                IsExpirationChecked = 1
                IsLocked = 0
                IsExpired = 0
            },
            [PSCustomObject]@{
                LoginName = "active_login"
                IsDisabled = $false
                LoginType = "SQL_LOGIN"
                IsPolicyChecked = 0
                IsExpirationChecked = 0
                IsLocked = 0
                IsExpired = 0
            },
            [PSCustomObject]@{
                LoginName = "locked_login"
                IsDisabled = $false
                LoginType = "SQL_LOGIN"
                IsPolicyChecked = 1
                IsExpirationChecked = 1
                IsLocked = 1
                IsExpired = 0
            },
            [PSCustomObject]@{
                LoginName = "expired_login"
                IsDisabled = $false
                LoginType = "SQL_LOGIN"
                IsPolicyChecked = 1
                IsExpirationChecked = 1
                IsLocked = 0
                IsExpired = 1
            }
        )

        # DonnÃ©es de test pour les rÃ´les serveur
        $mockServerRoles = @(
            [PSCustomObject]@{
                RoleName = "sysadmin"
                Members = @(
                    [PSCustomObject]@{ MemberName = "active_login" },
                    [PSCustomObject]@{ MemberName = "##MS_SQLResourceSigningCertificate##" }
                )
            },
            [PSCustomObject]@{
                RoleName = "securityadmin"
                Members = @(
                    [PSCustomObject]@{ MemberName = "disabled_login" }
                )
            }
        )

        # DonnÃ©es de test pour les permissions serveur
        $mockServerPermissions = @(
            [PSCustomObject]@{
                GranteeName = "active_login"
                Permissions = @(
                    [PSCustomObject]@{
                        PermissionName = "CONTROL SERVER"
                        PermissionState = "GRANT"
                    }
                )
            },
            [PSCustomObject]@{
                GranteeName = "disabled_login"
                Permissions = @(
                    [PSCustomObject]@{
                        PermissionName = "VIEW SERVER STATE"
                        PermissionState = "GRANT"
                    }
                )
            }
        )

        It "Find-PermissionAnomalies devrait dÃ©tecter les anomalies au niveau serveur" {
            $anomalies = Find-PermissionAnomalies -ServerRoles $mockServerRoles -ServerPermissions $mockServerPermissions -ServerLogins $mockServerLogins
            
            $anomalies | Should -Not -BeNullOrEmpty
            $anomalies.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier que les logins dÃ©sactivÃ©s avec des permissions sont dÃ©tectÃ©s
            $disabledLoginAnomalies = $anomalies | Where-Object { $_.LoginName -eq "disabled_login" }
            $disabledLoginAnomalies | Should -Not -BeNullOrEmpty
            
            # VÃ©rifier que les comptes avec des permissions Ã©levÃ©es sont dÃ©tectÃ©s
            $highPrivilegeAnomalies = $anomalies | Where-Object { $_.LoginName -eq "active_login" -and $_.AnomalyType -eq "HighPrivilegeAccount" }
            $highPrivilegeAnomalies | Should -Not -BeNullOrEmpty
            
            # VÃ©rifier que les comptes avec CONTROL SERVER sont dÃ©tectÃ©s
            $controlServerAnomalies = $anomalies | Where-Object { $_.LoginName -eq "active_login" -and $_.AnomalyType -eq "ControlServerPermission" }
            $controlServerAnomalies | Should -Not -BeNullOrEmpty
        }

        # DonnÃ©es de test pour les utilisateurs de base de donnÃ©es
        $mockDatabaseUsers = @(
            [PSCustomObject]@{
                DatabaseName = "TestDB"
                UserName = "orphaned_user"
                LoginName = $null
                IsDisabled = $false
                UserType = "SQL_USER"
            },
            [PSCustomObject]@{
                DatabaseName = "TestDB"
                UserName = "disabled_user"
                LoginName = "disabled_login"
                IsDisabled = $true
                UserType = "SQL_USER"
            },
            [PSCustomObject]@{
                DatabaseName = "TestDB"
                UserName = "normal_user"
                LoginName = "active_login"
                IsDisabled = $false
                UserType = "SQL_USER"
            }
        )

        # DonnÃ©es de test pour les rÃ´les de base de donnÃ©es
        $mockDatabaseRoles = @(
            [PSCustomObject]@{
                DatabaseName = "TestDB"
                RoleName = "db_owner"
                Members = @(
                    [PSCustomObject]@{ MemberName = "normal_user" }
                )
            },
            [PSCustomObject]@{
                DatabaseName = "TestDB"
                RoleName = "db_datareader"
                Members = @(
                    [PSCustomObject]@{ MemberName = "disabled_user" }
                )
            }
        )

        # DonnÃ©es de test pour les permissions de base de donnÃ©es
        $mockDatabasePermissions = @(
            [PSCustomObject]@{
                DatabaseName = "TestDB"
                GranteeName = "guest"
                Permissions = @(
                    [PSCustomObject]@{
                        PermissionName = "SELECT"
                        PermissionState = "GRANT"
                        SecurableType = "DATABASE"
                    }
                )
            },
            [PSCustomObject]@{
                DatabaseName = "TestDB"
                GranteeName = "normal_user"
                Permissions = @(
                    [PSCustomObject]@{
                        PermissionName = "CONTROL"
                        PermissionState = "GRANT"
                        SecurableType = "DATABASE"
                    }
                )
            }
        )

        It "Find-DatabasePermissionAnomalies devrait dÃ©tecter les anomalies au niveau base de donnÃ©es" {
            $anomalies = Find-DatabasePermissionAnomalies -DatabaseRoles $mockDatabaseRoles -DatabasePermissions $mockDatabasePermissions -DatabaseUsers $mockDatabaseUsers -ServerLogins $mockServerLogins
            
            $anomalies | Should -Not -BeNullOrEmpty
            $anomalies.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier que les utilisateurs orphelins sont dÃ©tectÃ©s
            $orphanedUserAnomalies = $anomalies | Where-Object { $_.UserName -eq "orphaned_user" }
            $orphanedUserAnomalies | Should -Not -BeNullOrEmpty
            
            # VÃ©rifier que les utilisateurs dÃ©sactivÃ©s avec des permissions sont dÃ©tectÃ©s
            $disabledUserAnomalies = $anomalies | Where-Object { $_.UserName -eq "disabled_user" }
            $disabledUserAnomalies | Should -Not -BeNullOrEmpty
            
            # VÃ©rifier que les utilisateurs avec des permissions Ã©levÃ©es sont dÃ©tectÃ©s
            $highPrivilegeUserAnomalies = $anomalies | Where-Object { $_.UserName -eq "normal_user" -and $_.AnomalyType -eq "HighPrivilegeDatabaseAccount" }
            $highPrivilegeUserAnomalies | Should -Not -BeNullOrEmpty
            
            # VÃ©rifier que les permissions guest sont dÃ©tectÃ©es
            $guestPermissionAnomalies = $anomalies | Where-Object { $_.UserName -eq "guest" }
            $guestPermissionAnomalies | Should -Not -BeNullOrEmpty
        }

        # DonnÃ©es de test pour les permissions d'objets
        $mockObjectPermissions = @(
            [PSCustomObject]@{
                GranteeName = "disabled_user"
                ObjectCount = 2
                ObjectPermissions = @(
                    [PSCustomObject]@{
                        ObjectName = "Table1"
                        ObjectType = "USER_TABLE"
                        Permissions = @(
                            [PSCustomObject]@{
                                PermissionName = "SELECT"
                                PermissionState = "GRANT"
                            }
                        )
                    },
                    [PSCustomObject]@{
                        ObjectName = "Table2"
                        ObjectType = "USER_TABLE"
                        Permissions = @(
                            [PSCustomObject]@{
                                PermissionName = "UPDATE"
                                PermissionState = "GRANT"
                            }
                        )
                    }
                )
            },
            [PSCustomObject]@{
                GranteeName = "guest"
                ObjectCount = 1
                ObjectPermissions = @(
                    [PSCustomObject]@{
                        ObjectName = "Table3"
                        ObjectType = "USER_TABLE"
                        Permissions = @(
                            [PSCustomObject]@{
                                PermissionName = "SELECT"
                                PermissionState = "GRANT"
                            }
                        )
                    }
                )
            },
            [PSCustomObject]@{
                GranteeName = "normal_user"
                ObjectCount = 1
                ObjectPermissions = @(
                    [PSCustomObject]@{
                        ObjectName = "Table4"
                        ObjectType = "USER_TABLE"
                        Permissions = @(
                            [PSCustomObject]@{
                                PermissionName = "CONTROL"
                                PermissionState = "GRANT"
                            }
                        )
                    }
                )
            }
        )

        It "Find-ObjectPermissionAnomalies devrait dÃ©tecter les anomalies au niveau objet" {
            $anomalies = Find-ObjectPermissionAnomalies -ObjectPermissions $mockObjectPermissions -DatabaseUsers $mockDatabaseUsers -DatabaseName "TestDB"
            
            $anomalies | Should -Not -BeNullOrEmpty
            $anomalies.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier que les utilisateurs dÃ©sactivÃ©s avec des permissions sur des objets sont dÃ©tectÃ©s
            $disabledUserObjectAnomalies = $anomalies | Where-Object { $_.UserName -eq "disabled_user" }
            $disabledUserObjectAnomalies | Should -Not -BeNullOrEmpty
            
            # VÃ©rifier que les permissions guest sur des objets sont dÃ©tectÃ©es
            $guestObjectAnomalies = $anomalies | Where-Object { $_.UserName -eq "guest" }
            $guestObjectAnomalies | Should -Not -BeNullOrEmpty
            
            # VÃ©rifier que les permissions CONTROL sur des objets sont dÃ©tectÃ©es
            $controlObjectAnomalies = $anomalies | Where-Object { $_.UserName -eq "normal_user" }
            $controlObjectAnomalies | Should -Not -BeNullOrEmpty
        }
    }
}
