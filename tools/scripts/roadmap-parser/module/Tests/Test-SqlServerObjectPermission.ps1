# Test simplifié pour la fonction Analyze-SqlServerPermission avec analyse au niveau objet

# Importer la fonction à tester
$scriptPath = "$PSScriptRoot\..\Functions\Public\Analyze-SqlServerPermission.ps1"
if (Test-Path $scriptPath) {
    Write-Host "Chargement du script: $scriptPath" -ForegroundColor Green
    . $scriptPath
} else {
    Write-Error "Le fichier de script '$scriptPath' n'existe pas."
    exit 1
}

# Vérifier que la fonction est bien importée
if (-not (Get-Command -Name Analyze-SqlServerPermission -ErrorAction SilentlyContinue)) {
    Write-Error "La fonction Analyze-SqlServerPermission n'a pas été correctement importée."
    exit 1
} else {
    Write-Host "La fonction Analyze-SqlServerPermission a été correctement importée." -ForegroundColor Green

    # Afficher les paramètres de la fonction
    $cmdInfo = Get-Command -Name Analyze-SqlServerPermission
    Write-Host "Paramètres de la fonction:" -ForegroundColor Cyan
    foreach ($param in $cmdInfo.Parameters.Keys) {
        if ($param -notin [System.Management.Automation.PSCmdlet]::CommonParameters) {
            Write-Host "  - $param" -ForegroundColor Gray
        }
    }
}

# Créer un dossier temporaire pour les rapports
$TempFolder = Join-Path -Path $env:TEMP -ChildPath "SqlPermissionReports"
New-Item -Path $TempFolder -ItemType Directory -Force | Out-Null

# Mock pour Invoke-Sqlcmd - Rôles serveur
function Invoke-Sqlcmd {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ServerInstance,

        [Parameter(Mandatory = $false)]
        [string]$Query,

        [Parameter(Mandatory = $false)]
        [string]$Database,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [string]$ErrorAction
    )

    # Requête pour obtenir la liste des bases de données
    if ($Query -like "*sys.databases*") {
        return @(
            [PSCustomObject]@{
                name = "AdventureWorks"
            },
            [PSCustomObject]@{
                name = "Northwind"
            }
        )
    }
    # Requête pour obtenir les rôles serveur
    elseif ($Query -like "*sys.server_role_members*") {
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
            }
        )
    }
    # Requête pour obtenir les permissions serveur
    elseif ($Query -like "*sys.server_permissions*") {
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
            }
        )
    }
    # Requête pour obtenir les logins serveur
    elseif ($Query -like "*sys.server_principals*" -and $Query -like "*LOGINPROPERTY*") {
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
            }
        )
    }
    # Requête pour obtenir les rôles de base de données
    elseif ($Query -like "*sys.database_role_members*") {
        return @(
            [PSCustomObject]@{
                RoleName         = "db_owner"
                MemberName       = "dbo"
                MemberType       = "SQL_USER"
                MemberCreateDate = (Get-Date).AddYears(-1)
                IsDisabled       = 0
            },
            [PSCustomObject]@{
                RoleName         = "db_datareader"
                MemberName       = "read_user"
                MemberType       = "SQL_USER"
                MemberCreateDate = (Get-Date).AddMonths(-3)
                IsDisabled       = 0
            }
        )
    }
    # Requête pour obtenir les permissions de base de données
    elseif ($Query -like "*sys.database_permissions*" -and $Query -notlike "*sys.objects*") {
        return @(
            [PSCustomObject]@{
                GranteeName     = "dbo"
                GranteeType     = "SQL_USER"
                SecurableName   = "DATABASE"
                SecurableType   = "DATABASE"
                PermissionName  = "CONTROL"
                PermissionState = "GRANT"
            },
            [PSCustomObject]@{
                GranteeName     = "read_user"
                GranteeType     = "SQL_USER"
                SecurableName   = "DATABASE"
                SecurableType   = "DATABASE"
                PermissionName  = "SELECT"
                PermissionState = "GRANT"
            }
        )
    }
    # Requête pour obtenir les utilisateurs de base de données
    elseif ($Query -like "*sys.database_principals*" -and $Query -notlike "*sys.database_role_members*") {
        return @(
            [PSCustomObject]@{
                UserName      = "dbo"
                UserType      = "SQL_USER"
                CreateDate    = (Get-Date).AddYears(-1)
                ModifyDate    = (Get-Date).AddYears(-1)
                DefaultSchema = "dbo"
                LoginName     = "sa"
                IsDisabled    = 0
            },
            [PSCustomObject]@{
                UserName      = "read_user"
                UserType      = "SQL_USER"
                CreateDate    = (Get-Date).AddMonths(-3)
                ModifyDate    = (Get-Date).AddMonths(-3)
                DefaultSchema = "dbo"
                LoginName     = "ReadOnlyUser"
                IsDisabled    = 0
            },
            [PSCustomObject]@{
                UserName      = "guest"
                UserType      = "SQL_USER"
                CreateDate    = (Get-Date).AddYears(-1)
                ModifyDate    = (Get-Date).AddYears(-1)
                DefaultSchema = "guest"
                LoginName     = $null
                IsDisabled    = 0
            }
        )
    }
    # Requête pour obtenir les objets de base de données
    elseif ($Query -like "*sys.objects*" -and $Query -like "*OBJECT_SCHEMA_NAME*" -and $Query -notlike "*sys.database_permissions*") {
        return @(
            [PSCustomObject]@{
                SchemaName  = "dbo"
                ObjectName  = "Customers"
                ObjectType  = "USER_TABLE"
                CreateDate  = (Get-Date).AddYears(-1)
                ModifyDate  = (Get-Date).AddMonths(-1)
                IsMsShipped = $false
            },
            [PSCustomObject]@{
                SchemaName  = "dbo"
                ObjectName  = "Orders"
                ObjectType  = "USER_TABLE"
                CreateDate  = (Get-Date).AddYears(-1)
                ModifyDate  = (Get-Date).AddMonths(-1)
                IsMsShipped = $false
            },
            [PSCustomObject]@{
                SchemaName  = "dbo"
                ObjectName  = "CustomerView"
                ObjectType  = "VIEW"
                CreateDate  = (Get-Date).AddMonths(-6)
                ModifyDate  = (Get-Date).AddMonths(-1)
                IsMsShipped = $false
            },
            [PSCustomObject]@{
                SchemaName  = "dbo"
                ObjectName  = "GetCustomerOrders"
                ObjectType  = "SQL_STORED_PROCEDURE"
                CreateDate  = (Get-Date).AddMonths(-6)
                ModifyDate  = (Get-Date).AddMonths(-1)
                IsMsShipped = $false
            }
        )
    }
    # Requête pour obtenir les permissions au niveau objet
    elseif ($Query -like "*sys.database_permissions*" -and $Query -like "*sys.objects*") {
        return @(
            [PSCustomObject]@{
                GranteeName     = "dbo"
                GranteeType     = "SQL_USER"
                ObjectName      = "dbo.Customers"
                ObjectType      = "USER_TABLE"
                PermissionName  = "CONTROL"
                PermissionState = "GRANT"
            },
            [PSCustomObject]@{
                GranteeName     = "read_user"
                GranteeType     = "SQL_USER"
                ObjectName      = "dbo.Customers"
                ObjectType      = "USER_TABLE"
                PermissionName  = "SELECT"
                PermissionState = "GRANT"
            },
            [PSCustomObject]@{
                GranteeName     = "read_user"
                GranteeType     = "SQL_USER"
                ObjectName      = "dbo.Orders"
                ObjectType      = "USER_TABLE"
                PermissionName  = "SELECT"
                PermissionState = "GRANT"
            },
            [PSCustomObject]@{
                GranteeName     = "read_user"
                GranteeType     = "SQL_USER"
                ObjectName      = "dbo.CustomerView"
                ObjectType      = "VIEW"
                PermissionName  = "SELECT"
                PermissionState = "GRANT"
            },
            [PSCustomObject]@{
                GranteeName     = "guest"
                GranteeType     = "SQL_USER"
                ObjectName      = "dbo.Customers"
                ObjectType      = "USER_TABLE"
                PermissionName  = "SELECT"
                PermissionState = "GRANT"
            }
        )
    }
}

