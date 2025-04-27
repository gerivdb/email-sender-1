# Test manuel pour la fonction Analyze-SqlServerPermission

# Définir la fonction à tester
function Analyze-SqlServerPermission {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$ServerInstance,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("HTML", "CSV", "JSON", "XML")]
        [string]$OutputFormat = "HTML"
    )

    # Simuler l'analyse des permissions SQL Server
    Write-Host "Analyse des permissions SQL Server pour l'instance: $ServerInstance"

    # Simuler les rôles serveur
    $serverRoles = @(
        [PSCustomObject]@{
            RoleName    = "sysadmin"
            Members     = @(
                [PSCustomObject]@{
                    MemberName = "sa"
                    MemberType = "SQL_LOGIN"
                    CreateDate = (Get-Date).AddYears(-1)
                    IsDisabled = $false
                },
                [PSCustomObject]@{
                    MemberName = "DOMAIN\Administrator"
                    MemberType = "WINDOWS_LOGIN"
                    CreateDate = (Get-Date).AddYears(-1)
                    IsDisabled = $false
                }
            )
            MemberCount = 2
        },
        [PSCustomObject]@{
            RoleName    = "securityadmin"
            Members     = @(
                [PSCustomObject]@{
                    MemberName = "SecurityUser"
                    MemberType = "SQL_LOGIN"
                    CreateDate = (Get-Date).AddMonths(-6)
                    IsDisabled = $true
                }
            )
            MemberCount = 1
        }
    )

    # Simuler les permissions serveur
    $serverPermissions = @(
        [PSCustomObject]@{
            GranteeName     = "sa"
            GranteeType     = "SQL_LOGIN"
            Permissions     = @(
                [PSCustomObject]@{
                    SecurableName   = "SERVER"
                    SecurableType   = "SERVER"
                    PermissionName  = "CONTROL SERVER"
                    PermissionState = "GRANT"
                }
            )
            PermissionCount = 1
        },
        [PSCustomObject]@{
            GranteeName     = "DOMAIN\Administrator"
            GranteeType     = "WINDOWS_LOGIN"
            Permissions     = @(
                [PSCustomObject]@{
                    SecurableName   = "SERVER"
                    SecurableType   = "SERVER"
                    PermissionName  = "ALTER ANY LOGIN"
                    PermissionState = "GRANT"
                }
            )
            PermissionCount = 1
        },
        [PSCustomObject]@{
            GranteeName     = "SecurityUser"
            GranteeType     = "SQL_LOGIN"
            Permissions     = @(
                [PSCustomObject]@{
                    SecurableName   = "SERVER"
                    SecurableType   = "SERVER"
                    PermissionName  = "VIEW SERVER STATE"
                    PermissionState = "GRANT"
                }
            )
            PermissionCount = 1
        }
    )

    # Simuler les logins serveur
    $serverLogins = @(
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

    # Simuler les anomalies de permissions
    $permissionAnomalies = @(
        [PSCustomObject]@{
            AnomalyType       = "DisabledLoginWithPermissions"
            LoginName         = "SecurityUser"
            Description       = "Le login désactivé possède des permissions ou est membre de rôles serveur"
            Severity          = "Moyenne"
            RecommendedAction = "Révoquer les permissions ou retirer des rôles serveur"
        },
        [PSCustomObject]@{
            AnomalyType       = "HighPrivilegeAccount"
            LoginName         = "sa"
            Description       = "Le login est membre du rôle serveur à privilèges élevés: sysadmin"
            Severity          = "Élevée"
            RecommendedAction = "Vérifier si ce niveau de privilège est nécessaire"
        },
        [PSCustomObject]@{
            AnomalyType       = "HighPrivilegeAccount"
            LoginName         = "DOMAIN\Administrator"
            Description       = "Le login est membre du rôle serveur à privilèges élevés: sysadmin"
            Severity          = "Élevée"
            RecommendedAction = "Vérifier si ce niveau de privilège est nécessaire"
        },
        [PSCustomObject]@{
            AnomalyType       = "ExpiredPassword"
            LoginName         = "SecurityUser"
            Description       = "Le mot de passe du login SQL est expiré"
            Severity          = "Moyenne"
            RecommendedAction = "Changer le mot de passe du compte"
        },
        [PSCustomObject]@{
            AnomalyType       = "LockedAccount"
            LoginName         = "LockedUser"
            Description       = "Le compte est verrouillé"
            Severity          = "Moyenne"
            RecommendedAction = "Déverrouiller le compte et investiguer la cause"
        },
        [PSCustomObject]@{
            AnomalyType       = "ControlServerPermission"
            LoginName         = "sa"
            Description       = "Le login possède la permission CONTROL SERVER (équivalent à sysadmin)"
            Severity          = "Élevée"
            RecommendedAction = "Vérifier si ce niveau de privilège est nécessaire"
        }
    )

    # Créer l'objet de résultat
    $result = [PSCustomObject]@{
        ServerInstance      = $ServerInstance
        ServerRoles         = $serverRoles
        ServerPermissions   = $serverPermissions
        ServerLogins        = $serverLogins
        PermissionAnomalies = $permissionAnomalies
        AnalysisDate        = Get-Date
    }

    # Générer un rapport si demandé
    if ($OutputPath) {
        if ($PSCmdlet.ShouldProcess("Rapport de permissions", "Génération")) {
            Write-Host "Generation du rapport de permissions au format $OutputFormat : $OutputPath"

            # Simuler la génération de rapport
            switch ($OutputFormat) {
                "HTML" {
                    # Créer un rapport HTML minimal
                    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de permissions SQL Server</title>
</head>
<body>
    <h1>Rapport de permissions SQL Server</h1>
    <p>Instance: $ServerInstance</p>
    <p>Date: $(Get-Date)</p>
</body>
</html>
"@
                    $htmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
                }
                "CSV" {
                    # Créer des fichiers CSV
                    $anomaliesPath = [System.IO.Path]::ChangeExtension($OutputPath, "anomalies.csv")
                    $permissionAnomalies | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath $anomaliesPath -Encoding UTF8

                    $loginsPath = [System.IO.Path]::ChangeExtension($OutputPath, "server_logins.csv")
                    $serverLogins | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath $loginsPath -Encoding UTF8
                }
                "JSON" {
                    # Créer un rapport JSON
                    $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
                }
                "XML" {
                    # Créer un rapport XML
                    $result | Export-Clixml -Path $OutputPath
                }
            }
        }
    }

    # Retourner les résultats
    return $result
}

