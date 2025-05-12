# Ensure-GDPRCompliance.ps1
# Module pour la conformité RGPD et l'anonymisation des données
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Fournit des fonctions pour la conformité RGPD et l'anonymisation des données.

.DESCRIPTION
    Ce module fournit des fonctions pour la conformité RGPD et l'anonymisation des données,
    notamment la gestion des consentements, l'anonymisation des données personnelles et la gestion des demandes d'accès.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
Add-Type -AssemblyName System.Security
Add-Type -AssemblyName System.Web

# Fonction pour enregistrer le consentement d'un utilisateur
function Register-UserConsent {
    <#
    .SYNOPSIS
        Enregistre le consentement d'un utilisateur pour le traitement de ses données.

    .DESCRIPTION
        Cette fonction enregistre le consentement d'un utilisateur pour le traitement de ses données
        conformément au Règlement Général sur la Protection des Données (RGPD).

    .PARAMETER UserId
        L'identifiant de l'utilisateur.

    .PARAMETER ConsentType
        Le type de consentement (Cookies, Marketing, Analytics, etc.).

    .PARAMETER ConsentValue
        La valeur du consentement (Granted, Denied, Withdrawn).

    .PARAMETER ExpiryDate
        La date d'expiration du consentement.
        Si non spécifiée, le consentement n'expire pas.

    .PARAMETER Details
        Les détails supplémentaires sur le consentement.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les informations de consentement.
        Si non spécifié, le chemin par défaut est utilisé.

    .EXAMPLE
        Register-UserConsent -UserId "john.doe" -ConsentType "Analytics" -ConsentValue "Granted" -ExpiryDate (Get-Date).AddYears(1) -Details "Consentement pour l'analyse des données d'utilisation"
        Enregistre le consentement de l'utilisateur pour l'analyse des données.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserId,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Cookies", "Marketing", "Analytics", "DataProcessing", "ThirdPartySharing", "All")]
        [string]$ConsentType,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Granted", "Denied", "Withdrawn")]
        [string]$ConsentValue,

        [Parameter(Mandatory = $false)]
        [DateTime]$ExpiryDate,

        [Parameter(Mandatory = $false)]
        [string]$Details = "",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )

    try {
        # Créer l'objet de consentement
        $Consent = [PSCustomObject]@{
            UserId = $UserId
            ConsentType = $ConsentType
            ConsentValue = $ConsentValue
            GrantDate = Get-Date
            ExpiryDate = $ExpiryDate
            Details = $Details
            IPAddress = [string](Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch "Loopback" } | Select-Object -First 1 -ExpandProperty IPAddress)
            UserAgent = "PowerShell/$($PSVersionTable.PSVersion)"
        }
        
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = ".\consents\$UserId-$ConsentType.json"
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        $OutputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }
        
        # Sauvegarder le consentement
        $ConsentJson = $Consent | ConvertTo-Json
        $ConsentJson | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Host "Consentement enregistré: $OutputPath" -ForegroundColor Green
        
        # Journaliser l'action
        Add-SecurityAuditLog -Action "ConsentRegistered" -UserId $UserId -TargetId $ConsentType -Details "Consentement $ConsentValue pour $ConsentType"
        
        return $Consent
    } catch {
        Write-Error "Échec de l'enregistrement du consentement: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour vérifier le consentement d'un utilisateur
function Test-UserConsent {
    <#
    .SYNOPSIS
        Vérifie le consentement d'un utilisateur pour le traitement de ses données.

    .DESCRIPTION
        Cette fonction vérifie si un utilisateur a donné son consentement pour le traitement de ses données
        conformément au Règlement Général sur la Protection des Données (RGPD).

    .PARAMETER UserId
        L'identifiant de l'utilisateur.

    .PARAMETER ConsentType
        Le type de consentement à vérifier.

    .PARAMETER ConsentPath
        Le chemin vers le fichier de consentement.
        Si non spécifié, le chemin par défaut est utilisé.

    .EXAMPLE
        Test-UserConsent -UserId "john.doe" -ConsentType "Analytics"
        Vérifie si l'utilisateur a donné son consentement pour l'analyse des données.

    .OUTPUTS
        Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserId,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Cookies", "Marketing", "Analytics", "DataProcessing", "ThirdPartySharing", "All")]
        [string]$ConsentType,

        [Parameter(Mandatory = $false)]
        [string]$ConsentPath = ""
    )

    try {
        # Déterminer le chemin du fichier de consentement
        if ([string]::IsNullOrEmpty($ConsentPath)) {
            $ConsentPath = ".\consents\$UserId-$ConsentType.json"
        }
        
        # Vérifier si le fichier de consentement existe
        if (-not (Test-Path $ConsentPath)) {
            # Vérifier si le consentement "All" existe
            if ($ConsentType -ne "All") {
                $AllConsentPath = ".\consents\$UserId-All.json"
                if (Test-Path $AllConsentPath) {
                    $ConsentPath = $AllConsentPath
                } else {
                    return $false
                }
            } else {
                return $false
            }
        }
        
        # Charger le consentement
        $Consent = Get-Content -Path $ConsentPath -Raw | ConvertFrom-Json
        
        # Vérifier si le consentement est valide
        if ($Consent.ConsentValue -ne "Granted") {
            return $false
        }
        
        # Vérifier si le consentement a expiré
        if ($null -ne $Consent.ExpiryDate -and [DateTime]::Parse($Consent.ExpiryDate) -lt (Get-Date)) {
            return $false
        }
        
        return $true
    } catch {
        Write-Error "Échec de la vérification du consentement: $($_.Exception.Message)"
        return $false
    }
}

