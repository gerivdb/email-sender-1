# Manage-AccessControl.ps1
# Module pour la gestion des accès et l'audit de sécurité
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Fournit des fonctions pour la gestion des accès et l'audit de sécurité.

.DESCRIPTION
    Ce module fournit des fonctions pour la gestion des accès et l'audit de sécurité,
    notamment le contrôle d'accès basé sur les rôles, la journalisation des accès et l'audit de sécurité.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
Add-Type -AssemblyName System.Security

# Définir les rôles et les permissions
$Global:RoadmapRoles = @{
    "Admin" = @{
        Description = "Administrateur avec accès complet"
        Permissions = @(
            "roadmap:create", "roadmap:read", "roadmap:update", "roadmap:delete",
            "user:create", "user:read", "user:update", "user:delete",
            "role:create", "role:read", "role:update", "role:delete",
            "audit:read", "audit:export",
            "security:configure"
        )
    }
    "Manager" = @{
        Description = "Gestionnaire de roadmaps"
        Permissions = @(
            "roadmap:create", "roadmap:read", "roadmap:update",
            "user:read",
            "role:read",
            "audit:read"
        )
    }
    "Editor" = @{
        Description = "Éditeur de roadmaps"
        Permissions = @(
            "roadmap:read", "roadmap:update"
        )
    }
    "Viewer" = @{
        Description = "Lecteur de roadmaps"
        Permissions = @(
            "roadmap:read"
        )
    }
}

