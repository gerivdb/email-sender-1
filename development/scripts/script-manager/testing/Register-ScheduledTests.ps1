#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre les tests du script manager comme tÃ¢che planifiÃ©e.
.DESCRIPTION
    Ce script enregistre les tests du script manager comme tÃ¢che planifiÃ©e
    pour une exÃ©cution automatique pÃ©riodique.
.PARAMETER TaskName
    Nom de la tÃ¢che planifiÃ©e.
.PARAMETER Schedule
    Planification de la tÃ¢che (Daily, Weekly, Monthly).
.PARAMETER Time
    Heure d'exÃ©cution de la tÃ¢che (format HH:mm).
.PARAMETER DayOfWeek
    Jour de la semaine pour une planification hebdomadaire.
.PARAMETER DayOfMonth
    Jour du mois pour une planification mensuelle.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de tests.
.PARAMETER SendEmail
    Envoie un e-mail avec les rÃ©sultats des tests.
.PARAMETER EmailTo
    Adresse e-mail du destinataire.
.PARAMETER EmailFrom
    Adresse e-mail de l'expÃ©diteur.
.PARAMETER SmtpServer
    Serveur SMTP pour l'envoi d'e-mails.
.EXAMPLE
    .\Register-ScheduledTests.ps1 -TaskName "TestsQuotidiens" -Schedule Daily -Time "22:00" -OutputPath "D:\Reports\Tests"
.EXAMPLE
    .\Register-ScheduledTests.ps1 -TaskName "TestsHebdomadaires" -Schedule Weekly -Time "22:00" -DayOfWeek Monday -OutputPath "D:\Reports\Tests" -SendEmail -EmailTo "admin@example.com" -EmailFrom "tests@example.com" -SmtpServer "smtp.example.com"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
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
}

# VÃ©rifier si le module ScheduledTasks est disponible
if (-not (Get-Module -Name ScheduledTasks -ListAvailable)) {
    Write-Log "Le module ScheduledTasks n'est pas disponible. Installation en cours..." -Level "WARNING"
    
    # VÃ©rifier si le script est exÃ©cutÃ© en tant qu'administrateur
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Log "Ce script doit Ãªtre exÃ©cutÃ© en tant qu'administrateur pour installer le module ScheduledTasks." -Level "ERROR"
        exit 1
    }
    
    try {
        Install-Module -Name ScheduledTasks -Force -Scope AllUsers
        Write-Log "Module ScheduledTasks installÃ© avec succÃ¨s." -Level "SUCCESS"
    }
    catch {
        Write-Log "Erreur lors de l'installation du module ScheduledTasks: $_" -Level "ERROR"
        exit 1
    }
}

# Importer le module ScheduledTasks
Import-Module ScheduledTasks

# VÃ©rifier si le dossier de sortie existe
if (-not (Test-Path -Path $OutputPath)) {
    if ($PSCmdlet.ShouldProcess($OutputPath, "CrÃ©er le dossier de sortie")) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-Log "Dossier de sortie crÃ©Ã©: $OutputPath" -Level "SUCCESS"
    }
}

# CrÃ©er le script d'exÃ©cution des tests
$scriptPath = Join-Path -Path $OutputPath -ChildPath "Run-ScheduledTests.ps1"
$scriptContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute les tests du script manager et envoie un rapport par e-mail.
.DESCRIPTION
    Ce script exÃ©cute les tests du script manager et envoie un rapport par e-mail.
    Il est conÃ§u pour Ãªtre exÃ©cutÃ© comme une tÃ¢che planifiÃ©e.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
#>

[CmdletBinding()]
param ()

# Fonction pour Ã©crire dans le journal
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

# CrÃ©er le dossier de sortie s'il n'existe pas
`$outputPath = "$OutputPath"
if (-not (Test-Path -Path `$outputPath)) {
    New-Item -Path `$outputPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de sortie crÃ©Ã©: `$outputPath" -Level "INFO"
}

# ExÃ©cuter les tests
Write-Log "ExÃ©cution des tests..." -Level "INFO"