# Fonction pour anonymiser les données personnelles
function Invoke-DataAnonymization {
    <#
    .SYNOPSIS
        Anonymise les données personnelles dans un fichier.

    .DESCRIPTION
        Cette fonction anonymise les données personnelles dans un fichier
        conformément au Règlement Général sur la Protection des Données (RGPD).

    .PARAMETER FilePath
        Le chemin vers le fichier à anonymiser.

    .PARAMETER OutputPath
        Le chemin où sauvegarder le fichier anonymisé.
        Si non spécifié, le fichier d'entrée est remplacé.

    .PARAMETER DataTypes
        Les types de données à anonymiser (Email, Name, Phone, Address, IP, All).

    .PARAMETER PreserveFormat
        Indique si le format des données doit être préservé.

    .PARAMETER BackupOriginal
        Indique si une sauvegarde du fichier original doit être créée.

    .EXAMPLE
        Invoke-DataAnonymization -FilePath "C:\Data\users.json" -OutputPath "C:\Data\users-anonymized.json" -DataTypes @("Email", "Name", "Phone") -PreserveFormat -BackupOriginal
        Anonymise les adresses e-mail, noms et numéros de téléphone dans un fichier JSON.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Email", "Name", "Phone", "Address", "IP", "All")]
        [string[]]$DataTypes = @("All"),

        [Parameter(Mandatory = $false)]
        [switch]$PreserveFormat,

        [Parameter(Mandatory = $false)]
        [switch]$BackupOriginal
    )

    try {
        # Vérifier que le fichier existe
        if (-not (Test-Path $FilePath)) {
            Write-Error "Le fichier n'existe pas: $FilePath"
            return $null
        }
        
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = $FilePath
        }
        
        # Créer une sauvegarde si demandé
        if ($BackupOriginal) {
            $BackupPath = "$FilePath.bak"
            Copy-Item -Path $FilePath -Destination $BackupPath -Force
            Write-Host "Sauvegarde créée: $BackupPath" -ForegroundColor Green
        }
        
        # Lire le contenu du fichier
        $Content = Get-Content -Path $FilePath -Raw
        
        # Définir les expressions régulières pour chaque type de données
        $Patterns = @{
            "Email" = '([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
            "Name" = '([A-Z][a-z]+\s+[A-Z][a-z]+)'
            "Phone" = '(\+?\d{1,3}[\s-]?\(?\d{1,4}\)?[\s-]?\d{1,4}[\s-]?\d{1,9})'
            "Address" = '(\d+\s+[A-Za-z\s]+,\s+[A-Za-z\s]+,\s+[A-Z]{2}\s+\d{5})'
            "IP" = '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
        }
        
        # Anonymiser chaque type de données
        $AnonymizedContent = $Content
        $ReplacementCount = 0
        
        foreach ($DataType in $DataTypes) {
            if ($DataType -eq "All") {
                $TypesToAnonymize = $Patterns.Keys
            } else {
                $TypesToAnonymize = @($DataType)
            }
            
            foreach ($Type in $TypesToAnonymize) {
                $Pattern = $Patterns[$Type]
                
                # Trouver toutes les correspondances
                $Matches = [regex]::Matches($AnonymizedContent, $Pattern)
                
                # Anonymiser chaque correspondance
                foreach ($Match in $Matches) {
                    $Original = $Match.Value
                    $Anonymized = ""
                    
                    # Générer une valeur anonymisée en fonction du type
                    switch ($Type) {
                        "Email" {
                            if ($PreserveFormat) {
                                $Parts = $Original -split "@"
                                $Anonymized = "anonymized-$($ReplacementCount)@example.com"
                            } else {
                                $Anonymized = "anonymized-email-$($ReplacementCount)"
                            }
                        }
                        "Name" {
                            if ($PreserveFormat) {
                                $Parts = $Original -split "\s+"
                                $Anonymized = "Anonymous User-$($ReplacementCount)"
                            } else {
                                $Anonymized = "anonymous-name-$($ReplacementCount)"
                            }
                        }
                        "Phone" {
                            if ($PreserveFormat) {
                                $Anonymized = "+00-000-000-0000"
                            } else {
                                $Anonymized = "anonymous-phone-$($ReplacementCount)"
                            }
                        }
                        "Address" {
                            if ($PreserveFormat) {
                                $Anonymized = "123 Anonymous St, Anonymous City, XX 00000"
                            } else {
                                $Anonymized = "anonymous-address-$($ReplacementCount)"
                            }
                        }
                        "IP" {
                            if ($PreserveFormat) {
                                $Anonymized = "0.0.0.0"
                            } else {
                                $Anonymized = "anonymous-ip-$($ReplacementCount)"
                            }
                        }
                    }
                    
                    # Remplacer la valeur originale par la valeur anonymisée
                    $AnonymizedContent = $AnonymizedContent.Replace($Original, $Anonymized)
                    $ReplacementCount++
                }
            }
        }
        
        # Écrire le contenu anonymisé dans le fichier de sortie
        $AnonymizedContent | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Host "Données anonymisées: $OutputPath" -ForegroundColor Green
        Write-Host "Nombre de remplacements: $ReplacementCount" -ForegroundColor Green
        
        # Journaliser l'action
        Add-SecurityAuditLog -Action "DataAnonymized" -TargetId $FilePath -Details "Données anonymisées: $ReplacementCount remplacements"
        
        # Créer l'objet de résultat
        $Result = [PSCustomObject]@{
            OriginalFile = $FilePath
            AnonymizedFile = $OutputPath
            BackupFile = if ($BackupOriginal) { $BackupPath } else { $null }
            DataTypes = $DataTypes
            ReplacementCount = $ReplacementCount
            PreserveFormat = $PreserveFormat
            AnonymizationDate = Get-Date
        }
        
        return $Result
    } catch {
        Write-Error "Échec de l'anonymisation des données: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour gérer les demandes d'accès aux données
function New-DataAccessRequest {
    <#
    .SYNOPSIS
        Crée une demande d'accès aux données personnelles.

    .DESCRIPTION
        Cette fonction crée une demande d'accès aux données personnelles
        conformément au Règlement Général sur la Protection des Données (RGPD).

    .PARAMETER UserId
        L'identifiant de l'utilisateur demandant l'accès.

    .PARAMETER RequestType
        Le type de demande (Access, Rectification, Erasure, Restriction, Portability, Objection).

    .PARAMETER RequestDetails
        Les détails de la demande.

    .PARAMETER ContactEmail
        L'adresse e-mail de contact pour la demande.

    .PARAMETER OutputPath
        Le chemin où sauvegarder la demande.
        Si non spécifié, le chemin par défaut est utilisé.

    .EXAMPLE
        New-DataAccessRequest -UserId "john.doe" -RequestType "Access" -RequestDetails "Demande d'accès à toutes mes données personnelles" -ContactEmail "john.doe@example.com"
        Crée une demande d'accès aux données personnelles.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserId,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Access", "Rectification", "Erasure", "Restriction", "Portability", "Objection")]
        [string]$RequestType,

        [Parameter(Mandatory = $false)]
        [string]$RequestDetails = "",

        [Parameter(Mandatory = $true)]
        [string]$ContactEmail,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )

    try {
        # Générer un identifiant unique pour la demande
        $RequestId = [Guid]::NewGuid().ToString()
        
        # Créer l'objet de demande
        $Request = [PSCustomObject]@{
            RequestId = $RequestId
            UserId = $UserId
            RequestType = $RequestType
            RequestDetails = $RequestDetails
            ContactEmail = $ContactEmail
            RequestDate = Get-Date
            Status = "Pending"
            CompletionDate = $null
            AssignedTo = $null
            Notes = @()
        }
        
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = ".\data-requests\$RequestId.json"
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        $OutputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }
        
        # Sauvegarder la demande
        $RequestJson = $Request | ConvertTo-Json
        $RequestJson | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Host "Demande d'accès aux données créée: $OutputPath" -ForegroundColor Green
        
        # Journaliser l'action
        Add-SecurityAuditLog -Action "DataAccessRequestCreated" -UserId $UserId -TargetId $RequestId -Details "Demande d'accès aux données de type $RequestType"
        
        return $Request
    } catch {
        Write-Error "Échec de la création de la demande d'accès aux données: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour mettre à jour le statut d'une demande d'accès aux données
function Update-DataAccessRequest {
    <#
    .SYNOPSIS
        Met à jour le statut d'une demande d'accès aux données personnelles.

    .DESCRIPTION
        Cette fonction met à jour le statut d'une demande d'accès aux données personnelles
        conformément au Règlement Général sur la Protection des Données (RGPD).

    .PARAMETER RequestId
        L'identifiant de la demande à mettre à jour.

    .PARAMETER RequestPath
        Le chemin vers le fichier de demande.
        Si non spécifié, le chemin par défaut est utilisé.

    .PARAMETER Status
        Le nouveau statut de la demande (Pending, InProgress, Completed, Rejected).

    .PARAMETER AssignedTo
        La personne à qui la demande est assignée.

    .PARAMETER Note
        Une note à ajouter à la demande.

    .PARAMETER OutputPath
        Le chemin où sauvegarder la demande mise à jour.
        Si non spécifié, le fichier d'origine est mis à jour.

    .EXAMPLE
        Update-DataAccessRequest -RequestId "12345678-1234-1234-1234-123456789012" -Status "InProgress" -AssignedTo "admin" -Note "Demande en cours de traitement"
        Met à jour le statut d'une demande d'accès aux données personnelles.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [string]$RequestId,

        [Parameter(Mandatory = $true, ParameterSetName = "ByPath")]
        [string]$RequestPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Pending", "InProgress", "Completed", "Rejected")]
        [string]$Status,

        [Parameter(Mandatory = $false)]
        [string]$AssignedTo,

        [Parameter(Mandatory = $false)]
        [string]$Note,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )

    try {
        # Déterminer le chemin du fichier de demande
        if ($PSCmdlet.ParameterSetName -eq "ById") {
            $RequestPath = ".\data-requests\$RequestId.json"
        }
        
        # Vérifier que le fichier existe
        if (-not (Test-Path $RequestPath)) {
            Write-Error "Le fichier de demande n'existe pas: $RequestPath"
            return $null
        }
        
        # Charger la demande
        $Request = Get-Content -Path $RequestPath -Raw | ConvertFrom-Json
        
        # Mettre à jour les propriétés spécifiées
        if (-not [string]::IsNullOrEmpty($Status)) {
            $Request.Status = $Status
            
            # Mettre à jour la date de complétion si le statut est Completed ou Rejected
            if ($Status -eq "Completed" -or $Status -eq "Rejected") {
                $Request.CompletionDate = Get-Date
            }
        }
        
        if (-not [string]::IsNullOrEmpty($AssignedTo)) {
            $Request.AssignedTo = $AssignedTo
        }
        
        if (-not [string]::IsNullOrEmpty($Note)) {
            # Ajouter la note avec un horodatage
            $NoteWithTimestamp = [PSCustomObject]@{
                Timestamp = Get-Date
                Author = $env:USERNAME
                Text = $Note
            }
            
            # Convertir les notes en tableau si nécessaire
            if ($null -eq $Request.Notes) {
                $Request.Notes = @()
            } elseif ($Request.Notes -isnot [array]) {
                $Request.Notes = @($Request.Notes)
            }
            
            $Request.Notes += $NoteWithTimestamp
        }
        
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = $RequestPath
        }
        
        # Sauvegarder la demande mise à jour
        $RequestJson = $Request | ConvertTo-Json -Depth 10
        $RequestJson | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Host "Demande d'accès aux données mise à jour: $OutputPath" -ForegroundColor Green
        
        # Journaliser l'action
        Add-SecurityAuditLog -Action "DataAccessRequestUpdated" -TargetId $Request.RequestId -Details "Demande d'accès aux données mise à jour: $Status"
        
        return $Request
    } catch {
        Write-Error "Échec de la mise à jour de la demande d'accès aux données: $($_.Exception.Message)"
        return $null
    }
}
