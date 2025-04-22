# Exemples d'utilisation courants du système de remédiation n8n

Ce document présente des exemples d'utilisation courants du système de remédiation n8n, avec des instructions étape par étape et des exemples de code.

## Table des matières

1. [Installation et configuration initiale](#installation-et-configuration-initiale)
2. [Gestion quotidienne de n8n](#gestion-quotidienne-de-n8n)
3. [Importation et gestion des workflows](#importation-et-gestion-des-workflows)
4. [Surveillance et maintenance](#surveillance-et-maintenance)
5. [Automatisation des tâches](#automatisation-des-tâches)
6. [Intégration avec d'autres systèmes](#intégration-avec-dautres-systèmes)
7. [Dépannage](#dépannage)

## Installation et configuration initiale

### Exemple 1 : Installation et configuration de base

Cet exemple montre comment installer et configurer le système de remédiation n8n pour une utilisation de base.

#### Étapes

1. Clonez ou téléchargez le dépôt dans votre répertoire de travail :
   ```
   git clone https://github.com/votre-utilisateur/n8n-remediation.git
   cd n8n-remediation
   ```

2. Exécutez le script de test de structure pour vérifier l'intégrité du système :
   ```
   .\test-structure.cmd -FixIssues $true
   ```

3. Configurez les paramètres de base via l'interface n8n Manager :
   ```
   .\n8n-manager.cmd
   ```
   Sélectionnez l'option `C` pour accéder au menu de configuration.

4. Modifiez les paramètres selon vos besoins :
   - Dossier racine n8n
   - Dossier des workflows
   - Dossier de référence
   - Port par défaut
   - Protocole par défaut
   - Hôte par défaut

5. Sauvegardez la configuration en sélectionnant l'option `S`.

6. Démarrez n8n en sélectionnant l'option `1` dans le menu principal.

### Exemple 2 : Configuration avancée

Cet exemple montre comment configurer le système de remédiation n8n pour une utilisation avancée avec des paramètres personnalisés.

#### Étapes

1. Créez un fichier de configuration personnalisé :
   ```json
   {
     "N8nRootFolder": "custom/n8n",
     "WorkflowFolder": "custom/n8n/data/.n8n/workflows",
     "ReferenceFolder": "custom/n8n/core/workflows/local",
     "LogFolder": "custom/n8n/logs",
     "DefaultPort": 5679,
     "DefaultProtocol": "https",
     "DefaultHostname": "n8n.example.com",
     "AutoRestart": true,
     "NotificationEnabled": true
   }
   ```
   Enregistrez ce fichier sous `n8n/config/custom-config.json`.

2. Modifiez le script `n8n-manager.ps1` pour utiliser ce fichier de configuration :
   ```powershell
   .\n8n-manager.cmd -ConfigFile "n8n/config/custom-config.json"
   ```

3. Créez un script de raccourci personnalisé :
   ```batch
   @echo off
   echo n8n Manager (Configuration personnalisee)
   echo.
   cd /d "%~dp0"
   call n8n\automation\n8n-manager.cmd -ConfigFile "n8n/config/custom-config.json" %*
   ```
   Enregistrez ce fichier sous `custom-n8n-manager.cmd`.

## Gestion quotidienne de n8n

### Exemple 3 : Démarrage et arrêt de n8n

Cet exemple montre comment démarrer et arrêter n8n dans le cadre d'une utilisation quotidienne.

#### Étapes

1. Démarrer n8n :
   ```
   .\n8n-start.cmd
   ```

2. Vérifier que n8n est en cours d'exécution :
   ```
   .\n8n-status.cmd
   ```

3. Arrêter n8n :
   ```
   .\n8n-stop.cmd
   ```

### Exemple 4 : Redémarrage de n8n après une mise à jour

Cet exemple montre comment redémarrer n8n après une mise à jour.

#### Étapes

1. Arrêter n8n :
   ```
   .\n8n-stop.cmd
   ```

2. Mettre à jour n8n (exemple avec npm) :
   ```
   cd n8n
   npm update n8n
   cd ..
   ```

3. Démarrer n8n :
   ```
   .\n8n-start.cmd
   ```

4. Vérifier que n8n est en cours d'exécution et que la version a été mise à jour :
   ```
   .\n8n-status.cmd
   ```

## Importation et gestion des workflows

### Exemple 5 : Importation de workflows

Cet exemple montre comment importer des workflows dans n8n.

#### Étapes

1. Assurez-vous que n8n est en cours d'exécution :
   ```
   .\n8n-status.cmd
   ```

2. Importez les workflows :
   ```
   .\n8n-import.cmd
   ```

3. Vérifiez que les workflows ont été importés correctement :
   ```
   .\n8n-manager.cmd -Action verify
   ```

### Exemple 6 : Importation de workflows en masse

Cet exemple montre comment importer un grand nombre de workflows en parallèle.

#### Étapes

1. Assurez-vous que n8n est en cours d'exécution :
   ```
   .\n8n-status.cmd
   ```

2. Importez les workflows en masse :
   ```
   .\n8n-manager.cmd -Action import-bulk
   ```

3. Vérifiez que les workflows ont été importés correctement :
   ```
   .\n8n-manager.cmd -Action verify
   ```

### Exemple 7 : Sauvegarde et restauration des workflows

Cet exemple montre comment sauvegarder et restaurer les workflows n8n.

#### Étapes

1. Sauvegardez les workflows :
   ```
   .\n8n-manager.cmd
   ```
   Sélectionnez l'option `M` pour accéder au menu de maintenance, puis sélectionnez l'option pour sauvegarder les workflows.

2. Restaurez les workflows à partir d'une sauvegarde :
   ```powershell
   # Arrêter n8n
   .\n8n-stop.cmd
   
   # Restaurer les workflows
   $backupFile = "n8n/backups/workflows_20250425_101530.zip"
   $workflowFolder = "n8n/data/.n8n/workflows"
   
   # Extraire la sauvegarde
   Expand-Archive -Path $backupFile -DestinationPath "temp_restore" -Force
   
   # Copier les workflows
   Copy-Item -Path "temp_restore\*" -Destination $workflowFolder -Recurse -Force
   
   # Nettoyer
   Remove-Item -Path "temp_restore" -Recurse -Force
   
   # Démarrer n8n
   .\n8n-start.cmd
   ```

## Surveillance et maintenance

### Exemple 8 : Surveillance de n8n

Cet exemple montre comment surveiller l'état de n8n.

#### Étapes

1. Vérifiez l'état de n8n :
   ```
   .\n8n-status.cmd
   ```

2. Affichez le tableau de bord :
   ```
   .\n8n-manager.cmd -Action dashboard
   ```

3. Configurez une surveillance automatique :
   ```powershell
   # Créer une tâche planifiée pour vérifier l'état de n8n toutes les 15 minutes
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n\automation\monitoring\check-n8n-status-main.ps1`" -AutoRestart `$true"
   $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15)
   Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "N8N_StatusCheck" -Description "Vérification de l'état de n8n"
   ```

### Exemple 9 : Maintenance de routine

Cet exemple montre comment effectuer une maintenance de routine sur n8n.

#### Étapes

1. Exécutez la maintenance :
   ```
   .\n8n-manager.cmd
   ```
   Sélectionnez l'option `M` pour accéder au menu de maintenance.

2. Configurez une maintenance automatique :
   ```powershell
   # Créer une tâche planifiée pour exécuter la maintenance tous les jours à 3h00
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n\automation\maintenance\maintenance.ps1`""
   $trigger = New-ScheduledTaskTrigger -Daily -At "3:00AM"
   Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "N8N_Maintenance" -Description "Maintenance de n8n"
   ```

## Automatisation des tâches

### Exemple 10 : Automatisation du démarrage et de l'arrêt de n8n

Cet exemple montre comment automatiser le démarrage et l'arrêt de n8n selon un horaire.

#### Étapes

1. Créez un script pour démarrer n8n au démarrage du système :
   ```powershell
   # Créer une tâche planifiée pour démarrer n8n au démarrage du système
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n\automation\deployment\start-n8n.ps1`""
   $trigger = New-ScheduledTaskTrigger -AtStartup
   Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "N8N_StartAtBoot" -Description "Démarrer n8n au démarrage du système"
   ```

2. Créez un script pour arrêter n8n à une heure spécifique :
   ```powershell
   # Créer une tâche planifiée pour arrêter n8n à 22h00
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n\automation\deployment\stop-n8n.ps1`""
   $trigger = New-ScheduledTaskTrigger -Daily -At "10:00PM"
   Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "N8N_StopAtNight" -Description "Arrêter n8n la nuit"
   ```

### Exemple 11 : Automatisation des tests d'intégration

Cet exemple montre comment automatiser l'exécution des tests d'intégration.

#### Étapes

1. Créez un script pour exécuter les tests d'intégration chaque semaine :
   ```powershell
   # Créer une tâche planifiée pour exécuter les tests d'intégration chaque dimanche à 4h00
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n\automation\tests\integration-tests.ps1`""
   $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "4:00AM"
   Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "N8N_IntegrationTests" -Description "Tests d'intégration n8n"
   ```

## Intégration avec d'autres systèmes

### Exemple 12 : Intégration avec un système de surveillance

Cet exemple montre comment intégrer le système de remédiation n8n avec un système de surveillance externe.

#### Étapes

1. Créez un script pour envoyer les résultats de surveillance à un système externe :
   ```powershell
   # Créer un script pour envoyer les résultats de surveillance à un système externe
   $monitoringScript = @"
   # Vérifier l'état de n8n
   `$result = & "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n\automation\monitoring\check-n8n-status-main.ps1" -NoInteractive
   
   # Préparer les données pour le système externe
   `$data = @{
       status = `$result.OverallSuccess
       timestamp = Get-Date -Format "o"
       responseTime = `$result.PortTest.ResponseTime
       endpoints = `$result.EndpointTests
   } | ConvertTo-Json
   
   # Envoyer les données au système externe
   Invoke-RestMethod -Uri "https://monitoring.example.com/api/status" -Method Post -Body `$data -ContentType "application/json"
   "@
   
   # Enregistrer le script
   Set-Content -Path "n8n/automation/monitoring/send-to-external.ps1" -Value $monitoringScript
   
   # Créer une tâche planifiée pour exécuter le script toutes les 5 minutes
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n\automation\monitoring\send-to-external.ps1`""
   $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)
   Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "N8N_ExternalMonitoring" -Description "Envoi des données de surveillance à un système externe"
   ```

### Exemple 13 : Intégration avec un système de notification

Cet exemple montre comment intégrer le système de remédiation n8n avec un système de notification externe.

#### Étapes

1. Créez un fichier de configuration pour les notifications :
   ```json
   {
     "Email": {
       "Enabled": true,
       "SmtpServer": "smtp.example.com",
       "SmtpPort": 587,
       "UseSsl": true,
       "Sender": "n8n@example.com",
       "Recipients": ["admin@example.com"],
       "Username": "n8n@example.com",
       "Password": "password"
     },
     "Teams": {
       "Enabled": true,
       "WebhookUrl": "https://outlook.office.com/webhook/..."
     },
     "Slack": {
       "Enabled": true,
       "WebhookUrl": "https://hooks.slack.com/services/..."
     }
   }
   ```
   Enregistrez ce fichier sous `n8n/config/notification-config.json`.

2. Modifiez le script de notification pour utiliser cette configuration :
   ```powershell
   # Modifier le script de notification
   $notificationScript = @"
   [CmdletBinding()]
   param (
       [Parameter(Mandatory=`$true)]
       [string]`$Subject,
       
       [Parameter(Mandatory=`$true)]
       [string]`$Message,
       
       [Parameter(Mandatory=`$false)]
       [ValidateSet("INFO", "WARNING", "ERROR")]
       [string]`$Level = "WARNING"
   )
   
   # Charger la configuration
   `$configFile = "n8n/config/notification-config.json"
   `$config = Get-Content -Path `$configFile -Raw | ConvertFrom-Json
   
   # Envoyer un e-mail
   if (`$config.Email.Enabled) {
       `$emailParams = @{
           SmtpServer = `$config.Email.SmtpServer
           Port = `$config.Email.SmtpPort
           UseSsl = `$config.Email.UseSsl
           From = `$config.Email.Sender
           To = `$config.Email.Recipients
           Subject = `$Subject
           Body = `$Message
           Credential = New-Object System.Management.Automation.PSCredential(`$config.Email.Username, (ConvertTo-SecureString `$config.Email.Password -AsPlainText -Force))
       }
       
       Send-MailMessage @emailParams
   }
   
   # Envoyer une notification Teams
   if (`$config.Teams.Enabled) {
       `$teamsMessage = @{
           "@type" = "MessageCard"
           "@context" = "http://schema.org/extensions"
           "themeColor" = switch (`$Level) {
               "INFO" { "0076D7" }
               "WARNING" { "FFA500" }
               "ERROR" { "FF0000" }
               default { "0076D7" }
           }
           "summary" = `$Subject
           "sections" = @(
               @{
                   "activityTitle" = `$Subject
                   "activitySubtitle" = "n8n Notification"
                   "activityImage" = "https://n8n.io/favicon.ico"
                   "text" = `$Message
               }
           )
       } | ConvertTo-Json -Depth 10
       
       Invoke-RestMethod -Uri `$config.Teams.WebhookUrl -Method Post -Body `$teamsMessage -ContentType "application/json"
   }
   
   # Envoyer une notification Slack
   if (`$config.Slack.Enabled) {
       `$slackMessage = @{
           text = `$Subject
           attachments = @(
               @{
                   color = switch (`$Level) {
                       "INFO" { "good" }
                       "WARNING" { "warning" }
                       "ERROR" { "danger" }
                       default { "good" }
                   }
                   text = `$Message
               }
           )
       } | ConvertTo-Json -Depth 10
       
       Invoke-RestMethod -Uri `$config.Slack.WebhookUrl -Method Post -Body `$slackMessage -ContentType "application/json"
   }
   "@
   
   # Enregistrer le script
   Set-Content -Path "n8n/automation/notification/send-notification.ps1" -Value $notificationScript
   ```

## Dépannage

### Exemple 14 : Résolution des problèmes de démarrage

Cet exemple montre comment résoudre les problèmes de démarrage de n8n.

#### Étapes

1. Vérifiez les logs de n8n :
   ```powershell
   Get-Content -Path "n8n/logs/n8n.log" -Tail 50
   ```

2. Vérifiez si le port est déjà utilisé :
   ```powershell
   # Vérifier si le port 5678 est déjà utilisé
   $portInUse = Get-NetTCPConnection -LocalPort 5678 -ErrorAction SilentlyContinue
   
   if ($portInUse) {
       Write-Host "Le port 5678 est déjà utilisé par le processus $($portInUse.OwningProcess)" -ForegroundColor Red
       
       # Obtenir des informations sur le processus
       $process = Get-Process -Id $portInUse.OwningProcess -ErrorAction SilentlyContinue
       
       if ($process) {
           Write-Host "Processus: $($process.Name) (PID: $($process.Id))" -ForegroundColor Red
       }
   } else {
       Write-Host "Le port 5678 est disponible" -ForegroundColor Green
   }
   ```

3. Vérifiez l'intégrité du système :
   ```
   .\test-structure.cmd -FixIssues $true
   ```

4. Redémarrez n8n avec des options de débogage :
   ```powershell
   # Arrêter n8n
   .\n8n-stop.cmd
   
   # Démarrer n8n avec des options de débogage
   $env:DEBUG = "n8n:*"
   .\n8n-start.cmd
   
   # Vérifier les logs
   Get-Content -Path "n8n/logs/n8n.log" -Tail 50 -Wait
   ```

### Exemple 15 : Résolution des problèmes d'importation de workflows

Cet exemple montre comment résoudre les problèmes d'importation de workflows.

#### Étapes

1. Vérifiez les logs d'importation :
   ```powershell
   Get-Content -Path "n8n/logs/import-workflows.log" -Tail 50
   ```

2. Vérifiez que l'API n8n est accessible :
   ```powershell
   # Vérifier que l'API n8n est accessible
   $response = Invoke-WebRequest -Uri "http://localhost:5678/healthz" -UseBasicParsing
   
   if ($response.StatusCode -eq 200) {
       Write-Host "L'API n8n est accessible" -ForegroundColor Green
   } else {
       Write-Host "L'API n8n n'est pas accessible (Code: $($response.StatusCode))" -ForegroundColor Red
   }
   ```

3. Vérifiez que les fichiers JSON sont valides :
   ```powershell
   # Vérifier que les fichiers JSON sont valides
   $referenceFolder = "n8n/core/workflows/local"
   $files = Get-ChildItem -Path $referenceFolder -Filter "*.json"
   
   foreach ($file in $files) {
       try {
           $content = Get-Content -Path $file.FullName -Raw
           $null = $content | ConvertFrom-Json
           Write-Host "Fichier valide: $($file.Name)" -ForegroundColor Green
       } catch {
           Write-Host "Fichier invalide: $($file.Name) - $_" -ForegroundColor Red
       }
   }
   ```

4. Importez un workflow spécifique manuellement :
   ```powershell
   # Importer un workflow spécifique manuellement
   $workflowFile = "n8n/core/workflows/local/workflow1.json"
   $workflowContent = Get-Content -Path $workflowFile -Raw
   $workflow = $workflowContent | ConvertFrom-Json
   
   $apiUrl = "http://localhost:5678/rest/workflows"
   $headers = @{
       "Content-Type" = "application/json"
   }
   
   $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $workflowContent -Headers $headers
   
   Write-Host "Workflow importé: $($response.name) (ID: $($response.id))" -ForegroundColor Green
   ```

Ces exemples couvrent les scénarios d'utilisation les plus courants du système de remédiation n8n. Ils peuvent être adaptés à vos besoins spécifiques en modifiant les paramètres et les scripts.
