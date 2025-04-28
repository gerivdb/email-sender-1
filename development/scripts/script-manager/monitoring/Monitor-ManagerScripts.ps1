#Requires -Version 5.1
<#
.SYNOPSIS
    Surveille les scripts du manager pour détecter les problèmes.
.DESCRIPTION
    Ce script surveille les scripts du manager pour détecter les problèmes,
    tels que les scripts mal organisés, les scripts obsolètes, etc.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de surveillance.
.PARAMETER SendEmail
    Envoie un email en cas de problème détecté.
.EXAMPLE
    .\Monitor-ManagerScripts.ps1 -OutputPath ".\reports\monitoring"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\monitoring",
    
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
    $logFilePath = Join-Path -Path $OutputPath -ChildPath "monitoring.log"
    Add-Content -Path $logFilePath -Value $logMessage -Encoding UTF8
}

# Fonction pour envoyer un email
function Send-MonitoringAlert {
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

# Chemin du dossier manager
$managerDir = $PSScriptRoot | Split-Path -Parent
Write-Log "Dossier manager: $managerDir" -Level "INFO"

# Vérifier les scripts à la racine du dossier manager
$rootFiles = Get-ChildItem -Path $managerDir -File | Where-Object { 
    $_.Extension -in '.ps1', '.psm1', '.psd1' -and 
    $_.Name -ne 'Initialize-ManagerEnvironment.ps1' -and
    $_.Name -ne 'README.md'
}

if ($rootFiles.Count -gt 0) {
    Write-Log "Des scripts sont présents à la racine du dossier manager:" -Level "WARNING"
    foreach ($file in $rootFiles) {
        Write-Log "  $($file.Name)" -Level "WARNING"
    }
    
    if ($SendEmail) {
        $subject = "ALERTE: $($rootFiles.Count) scripts non organisés dans le dossier manager"
        $body = "Les scripts suivants se trouvent à la racine du dossier manager et doivent être organisés:`n`n"
        foreach ($file in $rootFiles) {
            $body += "- $($file.Name)`n"
        }
        $body += "`nUtilisez le script d'organisation pour déplacer ces fichiers:`n"
        $body += ".\development\scripts\manager\organization\Organize-ManagerScripts.ps1 -Force"
        
        Send-MonitoringAlert -Subject $subject -Body $body
    }
}
else {
    Write-Log "Aucun script n'est présent à la racine du dossier manager." -Level "SUCCESS"
}

# Vérifier les sous-dossiers vides
$emptyDirs = Get-ChildItem -Path $managerDir -Directory | Where-Object { 
    (Get-ChildItem -Path $_.FullName -Recurse -File).Count -eq 0
}

if ($emptyDirs.Count -gt 0) {
    Write-Log "Des sous-dossiers sont vides:" -Level "WARNING"
    foreach ($dir in $emptyDirs) {
        Write-Log "  $($dir.Name)" -Level "WARNING"
    }
    
    if ($SendEmail) {
        $subject = "ALERTE: $($emptyDirs.Count) sous-dossiers vides dans le dossier manager"
        $body = "Les sous-dossiers suivants sont vides:`n`n"
        foreach ($dir in $emptyDirs) {
            $body += "- $($dir.Name)`n"
        }
        
        Send-MonitoringAlert -Subject $subject -Body $body
    }
}
else {
    Write-Log "Aucun sous-dossier n'est vide." -Level "SUCCESS"
}

# Vérifier les scripts obsolètes (non modifiés depuis plus de 6 mois)
$oldFiles = Get-ChildItem -Path $managerDir -Recurse -File | Where-Object { 
    $_.Extension -in '.ps1', '.psm1', '.psd1' -and 
    $_.LastWriteTime -lt (Get-Date).AddMonths(-6)
}

if ($oldFiles.Count -gt 0) {
    Write-Log "Des scripts sont obsolètes (non modifiés depuis plus de 6 mois):" -Level "WARNING"
    foreach ($file in $oldFiles) {
        Write-Log "  $($file.FullName) (Dernière modification: $($file.LastWriteTime))" -Level "WARNING"
    }
    
    if ($SendEmail) {
        $subject = "ALERTE: $($oldFiles.Count) scripts obsolètes dans le dossier manager"
        $body = "Les scripts suivants n'ont pas été modifiés depuis plus de 6 mois:`n`n"
        foreach ($file in $oldFiles) {
            $body += "- $($file.FullName) (Dernière modification: $($file.LastWriteTime))`n"
        }
        
        Send-MonitoringAlert -Subject $subject -Body $body
    }
}
else {
    Write-Log "Aucun script n'est obsolète." -Level "SUCCESS"
}

# Vérifier les scripts sans documentation
$undocumentedFiles = Get-ChildItem -Path $managerDir -Recurse -File | Where-Object { 
    $_.Extension -in '.ps1', '.psm1', '.psd1' -and 
    -not (Select-String -Path $_.FullName -Pattern "\.SYNOPSIS|\.DESCRIPTION" -Quiet)
}

if ($undocumentedFiles.Count -gt 0) {
    Write-Log "Des scripts sont sans documentation:" -Level "WARNING"
    foreach ($file in $undocumentedFiles) {
        Write-Log "  $($file.FullName)" -Level "WARNING"
    }
    
    if ($SendEmail) {
        $subject = "ALERTE: $($undocumentedFiles.Count) scripts sans documentation dans le dossier manager"
        $body = "Les scripts suivants n'ont pas de documentation (SYNOPSIS ou DESCRIPTION):`n`n"
        foreach ($file in $undocumentedFiles) {
            $body += "- $($file.FullName)`n"
        }
        
        Send-MonitoringAlert -Subject $subject -Body $body
    }
}
else {
    Write-Log "Tous les scripts ont une documentation." -Level "SUCCESS"
}

# Générer un rapport de surveillance
$reportPath = Join-Path -Path $OutputPath -ChildPath "monitoring_report_$(Get-Date -Format 'yyyyMMdd').json"
$report = @{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ManagerDir = $managerDir
    RootFilesCount = $rootFiles.Count
    EmptyDirsCount = $emptyDirs.Count
    OldFilesCount = $oldFiles.Count
    UndocumentedFilesCount = $undocumentedFiles.Count
    Status = if ($rootFiles.Count -eq 0 -and $emptyDirs.Count -eq 0 -and $undocumentedFiles.Count -eq 0) { "OK" } else { "PROBLÈME" }
    RootFiles = $rootFiles | Select-Object Name, LastWriteTime, Length
    EmptyDirs = $emptyDirs | Select-Object Name
    OldFiles = $oldFiles | Select-Object FullName, LastWriteTime, Length
    UndocumentedFiles = $undocumentedFiles | Select-Object FullName, LastWriteTime, Length
}

# Enregistrer le rapport
$report | ConvertTo-Json -Depth 4 | Out-File -FilePath $reportPath -Encoding utf8
Write-Log "Rapport généré: $reportPath" -Level "SUCCESS"

# Afficher un résumé
Write-Log "`nRésumé de la surveillance:" -Level "INFO"
Write-Log "  Scripts à la racine: $($rootFiles.Count)" -Level $(if ($rootFiles.Count -eq 0) { "SUCCESS" } else { "ERROR" })
Write-Log "  Sous-dossiers vides: $($emptyDirs.Count)" -Level $(if ($emptyDirs.Count -eq 0) { "SUCCESS" } else { "WARNING" })
Write-Log "  Scripts obsolètes: $($oldFiles.Count)" -Level $(if ($oldFiles.Count -eq 0) { "SUCCESS" } else { "WARNING" })
Write-Log "  Scripts sans documentation: $($undocumentedFiles.Count)" -Level $(if ($undocumentedFiles.Count -eq 0) { "SUCCESS" } else { "WARNING" })
Write-Log "  Statut global: $($report.Status)" -Level $(if ($report.Status -eq "OK") { "SUCCESS" } else { "ERROR" })

Write-Log "`nSurveillance terminée." -Level "SUCCESS"
