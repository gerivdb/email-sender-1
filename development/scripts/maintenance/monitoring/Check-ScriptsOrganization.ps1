#Requires -Version 5.1
<#
.SYNOPSIS
    Vérifie l'organisation des scripts dans le dossier maintenance.
.DESCRIPTION
    Ce script vérifie si des scripts PowerShell se trouvent à la racine du dossier maintenance
    et génère un rapport sur l'organisation des scripts.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de sortie.
.PARAMETER SendEmail
    Envoie un email en cas de problème d'organisation.
.EXAMPLE
    .\Check-ScriptsOrganization.ps1 -OutputPath ".\reports\organization"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-10
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\organization",
    
    [Parameter(Mandatory = $false)]
    [switch]$SendEmail
)

# Fonction pour écrire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
    
    # Ajouter au fichier de log
    $logFilePath = Join-Path -Path $OutputPath -ChildPath "organization_check.log"
    Add-Content -Path $logFilePath -Value $logMessage -Encoding UTF8
}

# Fonction pour envoyer un email
function Send-OrganizationAlert {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Subject,
        
        [Parameter(Mandatory = $true)]
        [string]$Body
    )
    
    # Cette fonction est un placeholder pour l'envoi d'email
    # Vous devrez l'adapter à votre système d'envoi d'email
    
    Write-Log "Alerte envoyée: $Subject" -Level "WARNING"
    Write-Log "Corps de l'alerte: $Body" -Level "INFO"
}

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de sortie créé: $OutputPath" -Level "INFO"
}

# Chemin du dossier maintenance
$maintenanceDir = $PSScriptRoot | Split-Path -Parent
Write-Log "Vérification de l'organisation des scripts dans: $maintenanceDir" -Level "INFO"

# Récupérer tous les fichiers PowerShell à la racine du dossier maintenance
$rootFiles = Get-ChildItem -Path $maintenanceDir -File | Where-Object { 
    $_.Extension -in '.ps1', '.psm1', '.psd1' -and 
    $_.Name -ne 'Initialize-MaintenanceEnvironment.ps1' -and
    $_.Name -ne 'README.md'
}

# Récupérer tous les sous-dossiers
$subDirs = Get-ChildItem -Path $maintenanceDir -Directory | Select-Object -ExpandProperty Name

# Récupérer tous les fichiers PowerShell dans les sous-dossiers
$subDirFiles = Get-ChildItem -Path $maintenanceDir -Recurse -File | Where-Object { 
    $_.Extension -in '.ps1', '.psm1', '.psd1' -and 
    $_.DirectoryName -ne $maintenanceDir
}

# Générer le rapport
$reportPath = Join-Path -Path $OutputPath -ChildPath "organization_report_$(Get-Date -Format 'yyyyMMdd').json"
$report = @{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    MaintenanceDir = $maintenanceDir
    RootFilesCount = $rootFiles.Count
    SubDirsCount = $subDirs.Count
    SubDirFilesCount = $subDirFiles.Count
    OrganizationStatus = if ($rootFiles.Count -eq 0) { "OK" } else { "PROBLÈME" }
    RootFiles = $rootFiles | Select-Object Name, LastWriteTime, Length
    SubDirs = $subDirs
    FilesPerSubDir = $subDirFiles | Group-Object { Split-Path -Leaf (Split-Path -Parent $_.FullName) } | 
                     Select-Object Name, Count, @{Name="Files"; Expression={$_.Group.Name}}
}

# Enregistrer le rapport
$report | ConvertTo-Json -Depth 4 | Out-File -FilePath $reportPath -Encoding utf8
Write-Log "Rapport généré: $reportPath" -Level "SUCCESS"

# Afficher un résumé
Write-Log "`nRésumé de l'organisation:" -Level "INFO"
Write-Log "  Fichiers à la racine: $($rootFiles.Count)" -Level $(if ($rootFiles.Count -eq 0) { "SUCCESS" } else { "ERROR" })
Write-Log "  Sous-dossiers: $($subDirs.Count)" -Level "INFO"
Write-Log "  Fichiers dans les sous-dossiers: $($subDirFiles.Count)" -Level "INFO"

# Afficher les fichiers à la racine s'il y en a
if ($rootFiles.Count -gt 0) {
    Write-Log "`nFichiers à déplacer:" -Level "ERROR"
    foreach ($file in $rootFiles) {
        Write-Log "  $($file.Name)" -Level "WARNING"
    }
    
    Write-Log "`nUtilisez le script d'organisation pour déplacer ces fichiers:" -Level "INFO"
    Write-Log "  .\organize\Organize-MaintenanceScripts.ps1 -Force" -Level "INFO"
    
    # Envoyer une alerte par email si demandé
    if ($SendEmail) {
        $subject = "ALERTE: $($rootFiles.Count) scripts non organisés dans le dossier maintenance"
        $body = "Les scripts suivants se trouvent à la racine du dossier maintenance et doivent être organisés:`n`n"
        foreach ($file in $rootFiles) {
            $body += "- $($file.Name)`n"
        }
        $body += "`nUtilisez le script d'organisation pour déplacer ces fichiers:`n"
        $body += ".\organize\Organize-MaintenanceScripts.ps1 -Force"
        
        Send-OrganizationAlert -Subject $subject -Body $body
    }
}
else {
    Write-Log "`nTous les scripts sont correctement organisés." -Level "SUCCESS"
}

# Afficher la répartition des fichiers par sous-dossier
Write-Log "`nRépartition des fichiers par sous-dossier:" -Level "INFO"
foreach ($dir in $report.FilesPerSubDir | Sort-Object Count -Descending) {
    Write-Log "  $($dir.Name): $($dir.Count) fichier(s)" -Level "INFO"
}

Write-Log "`nVérification terminée." -Level "SUCCESS"