# Fonction pour créer un utilisateur
function New-RoadmapUser {
    <#
    .SYNOPSIS
        Crée un nouvel utilisateur pour le système de roadmaps.

    .DESCRIPTION
        Cette fonction crée un nouvel utilisateur pour le système de roadmaps
        avec les rôles et permissions spécifiés.

    .PARAMETER UserId
        L'identifiant de l'utilisateur.

    .PARAMETER FullName
        Le nom complet de l'utilisateur.

    .PARAMETER Email
        L'adresse e-mail de l'utilisateur.

    .PARAMETER Roles
        Les rôles attribués à l'utilisateur.

    .PARAMETER CustomPermissions
        Les permissions personnalisées attribuées à l'utilisateur.

    .PARAMETER Enabled
        Indique si l'utilisateur est activé.

    .PARAMETER RequireMFA
        Indique si l'authentification multi-facteurs est requise pour cet utilisateur.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les informations de l'utilisateur.

    .EXAMPLE
        New-RoadmapUser -UserId "john.doe" -FullName "John Doe" -Email "john.doe@example.com" -Roles @("Editor", "Viewer") -Enabled $true -RequireMFA $true -OutputPath "C:\Users\john.doe.json"
        Crée un nouvel utilisateur avec les rôles d'éditeur et de lecteur.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserId,

        [Parameter(Mandatory = $true)]
        [string]$FullName,

        [Parameter(Mandatory = $true)]
        [string]$Email,

        [Parameter(Mandatory = $false)]
        [string[]]$Roles = @("Viewer"),

        [Parameter(Mandatory = $false)]
        [string[]]$CustomPermissions = @(),

        [Parameter(Mandatory = $false)]
        [bool]$Enabled = $true,

        [Parameter(Mandatory = $false)]
        [bool]$RequireMFA = $false,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    try {
        # Vérifier que les rôles sont valides
        foreach ($Role in $Roles) {
            if (-not $Global:RoadmapRoles.ContainsKey($Role)) {
                Write-Error "Rôle invalide: $Role"
                return $null
            }
        }
        
        # Calculer les permissions basées sur les rôles
        $Permissions = @()
        foreach ($Role in $Roles) {
            $Permissions += $Global:RoadmapRoles[$Role].Permissions
        }
        
        # Ajouter les permissions personnalisées
        $Permissions += $CustomPermissions
        
        # Supprimer les doublons
        $Permissions = $Permissions | Select-Object -Unique
        
        # Créer l'objet utilisateur
        $User = [PSCustomObject]@{
            UserId = $UserId
            FullName = $FullName
            Email = $Email
            Roles = $Roles
            Permissions = $Permissions
            CustomPermissions = $CustomPermissions
            Enabled = $Enabled
            RequireMFA = $RequireMFA
            CreationDate = Get-Date
            LastModified = Get-Date
            LastLogin = $null
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        $OutputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }
        
        # Sauvegarder l'utilisateur
        $UserJson = $User | ConvertTo-Json
        $UserJson | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Host "Utilisateur créé: $OutputPath" -ForegroundColor Green
        
        # Journaliser l'action
        Add-SecurityAuditLog -Action "UserCreated" -UserId $env:USERNAME -TargetId $UserId -Details "Utilisateur créé avec les rôles: $($Roles -join ', ')"
        
        return $User
    } catch {
        Write-Error "Échec de la création de l'utilisateur: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour obtenir un utilisateur
function Get-RoadmapUser {
    <#
    .SYNOPSIS
        Obtient les informations d'un utilisateur.

    .DESCRIPTION
        Cette fonction obtient les informations d'un utilisateur à partir d'un fichier JSON.

    .PARAMETER UserId
        L'identifiant de l'utilisateur.

    .PARAMETER UserPath
        Le chemin vers le fichier de l'utilisateur.
        Si non spécifié, le chemin par défaut est utilisé.

    .PARAMETER DefaultUserDir
        Le répertoire par défaut pour les fichiers utilisateur.

    .EXAMPLE
        Get-RoadmapUser -UserId "john.doe" -DefaultUserDir "C:\Users"
        Obtient les informations de l'utilisateur john.doe.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [string]$UserId,

        [Parameter(Mandatory = $true, ParameterSetName = "ByPath")]
        [string]$UserPath,

        [Parameter(Mandatory = $false, ParameterSetName = "ById")]
        [string]$DefaultUserDir = ".\users"
    )

    try {
        # Déterminer le chemin du fichier utilisateur
        if ($PSCmdlet.ParameterSetName -eq "ById") {
            # Créer le dossier par défaut s'il n'existe pas
            if (-not (Test-Path $DefaultUserDir)) {
                New-Item -Path $DefaultUserDir -ItemType Directory -Force | Out-Null
            }
            
            $UserPath = Join-Path -Path $DefaultUserDir -ChildPath "$UserId.json"
        }
        
        # Vérifier que le fichier existe
        if (-not (Test-Path $UserPath)) {
            Write-Error "Le fichier utilisateur n'existe pas: $UserPath"
            return $null
        }
        
        # Charger l'utilisateur
        $User = Get-Content -Path $UserPath -Raw | ConvertFrom-Json
        
        # Journaliser l'action
        Add-SecurityAuditLog -Action "UserRead" -UserId $env:USERNAME -TargetId $User.UserId -Details "Informations utilisateur lues"
        
        return $User
    } catch {
        Write-Error "Échec de l'obtention de l'utilisateur: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour mettre à jour un utilisateur
function Update-RoadmapUser {
    <#
    .SYNOPSIS
        Met à jour les informations d'un utilisateur.

    .DESCRIPTION
        Cette fonction met à jour les informations d'un utilisateur.

    .PARAMETER User
        L'objet utilisateur à mettre à jour.

    .PARAMETER FullName
        Le nouveau nom complet de l'utilisateur.

    .PARAMETER Email
        La nouvelle adresse e-mail de l'utilisateur.

    .PARAMETER Roles
        Les nouveaux rôles attribués à l'utilisateur.

    .PARAMETER CustomPermissions
        Les nouvelles permissions personnalisées attribuées à l'utilisateur.

    .PARAMETER Enabled
        Indique si l'utilisateur est activé.

    .PARAMETER RequireMFA
        Indique si l'authentification multi-facteurs est requise pour cet utilisateur.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les informations de l'utilisateur.
        Si non spécifié, le chemin d'origine est utilisé.

    .EXAMPLE
        $user = Get-RoadmapUser -UserId "john.doe"
        Update-RoadmapUser -User $user -Roles @("Admin", "Manager") -Enabled $true
        Met à jour les rôles de l'utilisateur john.doe.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$User,

        [Parameter(Mandatory = $false)]
        [string]$FullName,

        [Parameter(Mandatory = $false)]
        [string]$Email,

        [Parameter(Mandatory = $false)]
        [string[]]$Roles,

        [Parameter(Mandatory = $false)]
        [string[]]$CustomPermissions,

        [Parameter(Mandatory = $false)]
        [bool]$Enabled,

        [Parameter(Mandatory = $false)]
        [bool]$RequireMFA,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    try {
        # Mettre à jour les propriétés spécifiées
        if (-not [string]::IsNullOrEmpty($FullName)) {
            $User.FullName = $FullName
        }
        
        if (-not [string]::IsNullOrEmpty($Email)) {
            $User.Email = $Email
        }
        
        if ($null -ne $Roles) {
            # Vérifier que les rôles sont valides
            foreach ($Role in $Roles) {
                if (-not $Global:RoadmapRoles.ContainsKey($Role)) {
                    Write-Error "Rôle invalide: $Role"
                    return $null
                }
            }
            
            $User.Roles = $Roles
            
            # Recalculer les permissions basées sur les rôles
            $Permissions = @()
            foreach ($Role in $Roles) {
                $Permissions += $Global:RoadmapRoles[$Role].Permissions
            }
            
            # Ajouter les permissions personnalisées existantes
            $Permissions += $User.CustomPermissions
            
            # Supprimer les doublons
            $User.Permissions = $Permissions | Select-Object -Unique
        }
        
        if ($null -ne $CustomPermissions) {
            $User.CustomPermissions = $CustomPermissions
            
            # Recalculer les permissions
            $Permissions = @()
            foreach ($Role in $User.Roles) {
                $Permissions += $Global:RoadmapRoles[$Role].Permissions
            }
            
            # Ajouter les nouvelles permissions personnalisées
            $Permissions += $CustomPermissions
            
            # Supprimer les doublons
            $User.Permissions = $Permissions | Select-Object -Unique
        }
        
        if ($null -ne $Enabled) {
            $User.Enabled = $Enabled
        }
        
        if ($null -ne $RequireMFA) {
            $User.RequireMFA = $RequireMFA
        }
        
        # Mettre à jour la date de dernière modification
        $User.LastModified = Get-Date
        
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = Join-Path -Path ".\users" -ChildPath "$($User.UserId).json"
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        $OutputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }
        
        # Sauvegarder l'utilisateur
        $UserJson = $User | ConvertTo-Json
        $UserJson | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Host "Utilisateur mis à jour: $OutputPath" -ForegroundColor Green
        
        # Journaliser l'action
        Add-SecurityAuditLog -Action "UserUpdated" -UserId $env:USERNAME -TargetId $User.UserId -Details "Utilisateur mis à jour"
        
        return $User
    } catch {
        Write-Error "Échec de la mise à jour de l'utilisateur: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour vérifier les permissions d'un utilisateur
function Test-UserPermission {
    <#
    .SYNOPSIS
        Vérifie si un utilisateur a une permission spécifique.

    .DESCRIPTION
        Cette fonction vérifie si un utilisateur a une permission spécifique
        en fonction de ses rôles et permissions personnalisées.

    .PARAMETER User
        L'objet utilisateur à vérifier.

    .PARAMETER Permission
        La permission à vérifier.

    .PARAMETER LogAccess
        Indique si l'accès doit être journalisé.

    .EXAMPLE
        $user = Get-RoadmapUser -UserId "john.doe"
        Test-UserPermission -User $user -Permission "roadmap:read" -LogAccess
        Vérifie si l'utilisateur john.doe a la permission de lecture des roadmaps.

    .OUTPUTS
        Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$User,

        [Parameter(Mandatory = $true)]
        [string]$Permission,

        [Parameter(Mandatory = $false)]
        [switch]$LogAccess
    )

    try {
        # Vérifier si l'utilisateur est activé
        if (-not $User.Enabled) {
            if ($LogAccess) {
                Add-SecurityAuditLog -Action "AccessDenied" -UserId $User.UserId -TargetId $Permission -Details "Utilisateur désactivé"
            }
            return $false
        }
        
        # Vérifier si l'utilisateur a la permission
        $HasPermission = $User.Permissions -contains $Permission
        
        # Journaliser l'accès si demandé
        if ($LogAccess) {
            if ($HasPermission) {
                Add-SecurityAuditLog -Action "AccessGranted" -UserId $User.UserId -TargetId $Permission -Details "Permission accordée"
            } else {
                Add-SecurityAuditLog -Action "AccessDenied" -UserId $User.UserId -TargetId $Permission -Details "Permission refusée"
            }
        }
        
        return $HasPermission
    } catch {
        Write-Error "Échec de la vérification de la permission: $($_.Exception.Message)"
        return $false
    }
}

# Fonction pour ajouter une entrée au journal d'audit de sécurité
function Add-SecurityAuditLog {
    <#
    .SYNOPSIS
        Ajoute une entrée au journal d'audit de sécurité.

    .DESCRIPTION
        Cette fonction ajoute une entrée au journal d'audit de sécurité
        pour suivre les actions des utilisateurs et les événements de sécurité.

    .PARAMETER Action
        L'action effectuée.

    .PARAMETER UserId
        L'identifiant de l'utilisateur qui a effectué l'action.

    .PARAMETER TargetId
        L'identifiant de la cible de l'action.

    .PARAMETER Details
        Les détails de l'action.

    .PARAMETER Severity
        La gravité de l'événement (Info, Warning, Error).

    .PARAMETER LogPath
        Le chemin vers le fichier de journal.
        Si non spécifié, le chemin par défaut est utilisé.

    .EXAMPLE
        Add-SecurityAuditLog -Action "Login" -UserId "john.doe" -Details "Connexion réussie" -Severity "Info"
        Ajoute une entrée de journal pour une connexion réussie.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Action,

        [Parameter(Mandatory = $false)]
        [string]$UserId = $env:USERNAME,

        [Parameter(Mandatory = $false)]
        [string]$TargetId = "",

        [Parameter(Mandatory = $false)]
        [string]$Details = "",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Severity = "Info",

        [Parameter(Mandatory = $false)]
        [string]$LogPath = ".\logs\security-audit.json"
    )

    try {
        # Créer l'entrée de journal
        $LogEntry = [PSCustomObject]@{
            Timestamp = Get-Date -Format "o"
            Action = $Action
            UserId = $UserId
            TargetId = $TargetId
            Details = $Details
            Severity = $Severity
            IPAddress = [string](Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch "Loopback" } | Select-Object -First 1 -ExpandProperty IPAddress)
            Hostname = [System.Net.Dns]::GetHostName()
            ProcessId = $PID
        }
        
        # Créer le dossier de journal s'il n'existe pas
        $LogDir = Split-Path -Parent $LogPath
        if (-not (Test-Path $LogDir)) {
            New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
        }
        
        # Convertir l'entrée en JSON
        $LogEntryJson = $LogEntry | ConvertTo-Json -Compress
        
        # Ajouter l'entrée au fichier de journal
        $LogEntryJson | Out-File -FilePath $LogPath -Encoding UTF8 -Append
        
        return $LogEntry
    } catch {
        Write-Error "Échec de l'ajout de l'entrée au journal d'audit: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour exporter le journal d'audit de sécurité
function Export-SecurityAuditLog {
    <#
    .SYNOPSIS
        Exporte le journal d'audit de sécurité.

    .DESCRIPTION
        Cette fonction exporte le journal d'audit de sécurité dans différents formats.

    .PARAMETER LogPath
        Le chemin vers le fichier de journal.

    .PARAMETER OutputPath
        Le chemin où sauvegarder le journal exporté.

    .PARAMETER Format
        Le format d'exportation (CSV, HTML, XML).

    .PARAMETER StartDate
        La date de début pour filtrer les entrées.

    .PARAMETER EndDate
        La date de fin pour filtrer les entrées.

    .PARAMETER UserId
        L'identifiant de l'utilisateur pour filtrer les entrées.

    .PARAMETER Action
        L'action pour filtrer les entrées.

    .PARAMETER Severity
        La gravité pour filtrer les entrées.

    .EXAMPLE
        Export-SecurityAuditLog -LogPath ".\logs\security-audit.json" -OutputPath ".\logs\security-audit.csv" -Format "CSV" -StartDate (Get-Date).AddDays(-7)
        Exporte le journal d'audit de sécurité des 7 derniers jours au format CSV.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$LogPath = ".\logs\security-audit.json",

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("CSV", "HTML", "XML")]
        [string]$Format = "CSV",

        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate,

        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate,

        [Parameter(Mandatory = $false)]
        [string]$UserId,

        [Parameter(Mandatory = $false)]
        [string]$Action,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Severity
    )

    try {
        # Vérifier que le fichier de journal existe
        if (-not (Test-Path $LogPath)) {
            Write-Error "Le fichier de journal n'existe pas: $LogPath"
            return $null
        }
        
        # Lire le fichier de journal
        $LogEntries = @()
        Get-Content -Path $LogPath -Encoding UTF8 | ForEach-Object {
            if (-not [string]::IsNullOrEmpty($_)) {
                $LogEntries += $_ | ConvertFrom-Json
            }
        }
        
        # Filtrer les entrées
        if ($null -ne $StartDate) {
            $LogEntries = $LogEntries | Where-Object { [DateTime]::Parse($_.Timestamp) -ge $StartDate }
        }
        
        if ($null -ne $EndDate) {
            $LogEntries = $LogEntries | Where-Object { [DateTime]::Parse($_.Timestamp) -le $EndDate }
        }
        
        if (-not [string]::IsNullOrEmpty($UserId)) {
            $LogEntries = $LogEntries | Where-Object { $_.UserId -eq $UserId }
        }
        
        if (-not [string]::IsNullOrEmpty($Action)) {
            $LogEntries = $LogEntries | Where-Object { $_.Action -eq $Action }
        }
        
        if (-not [string]::IsNullOrEmpty($Severity)) {
            $LogEntries = $LogEntries | Where-Object { $_.Severity -eq $Severity }
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        $OutputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }
        
        # Exporter les entrées dans le format spécifié
        switch ($Format) {
            "CSV" {
                $LogEntries | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            }
            "HTML" {
                $HtmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Journal d'audit de sécurité</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .info { color: black; }
        .warning { color: orange; }
        .error { color: red; }
    </style>
</head>
<body>
    <h1>Journal d'audit de sécurité</h1>
    <p>Exporté le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    <table>
        <tr>
            <th>Horodatage</th>
            <th>Action</th>
            <th>Utilisateur</th>
            <th>Cible</th>
            <th>Détails</th>
            <th>Gravité</th>
            <th>Adresse IP</th>
            <th>Nom d'hôte</th>
        </tr>
"@
                
                $HtmlRows = $LogEntries | ForEach-Object {
                    $SeverityClass = $_.Severity.ToLower()
                    "<tr class='$SeverityClass'><td>$($_.Timestamp)</td><td>$($_.Action)</td><td>$($_.UserId)</td><td>$($_.TargetId)</td><td>$($_.Details)</td><td>$($_.Severity)</td><td>$($_.IPAddress)</td><td>$($_.Hostname)</td></tr>"
                }
                
                $HtmlFooter = @"
    </table>
</body>
</html>
"@
                
                $HtmlContent = $HtmlHeader + ($HtmlRows -join "`n") + $HtmlFooter
                $HtmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            "XML" {
                $XmlHeader = @"
<?xml version="1.0" encoding="UTF-8"?>
<SecurityAuditLog>
"@
                
                $XmlRows = $LogEntries | ForEach-Object {
                    @"
    <LogEntry>
        <Timestamp>$($_.Timestamp)</Timestamp>
        <Action>$($_.Action)</Action>
        <UserId>$($_.UserId)</UserId>
        <TargetId>$($_.TargetId)</TargetId>
        <Details>$($_.Details)</Details>
        <Severity>$($_.Severity)</Severity>
        <IPAddress>$($_.IPAddress)</IPAddress>
        <Hostname>$($_.Hostname)</Hostname>
        <ProcessId>$($_.ProcessId)</ProcessId>
    </LogEntry>
"@
                }
                
                $XmlFooter = @"
</SecurityAuditLog>
"@
                
                $XmlContent = $XmlHeader + ($XmlRows -join "`n") + $XmlFooter
                $XmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
            }
        }
        
        Write-Host "Journal d'audit de sécurité exporté: $OutputPath" -ForegroundColor Green
        
        # Journaliser l'action
        Add-SecurityAuditLog -Action "AuditLogExported" -UserId $env:USERNAME -Details "Journal d'audit de sécurité exporté au format $Format"
        
        # Créer l'objet de résultat
        $Result = [PSCustomObject]@{
            LogPath = $LogPath
            OutputPath = $OutputPath
            Format = $Format
            EntriesCount = $LogEntries.Count
            StartDate = $StartDate
            EndDate = $EndDate
            ExportDate = Get-Date
        }
        
        return $Result
    } catch {
        Write-Error "Échec de l'exportation du journal d'audit de sécurité: $($_.Exception.Message)"
        return $null
    }
}
