#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre les tests du script manager comme tâche planifiée.
.DESCRIPTION
    Ce script enregistre les tests du script manager comme tâche planifiée
    pour une exécution automatique périodique.
.PARAMETER TaskName
    Nom de la tâche planifiée.
.PARAMETER Schedule
    Planification de la tâche (Daily, Weekly, Monthly).
.PARAMETER Time
    Heure d'exécution de la tâche (format HH:mm).
.PARAMETER DayOfWeek
    Jour de la semaine pour une planification hebdomadaire.
.PARAMETER DayOfMonth
    Jour du mois pour une planification mensuelle.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de tests.
.PARAMETER SendEmail
    Envoie un e-mail avec les résultats des tests.
.PARAMETER EmailTo
    Adresse e-mail du destinataire.
.PARAMETER EmailFrom
    Adresse e-mail de l'expéditeur.
.PARAMETER SmtpServer
    Serveur SMTP pour l'envoi d'e-mails.
.EXAMPLE
    .\Register-ScheduledTests.ps1 -TaskName "TestsQuotidiens" -Schedule Daily -Time "22:00" -OutputPath "D:\Reports\Tests"
.EXAMPLE
    .\Register-ScheduledTests.ps1 -TaskName "TestsHebdomadaires" -Schedule Weekly -Time "22:00" -DayOfWeek Monday -OutputPath "D:\Reports\Tests" -SendEmail -EmailTo "admin@example.com" -EmailFrom "tests@example.com" -SmtpServer "smtp.example.com"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-15
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [string]$TaskName,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("Daily", "Weekly", "Monthly")]
    [string]$Schedule,
    
    [Parameter(Mandatory = $true)]
    [string]$Time,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")]
    [string]$DayOfWeek = "Monday",
    
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 31)]
    [int]$DayOfMonth = 1,
    
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$SendEmail,
    
    [Parameter(Mandatory = $false)]
    [string]$EmailTo,
    
    [Parameter(Mandatory = $false)]
    [string]$EmailFrom,
    
    [Parameter(Mandatory = $false)]
    [string]$SmtpServer
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
}

# Vérifier si le module ScheduledTasks est disponible
if (-not (Get-Module -Name ScheduledTasks -ListAvailable)) {
    Write-Log "Le module ScheduledTasks n'est pas disponible. Installation en cours..." -Level "WARNING"
    
    # Vérifier si le script est exécuté en tant qu'administrateur
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Log "Ce script doit être exécuté en tant qu'administrateur pour installer le module ScheduledTasks." -Level "ERROR"
        exit 1
    }
    
    try {
        Install-Module -Name ScheduledTasks -Force -Scope AllUsers
        Write-Log "Module ScheduledTasks installé avec succès." -Level "SUCCESS"
    }
    catch {
        Write-Log "Erreur lors de l'installation du module ScheduledTasks: $_" -Level "ERROR"
        exit 1
    }
}

# Importer le module ScheduledTasks
Import-Module ScheduledTasks

# Vérifier si le dossier de sortie existe
if (-not (Test-Path -Path $OutputPath)) {
    if ($PSCmdlet.ShouldProcess($OutputPath, "Créer le dossier de sortie")) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-Log "Dossier de sortie créé: $OutputPath" -Level "SUCCESS"
    }
}

# Créer le script d'exécution des tests
$scriptPath = Join-Path -Path $OutputPath -ChildPath "Run-ScheduledTests.ps1"
$scriptContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute les tests du script manager et envoie un rapport par e-mail.
.DESCRIPTION
    Ce script exécute les tests du script manager et envoie un rapport par e-mail.
    Il est conçu pour être exécuté comme une tâche planifiée.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-15
#>

[CmdletBinding()]
param ()

# Fonction pour écrire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Message,
        
        [Parameter(Mandatory = `$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]`$Level = "INFO"
    )
    
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$logMessage = "[`$timestamp] [`$Level] `$Message"
    
    `$logPath = Join-Path -Path "$OutputPath" -ChildPath "ScheduledTests.log"
    "`$logMessage" | Out-File -FilePath `$logPath -Append -Encoding utf8
}

# Créer le dossier de sortie s'il n'existe pas
`$outputPath = "$OutputPath"
if (-not (Test-Path -Path `$outputPath)) {
    New-Item -Path `$outputPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de sortie créé: `$outputPath" -Level "INFO"
}

# Exécuter les tests
Write-Log "Exécution des tests..." -Level "INFO"

try {
    # Exécuter les tests simplifiés
    `$simplifiedTestsPath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\development\scripts\manager\testing\Run-SimplifiedTests.ps1"
    `$simplifiedOutputPath = Join-Path -Path `$outputPath -ChildPath "simplified"
    
    if (-not (Test-Path -Path `$simplifiedOutputPath)) {
        New-Item -Path `$simplifiedOutputPath -ItemType Directory -Force | Out-Null
    }
    
    Write-Log "Exécution des tests simplifiés..." -Level "INFO"
    & `$simplifiedTestsPath -OutputPath `$simplifiedOutputPath -GenerateHTML
    
    # Exécuter les tests corrigés
    `$fixedTestsPath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\development\scripts\manager\testing\Run-FixedTests.ps1"
    `$fixedOutputPath = Join-Path -Path `$outputPath -ChildPath "fixed"
    
    if (-not (Test-Path -Path `$fixedOutputPath)) {
        New-Item -Path `$fixedOutputPath -ItemType Directory -Force | Out-Null
    }
    
    Write-Log "Exécution des tests corrigés..." -Level "INFO"
    & `$fixedTestsPath -OutputPath `$fixedOutputPath -GenerateHTML
    
    # Générer la documentation des tests
    `$documentationPath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\development\scripts\manager\testing\Generate-TestDocumentation.ps1"
    `$documentationOutputPath = Join-Path -Path `$outputPath -ChildPath "documentation"
    
    if (-not (Test-Path -Path `$documentationOutputPath)) {
        New-Item -Path `$documentationOutputPath -ItemType Directory -Force | Out-Null
    }
    
    Write-Log "Génération de la documentation des tests..." -Level "INFO"
    & `$documentationPath -OutputPath `$documentationOutputPath
    
    Write-Log "Tests exécutés avec succès." -Level "SUCCESS"
}
catch {
    Write-Log "Erreur lors de l'exécution des tests: `$_" -Level "ERROR"
}