# Mock pour Get-Module
function Get-Module {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$ListAvailable
    )

    if ($Name -eq "SqlServer" -and $ListAvailable) {
        return $true
    }
}

# Mock pour Import-Module
function Import-Module {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$ErrorAction
    )

    # Ne rien faire, juste simuler l'importation
}

# Tester la fonction
Write-Host "Test de la fonction Analyze-SqlServerPermission avec analyse au niveau objet..." -ForegroundColor Cyan

# Définir la variable d'environnement pour le test
$env:PESTER_TEST_RUN = $true

# Créer une fonction de test qui utilise la fonction importée
function Test-AnalyzeSqlServerPermission {
    param (
        [string]$ServerInstance,
        [bool]$IncludeDatabaseLevel,
        [bool]$IncludeObjectLevel
    )

    try {
        # Appeler la fonction avec les paramètres fournis
        $result = Analyze-SqlServerPermission -ServerInstance $ServerInstance -IncludeDatabaseLevel $IncludeDatabaseLevel -IncludeObjectLevel $IncludeObjectLevel
        return $result
    } catch {
        Write-Host "Erreur lors de l'appel de la fonction: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Test avec analyse au niveau objet
$result = Test-AnalyzeSqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -IncludeDatabaseLevel $true -IncludeObjectLevel $true

# Vérifier les résultats
Write-Host "`nVérification des résultats..." -ForegroundColor Cyan

# Vérifier les propriétés de base
if ($result -and $result.ServerInstance -eq "localhost\SQLEXPRESS") {
    Write-Host "- ServerInstance: OK" -ForegroundColor Green
} else {
    Write-Host "- ServerInstance: ÉCHEC" -ForegroundColor Red
}

if ($result.IncludeObjectLevel -eq $true) {
    Write-Host "- IncludeObjectLevel: OK" -ForegroundColor Green
} else {
    Write-Host "- IncludeObjectLevel: ÉCHEC" -ForegroundColor Red
}

if ($result.DatabaseObjects -and $result.DatabaseObjects.Count -gt 0) {
    Write-Host "- DatabaseObjects: OK (Count: $($result.DatabaseObjects.Count))" -ForegroundColor Green

    # Vérifier les types d'objets
    $objectTypes = $result.DatabaseObjects | ForEach-Object { $_.ObjectType } | Sort-Object -Unique
    Write-Host "  Types d'objets détectés: $($objectTypes -join ', ')" -ForegroundColor Gray
} else {
    Write-Host "- DatabaseObjects: ÉCHEC" -ForegroundColor Red
}

if ($result.ObjectPermissions -and $result.ObjectPermissions.Count -gt 0) {
    Write-Host "- ObjectPermissions: OK (Count: $($result.ObjectPermissions.Count))" -ForegroundColor Green

    # Vérifier les utilisateurs avec des permissions
    $users = $result.ObjectPermissions | ForEach-Object { $_.GranteeName } | Sort-Object -Unique
    Write-Host "  Utilisateurs avec des permissions sur des objets: $($users -join ', ')" -ForegroundColor Gray
} else {
    Write-Host "- ObjectPermissions: ÉCHEC" -ForegroundColor Red
}

if ($result.ObjectPermissionAnomalies -and $result.ObjectPermissionAnomalies.Count -gt 0) {
    Write-Host "- ObjectPermissionAnomalies: OK (Count: $($result.ObjectPermissionAnomalies.Count))" -ForegroundColor Green

    # Vérifier les types d'anomalies
    $anomalyTypes = $result.ObjectPermissionAnomalies | Group-Object -Property AnomalyType | Select-Object -ExpandProperty Name
    Write-Host "  Types d'anomalies détectés au niveau objet: $($anomalyTypes -join ', ')" -ForegroundColor Gray
} else {
    Write-Host "- ObjectPermissionAnomalies: ÉCHEC" -ForegroundColor Red
}

# Test de génération de rapport
$outputPath = Join-Path -Path $TempFolder -ChildPath "SqlObjectPermissions.html"
Test-AnalyzeSqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -IncludeDatabaseLevel $true -IncludeObjectLevel $true | Export-PermissionReport -OutputPath $outputPath -OutputFormat "HTML"

if (Test-Path -Path $outputPath) {
    Write-Host "- Génération de rapport HTML: OK" -ForegroundColor Green
} else {
    Write-Host "- Génération de rapport HTML: ÉCHEC" -ForegroundColor Red
}

# Test de génération de rapport CSV
$outputPath = Join-Path -Path $TempFolder -ChildPath "SqlObjectPermissions.csv"
Test-AnalyzeSqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -IncludeDatabaseLevel $true -IncludeObjectLevel $true | Export-PermissionReport -OutputPath $outputPath -OutputFormat "CSV"

$objectPermissionsPath = [System.IO.Path]::ChangeExtension($outputPath, "object_permissions.csv")
$objectAnomaliesPath = [System.IO.Path]::ChangeExtension($outputPath, "object_anomalies.csv")
$databaseObjectsPath = [System.IO.Path]::ChangeExtension($outputPath, "database_objects.csv")

if ((Test-Path -Path $objectPermissionsPath) -or (Test-Path -Path $objectAnomaliesPath) -or (Test-Path -Path $databaseObjectsPath)) {
    Write-Host "- Génération de rapport CSV: OK" -ForegroundColor Green
} else {
    Write-Host "- Génération de rapport CSV: ÉCHEC" -ForegroundColor Red
}

# Test de génération de rapport JSON
$outputPath = Join-Path -Path $TempFolder -ChildPath "SqlObjectPermissions.json"
Test-AnalyzeSqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -IncludeDatabaseLevel $true -IncludeObjectLevel $true | Export-PermissionReport -OutputPath $outputPath -OutputFormat "JSON"

if (Test-Path -Path $outputPath) {
    Write-Host "- Génération de rapport JSON: OK" -ForegroundColor Green
} else {
    Write-Host "- Génération de rapport JSON: ÉCHEC" -ForegroundColor Red
}

# Test sans analyse au niveau objet
$result = Test-AnalyzeSqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -IncludeDatabaseLevel $true -IncludeObjectLevel $false

if ($result -and $result.IncludeObjectLevel -eq $false -and $result.ObjectPermissions.Count -eq 0) {
    Write-Host "- Test sans analyse au niveau objet: OK" -ForegroundColor Green
} else {
    Write-Host "- Test sans analyse au niveau objet: ÉCHEC" -ForegroundColor Red
}

# Nettoyer les fichiers temporaires
if (Test-Path -Path $TempFolder) {
    Remove-Item -Path $TempFolder -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`nTests terminés." -ForegroundColor Cyan