try {
    # ExÃ©cuter les tests simplifiÃ©s
    `$simplifiedTestsPath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\development\\scripts\\mode-manager\testing\Run-SimplifiedTests.ps1"
    `$simplifiedOutputPath = Join-Path -Path `$outputPath -ChildPath "simplified"
    
    if (-not (Test-Path -Path `$simplifiedOutputPath)) {
        New-Item -Path `$simplifiedOutputPath -ItemType Directory -Force | Out-Null
    }
    
    Write-Log "ExÃ©cution des tests simplifiÃ©s..." -Level "INFO"
    & `$simplifiedTestsPath -OutputPath `$simplifiedOutputPath -GenerateHTML
    
    # ExÃ©cuter les tests corrigÃ©s
    `$fixedTestsPath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\development\\scripts\\mode-manager\testing\Run-FixedTests.ps1"
    `$fixedOutputPath = Join-Path -Path `$outputPath -ChildPath "fixed"
    
    if (-not (Test-Path -Path `$fixedOutputPath)) {
        New-Item -Path `$fixedOutputPath -ItemType Directory -Force | Out-Null
    }
    
    Write-Log "ExÃ©cution des tests corrigÃ©s..." -Level "INFO"
    & `$fixedTestsPath -OutputPath `$fixedOutputPath -GenerateHTML
    
    # GÃ©nÃ©rer la documentation des tests
    `$documentationPath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\development\\scripts\\mode-manager\testing\Generate-TestDocumentation.ps1"
    `$documentationOutputPath = Join-Path -Path `$outputPath -ChildPath "documentation"
    
    if (-not (Test-Path -Path `$documentationOutputPath)) {
        New-Item -Path `$documentationOutputPath -ItemType Directory -Force | Out-Null
    }
    
    Write-Log "GÃ©nÃ©ration de la documentation des tests..." -Level "INFO"
    & `$documentationPath -OutputPath `$documentationOutputPath
    
    Write-Log "Tests exÃ©cutÃ©s avec succÃ¨s." -Level "SUCCESS"
}
catch {
    Write-Log "Erreur lors de l'exÃ©cution des tests: `$_" -Level "ERROR"
}

# Envoyer un e-mail avec les rÃ©sultats des tests
if (`$SendEmail) {
    Write-Log "Envoi d'un e-mail avec les rÃ©sultats des tests..." -Level "INFO"
    
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
    <p>GÃ©nÃ©rÃ© le `$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    
    <h2>RÃ©sultats des tests</h2>
    <p>Les rÃ©sultats dÃ©taillÃ©s des tests sont disponibles dans les piÃ¨ces jointes.</p>
    
    <p>Cordialement,<br>
    L'Ã©quipe EMAIL_SENDER_1</p>
</body>
</html>
"@
        
        `$attachments = @(
            (Join-Path -Path `$simplifiedOutputPath -ChildPath "SimplifiedTestResults.html"),
            (Join-Path -Path `$fixedOutputPath -ChildPath "FixedTestResults.html"),
            (Join-Path -Path `$documentationOutputPath -ChildPath "TestDocumentation.html")
        )
        
        Send-MailMessage -To `$emailTo -From `$emailFrom -Subject `$subject -Body `$body -BodyAsHtml -SmtpServer `$smtpServer -Attachments `$attachments
        
        Write-Log "E-mail envoyÃ© avec succÃ¨s." -Level "SUCCESS"
    }
    catch {
        Write-Log "Erreur lors de l'envoi de l'e-mail: `$_" -Level "ERROR"
    }
}

Write-Log "ExÃ©cution des tests planifiÃ©s terminÃ©e." -Level "INFO"
"@

if ($PSCmdlet.ShouldProcess($scriptPath, "CrÃ©er le script d'exÃ©cution des tests")) {
    $scriptContent | Out-File -FilePath $scriptPath -Encoding utf8
    Write-Log "Script d'exÃ©cution des tests crÃ©Ã©: $scriptPath" -Level "SUCCESS"
}

# CrÃ©er la tÃ¢che planifiÃ©e
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

# DÃ©finir le dÃ©clencheur en fonction de la planification
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

# DÃ©finir les paramÃ¨tres de la tÃ¢che
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew

# CrÃ©er la tÃ¢che planifiÃ©e
if ($PSCmdlet.ShouldProcess($TaskName, "CrÃ©er la tÃ¢che planifiÃ©e")) {
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    
    if ($existingTask) {
        # Mettre Ã  jour la tÃ¢che existante
        Set-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal
        Write-Log "TÃ¢che planifiÃ©e mise Ã  jour: $TaskName" -Level "SUCCESS"
    }
    else {
        # CrÃ©er une nouvelle tÃ¢che
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal
        Write-Log "TÃ¢che planifiÃ©e crÃ©Ã©e: $TaskName" -Level "SUCCESS"
    }
}

# Afficher un rÃ©sumÃ©
Write-Log "`nRÃ©sumÃ© de la tÃ¢che planifiÃ©e:" -Level "INFO"
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
    Write-Log "  ExpÃ©diteur: $EmailFrom" -Level "INFO"
    Write-Log "  Serveur SMTP: $SmtpServer" -Level "INFO"
}
else {
    Write-Log "  Envoi d'e-mail: Non" -Level "INFO"
}

Write-Log "`nLa tÃ¢che planifiÃ©e a Ã©tÃ© crÃ©Ã©e avec succÃ¨s." -Level "SUCCESS"
Write-Log "Les tests seront exÃ©cutÃ©s automatiquement selon la planification dÃ©finie." -Level "INFO"
Write-Log "Les rÃ©sultats des tests seront enregistrÃ©s dans le dossier: $OutputPath" -Level "INFO"

if ($SendEmail) {
    Write-Log "Un e-mail avec les rÃ©sultats des tests sera envoyÃ© Ã : $EmailTo" -Level "INFO"
}

