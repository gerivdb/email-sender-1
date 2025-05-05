#Requires -Version 5.1
<#
.SYNOPSIS
    VÃ©rifie l'organisation des scripts dans le dossier maintenance.
.DESCRIPTION
    Ce script vÃ©rifie si des scripts PowerShell se trouvent Ã  la racine du dossier maintenance
    et gÃ©nÃ¨re un rapport sur l'organisation des scripts.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de sortie.
.PARAMETER SendEmail
    Envoie un email en cas de problÃ¨me d'organisation.
.EXAMPLE
    .\Check-ScriptsOrganization.ps1 -OutputPath ".\reports\organization"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-10
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\organization",
    
    [Parameter(Mandatory = $false)]
    [switch]$SendEmail
)

# Fonction pour Ã©crire dans le journal
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
    # Vous devrez l'adapter Ã  votre systÃ¨me d'envoi d'email
    
    Write-Log "Alerte envoyÃ©e: $Subject" -Level "WARNING"
    Write-Log "Corps de l'alerte: $Body" -Level "INFO"
}

# CrÃ©er le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de sortie crÃ©Ã©: $OutputPath" -Level "INFO"
}

# Chemin du dossier maintenance
$maintenanceDir = $PSScriptRoot | Split-Path -Parent
Write-Log "VÃ©rification de l'organisation des scripts dans: $maintenanceDir" -Level "INFO"

# RÃ©cupÃ©rer tous les fichiers PowerShell Ã  la racine du dossier maintenance
$rootFiles = Get-ChildItem -Path $maintenanceDir -File | Where-Object { 
    $_.Extension -in '.ps1', '.psm1', '.psd1' -and 
    $_.Name -ne 'Initialize-MaintenanceEnvironment.ps1' -and
    $_.Name -ne 'README.md'
}

# RÃ©cupÃ©rer tous les sous-dossiers
$subDirs = Get-ChildItem -Path $maintenanceDir -Directory | Select-Object -ExpandProperty Name

# RÃ©cupÃ©rer tous les fichiers PowerShell dans les sous-dossiers
$subDirFiles = Get-ChildItem -Path $maintenanceDir -Recurse -File | Where-Object { 
    $_.Extension -in '.ps1', '.psm1', '.psd1' -and 
    $_.DirectoryName -ne $maintenanceDir
}

# GÃ©nÃ©rer le rapport
$reportPath = Join-Path -Path $OutputPath -ChildPath "organization_report_$(Get-Date -Format 'yyyyMMdd').json"
$report = @{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    MaintenanceDir = $maintenanceDir
    RootFilesCount = $rootFiles.Count
    SubDirsCount = $subDirs.Count
    SubDirFilesCount = $subDirFiles.Count
    OrganizationStatus = if ($rootFiles.Count -eq 0) { "OK" } else { "PROBLÃˆME" }
    RootFiles = $rootFiles | Select-Object Name, LastWriteTime, Length
    SubDirs = $subDirs
    FilesPerSubDir = $subDirFiles | Group-Object { Split-Path -Leaf (Split-Path -Parent $_.FullName) } | 
                     Select-Object Name, Count, @{Name="Files"; Expression={$_.Group.Name}}
}

# Enregistrer le rapport
$report | ConvertTo-Json -Depth 4 | Out-File -FilePath $reportPath -Encoding utf8
Write-Log "Rapport gÃ©nÃ©rÃ©: $reportPath" -Level "SUCCESS"

# Afficher un rÃ©sumÃ©
Write-Log "`nRÃ©sumÃ© de l'organisation:" -Level "INFO"
Write-Log "  Fichiers Ã  la racine: $($rootFiles.Count)" -Level $(if ($rootFiles.Count -eq 0) { "SUCCESS" } else { "ERROR" })
Write-Log "  Sous-dossiers: $($subDirs.Count)" -Level "INFO"
Write-Log "  Fichiers dans les sous-dossiers: $($subDirFiles.Count)" -Level "INFO"

# Afficher les fichiers Ã  la racine s'il y en a
if ($rootFiles.Count -gt 0) {
    Write-Log "`nFichiers Ã  dÃ©placer:" -Level "ERROR"
    foreach ($file in $rootFiles) {
        Write-Log "  $($file.Name)" -Level "WARNING"
    }
    
    Write-Log "`nUtilisez le script d'organisation pour dÃ©placer ces fichiers:" -Level "INFO"
    Write-Log "  .\organize\Organize-MaintenanceScripts.ps1 -Force" -Level "INFO"
    
    # Envoyer une alerte par email si demandÃ©
    if ($SendEmail) {
        $subject = "ALERTE: $($rootFiles.Count) scripts non organisÃ©s dans le dossier maintenance"
        $body = "Les scripts suivants se trouvent Ã  la racine du dossier maintenance et doivent Ãªtre organisÃ©s:`n`n"
        foreach ($file in $rootFiles) {
            $body += "- $($file.Name)`n"
        }
        $body += "`nUtilisez le script d'organisation pour dÃ©placer ces fichiers:`n"
        $body += ".\organize\Organize-MaintenanceScripts.ps1 -Force"
        
        Send-OrganizationAlert -Subject $subject -Body $body
    }
}
else {
    Write-Log "`nTous les scripts sont correctement organisÃ©s." -Level "SUCCESS"
}

# Afficher la rÃ©partition des fichiers par sous-dossier
Write-Log "`nRÃ©partition des fichiers par sous-dossier:" -Level "INFO"
foreach ($dir in $report.FilesPerSubDir | Sort-Object Count -Descending) {
    Write-Log "  $($dir.Name): $($dir.Count) fichier(s)" -Level "INFO"
}

Write-Log "`nVÃ©rification terminÃ©e." -Level "SUCCESS"