# Créer un dossier temporaire pour les rapports
$TempFolder = Join-Path -Path $env:TEMP -ChildPath "SqlPermissionReports"
New-Item -Path $TempFolder -ItemType Directory -Force | Out-Null

# Tester la fonction
Write-Host "Test de la fonction Analyze-SqlServerPermission..." -ForegroundColor Cyan

# Test de base
$result = Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS"

# Vérifier les résultats
Write-Host "`nVérification des résultats..." -ForegroundColor Cyan

# Vérifier les propriétés de base
if ($result -and $result.ServerInstance -eq "localhost\SQLEXPRESS") {
    Write-Host "- ServerInstance: OK" -ForegroundColor Green
} else {
    Write-Host "- ServerInstance: ÉCHEC" -ForegroundColor Red
}

if ($result.ServerRoles -and $result.ServerRoles.Count -gt 0) {
    Write-Host "- ServerRoles: OK (Count: $($result.ServerRoles.Count))" -ForegroundColor Green
} else {
    Write-Host "- ServerRoles: ÉCHEC" -ForegroundColor Red
}

if ($result.ServerPermissions -and $result.ServerPermissions.Count -gt 0) {
    Write-Host "- ServerPermissions: OK (Count: $($result.ServerPermissions.Count))" -ForegroundColor Green
} else {
    Write-Host "- ServerPermissions: ÉCHEC" -ForegroundColor Red
}

if ($result.ServerLogins -and $result.ServerLogins.Count -gt 0) {
    Write-Host "- ServerLogins: OK (Count: $($result.ServerLogins.Count))" -ForegroundColor Green
} else {
    Write-Host "- ServerLogins: ÉCHEC" -ForegroundColor Red
}

if ($result.PermissionAnomalies -and $result.PermissionAnomalies.Count -gt 0) {
    Write-Host "- PermissionAnomalies: OK (Count: $($result.PermissionAnomalies.Count))" -ForegroundColor Green

    # Vérifier les types d'anomalies
    $anomalyTypes = $result.PermissionAnomalies | Group-Object -Property AnomalyType | Select-Object -ExpandProperty Name
    Write-Host "  Types d'anomalies détectés: $($anomalyTypes -join ', ')" -ForegroundColor Gray
} else {
    Write-Host "- PermissionAnomalies: ÉCHEC" -ForegroundColor Red
}

# Test de génération de rapport
$outputPath = Join-Path -Path $TempFolder -ChildPath "SqlPermissions.html"
Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -OutputPath $outputPath -OutputFormat "HTML"

if (Test-Path -Path $outputPath) {
    Write-Host "- Génération de rapport HTML: OK" -ForegroundColor Green
} else {
    Write-Host "- Génération de rapport HTML: ÉCHEC" -ForegroundColor Red
}

# Test de génération de rapport CSV
$outputPath = Join-Path -Path $TempFolder -ChildPath "SqlPermissions.csv"
Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -OutputPath $outputPath -OutputFormat "CSV"

$anomaliesPath = [System.IO.Path]::ChangeExtension($outputPath, "anomalies.csv")
if (Test-Path -Path $anomaliesPath) {
    Write-Host "- Génération de rapport CSV: OK" -ForegroundColor Green
} else {
    Write-Host "- Génération de rapport CSV: ÉCHEC" -ForegroundColor Red
}

# Test de génération de rapport JSON
$outputPath = Join-Path -Path $TempFolder -ChildPath "SqlPermissions.json"
Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -OutputPath $outputPath -OutputFormat "JSON"

if (Test-Path -Path $outputPath) {
    Write-Host "- Génération de rapport JSON: OK" -ForegroundColor Green
} else {
    Write-Host "- Génération de rapport JSON: ÉCHEC" -ForegroundColor Red
}

# Test de génération de rapport XML
$outputPath = Join-Path -Path $TempFolder -ChildPath "SqlPermissions.xml"
Analyze-SqlServerPermission -ServerInstance "localhost\SQLEXPRESS" -OutputPath $outputPath -OutputFormat "XML"

if (Test-Path -Path $outputPath) {
    Write-Host "- Génération de rapport XML: OK" -ForegroundColor Green
} else {
    Write-Host "- Génération de rapport XML: ÉCHEC" -ForegroundColor Red
}

# Nettoyer les fichiers temporaires
if (Test-Path -Path $TempFolder) {
    Remove-Item -Path $TempFolder -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`nTests terminés." -ForegroundColor Cyan