# Envoyer un e-mail avec les résultats des tests
if (`$SendEmail) {
    Write-Log "Envoi d'un e-mail avec les résultats des tests..." -Level "INFO"
    
    try {
        `$emailTo = "$EmailTo"
        `$emailFrom = "$EmailFrom"
        `$smtpServer = "$SmtpServer"
        
        `$subject = "Rapport de tests du script manager - `$(Get-Date -Format 'yyyy-MM-dd')"
        `$body = @"
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
    </style>
</head>
<body>
    <h1>Rapport de tests du script manager</h1>
    <p>Généré le `$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    
    <h2>Résultats des tests</h2>
    <p>Les résultats détaillés des tests sont disponibles dans les pièces jointes.</p>
    
    <p>Cordialement,<br>
    L'équipe EMAIL_SENDER_1</p>
</body>
</html>
"@
        
        `$attachments = @(
            (Join-Path -Path `$simplifiedOutputPath -ChildPath "SimplifiedTestResults.html"),
            (Join-Path -Path `$fixedOutputPath -ChildPath "FixedTestResults.html"),
            (Join-Path -Path `$documentationOutputPath -ChildPath "TestDocumentation.html")
        )
        
        Send-MailMessage -To `$emailTo -From `$emailFrom -Subject `$subject -Body `$body -BodyAsHtml -SmtpServer `$smtpServer -Attachments `$attachments
        
        Write-Log "E-mail envoyé avec succès." -Level "SUCCESS"
    }
    catch {
        Write-Log "Erreur lors de l'envoi de l'e-mail: `$_" -Level "ERROR"
    }
}

Write-Log "Exécution des tests planifiés terminée." -Level "INFO"
"@

if ($PSCmdlet.ShouldProcess($scriptPath, "Créer le script d'exécution des tests")) {
    $scriptContent | Out-File -FilePath $scriptPath -Encoding utf8
    Write-Log "Script d'exécution des tests créé: $scriptPath" -Level "SUCCESS"
}

# Créer la tâche planifiée
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

# Définir le déclencheur en fonction de la planification
switch ($Schedule) {
    "Daily" {
        $trigger = New-ScheduledTaskTrigger -Daily -At $Time
    }
    "Weekly" {
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DayOfWeek -At $Time
    }
    "Monthly" {
        $trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth $DayOfMonth -At $Time
    }
}

# Définir les paramètres de la tâche
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew

# Créer la tâche planifiée
if ($PSCmdlet.ShouldProcess($TaskName, "Créer la tâche planifiée")) {
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Vérifier si la tâche existe déjà
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    
    if ($existingTask) {
        # Mettre à jour la tâche existante
        Set-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal
        Write-Log "Tâche planifiée mise à jour: $TaskName" -Level "SUCCESS"
    }
    else {
        # Créer une nouvelle tâche
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal
        Write-Log "Tâche planifiée créée: $TaskName" -Level "SUCCESS"
    }
}

# Afficher un résumé
Write-Log "`nRésumé de la tâche planifiée:" -Level "INFO"
Write-Log "  Nom: $TaskName" -Level "INFO"
Write-Log "  Planification: $Schedule" -Level "INFO"
Write-Log "  Heure: $Time" -Level "INFO"

if ($Schedule -eq "Weekly") {
    Write-Log "  Jour de la semaine: $DayOfWeek" -Level "INFO"
}
elseif ($Schedule -eq "Monthly") {
    Write-Log "  Jour du mois: $DayOfMonth" -Level "INFO"
}

Write-Log "  Dossier de sortie: $OutputPath" -Level "INFO"

if ($SendEmail) {
    Write-Log "  Envoi d'e-mail: Oui" -Level "INFO"
    Write-Log "  Destinataire: $EmailTo" -Level "INFO"
    Write-Log "  Expéditeur: $EmailFrom" -Level "INFO"
    Write-Log "  Serveur SMTP: $SmtpServer" -Level "INFO"
}
else {
    Write-Log "  Envoi d'e-mail: Non" -Level "INFO"
}

Write-Log "`nLa tâche planifiée a été créée avec succès." -Level "SUCCESS"
Write-Log "Les tests seront exécutés automatiquement selon la planification définie." -Level "INFO"
Write-Log "Les résultats des tests seront enregistrés dans le dossier: $OutputPath" -Level "INFO"

if ($SendEmail) {
    Write-Log "Un e-mail avec les résultats des tests sera envoyé à: $EmailTo" -Level "INFO"
}
