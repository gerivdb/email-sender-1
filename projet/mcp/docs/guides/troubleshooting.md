# Guide de dépannage MCP

Ce guide vous aidera à résoudre les problèmes courants rencontrés avec les serveurs MCP (Model Context Protocol) dans le projet EMAIL_SENDER_1.

## Diagnostic général

Avant de commencer le dépannage, exécutez le script de diagnostic pour obtenir un aperçu de l'état du système :

```powershell
.\projet\mcp\monitoring\scripts\check-mcp-health.ps1 -OutputFormat HTML
```

Ce script générera un rapport détaillé sur l'état des serveurs MCP, ce qui vous aidera à identifier les problèmes potentiels.

## Problèmes de démarrage des serveurs

### Un serveur ne démarre pas

**Symptômes :**
- Le serveur ne répond pas aux requêtes
- La commande `Start-MCPServer` échoue
- Le statut du serveur reste "Stopped"

**Solutions :**

1. **Vérifiez les journaux :**
   ```powershell
   Get-Content .\projet\mcp\monitoring\logs\mcp.log -Tail 50
   ```

2. **Vérifiez la configuration du serveur :**
   ```powershell
   .\projet\mcp\tests\unit\Test-MCPConfig.ps1
   ```

3. **Vérifiez les dépendances :**
   ```powershell
   .\projet\mcp\dependencies\scripts\install-dependencies.ps1
   ```

4. **Redémarrez le serveur avec l'option Force :**
   ```powershell
   Restart-MCPServer -ServerName <nom_du_serveur> -Force
   ```

5. **Vérifiez les processus en cours d'exécution :**
   ```powershell
   Get-Process | Where-Object { $_.ProcessName -like "*mcp*" -or $_.ProcessName -like "*node*" }
   ```

### Tous les serveurs ne démarrent pas

**Symptômes :**
- Aucun serveur ne démarre
- Erreurs multiples dans les journaux

**Solutions :**

1. **Vérifiez l'installation de MCP :**
   ```powershell
   .\projet\mcp\scripts\setup\setup-mcp.ps1 -Force
   ```

2. **Vérifiez les permissions :**
   ```powershell
   # Exécutez PowerShell en tant qu'administrateur
   Start-Process powershell -Verb RunAs
   ```

3. **Restaurez une sauvegarde fonctionnelle :**
   ```powershell
   .\projet\mcp\versioning\scripts\rollback-mcp-update.ps1
   ```

## Problèmes de configuration

### Erreurs de configuration

**Symptômes :**
- Messages d'erreur concernant la configuration
- Les serveurs démarrent mais ne fonctionnent pas correctement

**Solutions :**

1. **Validez la configuration :**
   ```powershell
   .\projet\mcp\tests\unit\Test-MCPConfig.ps1
   ```

2. **Réinitialisez la configuration :**
   ```powershell
   # Sauvegardez d'abord la configuration actuelle
   .\projet\mcp\scripts\maintenance\backup-mcp-config.ps1 -CreateZip
   
   # Réinitialisez la configuration
   Remove-Item .\projet\mcp\config\mcp-config.json -Force
   .\projet\mcp\scripts\setup\setup-mcp.ps1 -Force
   ```

3. **Vérifiez les fichiers de configuration spécifiques aux serveurs :**
   ```powershell
   Get-ChildItem .\projet\mcp\config\servers\
   ```

### Problèmes de chemin

**Symptômes :**
- Erreurs "File not found" ou "Path not found"
- Les serveurs ne peuvent pas accéder aux fichiers

**Solutions :**

1. **Vérifiez les chemins dans la configuration :**
   ```powershell
   # Ouvrez le fichier de configuration
   notepad .\projet\mcp\config\mcp-config.json
   ```

2. **Utilisez des chemins absolus :**
   ```powershell
   # Exemple de correction dans la configuration
   $config = Get-Content .\projet\mcp\config\mcp-config.json -Raw | ConvertFrom-Json
   $config.mcpServers.filesystem.args[1] = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
   $config | ConvertTo-Json -Depth 10 | Set-Content .\projet\mcp\config\mcp-config.json
   ```

## Problèmes de performance

### Serveurs lents ou instables

**Symptômes :**
- Temps de réponse élevés
- Serveurs qui se bloquent ou plantent
- Utilisation élevée des ressources

**Solutions :**

1. **Collectez des métriques de performance :**
   ```powershell
   .\projet\mcp\monitoring\scripts\collect-metrics.ps1 -Interval 10 -Duration 10
   ```

2. **Vérifiez l'utilisation des ressources :**
   ```powershell
   Get-Process | Where-Object { $_.ProcessName -like "*mcp*" } | Select-Object ProcessName, Id, CPU, WorkingSet
   ```

3. **Redémarrez les serveurs problématiques :**
   ```powershell
   Restart-MCPServer -ServerName <nom_du_serveur> -Force
   ```

4. **Augmentez les ressources allouées :**
   ```powershell
   # Modifiez la configuration pour allouer plus de ressources
   # Par exemple, augmentez la mémoire maximale pour Node.js
   $env:NODE_OPTIONS="--max-old-space-size=4096"
   ```

### Fuites de mémoire

**Symptômes :**
- Utilisation croissante de la mémoire au fil du temps
- Performances qui se dégradent progressivement

**Solutions :**

1. **Surveillez l'utilisation de la mémoire :**
   ```powershell
   .\projet\mcp\monitoring\scripts\collect-metrics.ps1 -Interval 60 -Duration 60
   ```

2. **Redémarrez régulièrement les serveurs :**
   ```powershell
   # Créez une tâche planifiée pour redémarrer les serveurs
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -Command `"Import-Module .\projet\mcp\modules\MCPManager; Restart-MCPServer -Force`""
   $trigger = New-ScheduledTaskTrigger -Daily -At 3AM
   Register-ScheduledTask -TaskName "RestartMCPServers" -Action $action -Trigger $trigger
   ```

## Problèmes d'intégration

### Problèmes avec n8n

**Symptômes :**
- Les workflows n8n échouent
- Erreurs de connexion aux serveurs MCP

**Solutions :**

1. **Vérifiez que n8n est en cours d'exécution :**
   ```powershell
   # Vérifiez si n8n est en cours d'exécution
   Get-Process | Where-Object { $_.ProcessName -like "*n8n*" }
   
   # Démarrez n8n si nécessaire
   cd <chemin_vers_n8n>
   npm run start
   ```

2. **Reconfigurez l'intégration avec n8n :**
   ```powershell
   .\projet\mcp\integrations\n8n\scripts\configure-n8n-mcp.ps1 -Force
   ```

3. **Vérifiez les credentials dans n8n :**
   - Ouvrez n8n dans votre navigateur (généralement http://localhost:5678)
   - Allez dans Settings > Credentials
   - Vérifiez que les credentials MCP sont correctement configurés

4. **Testez les workflows avec des données simples :**
   - Importez les workflows de test depuis `projet/mcp/integrations/n8n/workflows/`
   - Exécutez-les avec des données simples pour vérifier la connexion

### Problèmes avec les API externes

**Symptômes :**
- Erreurs lors de l'accès aux API externes
- Timeouts ou erreurs d'authentification

**Solutions :**

1. **Vérifiez les tokens d'API :**
   ```powershell
   # Vérifiez les fichiers de configuration des serveurs
   Get-ChildItem .\projet\mcp\config\servers\
   ```

2. **Vérifiez la connectivité réseau :**
   ```powershell
   # Testez la connexion aux API externes
   Test-NetConnection -ComputerName api.github.com -Port 443
   ```

3. **Mettez à jour les tokens d'API :**
   ```powershell
   # Modifiez les fichiers de configuration des serveurs
   notepad .\projet\mcp\config\servers\github.json
   ```

## Problèmes de module PowerShell

### Le module MCPManager ne se charge pas

**Symptômes :**
- Erreurs lors de l'importation du module
- Commandes non reconnues

**Solutions :**

1. **Vérifiez le module :**
   ```powershell
   Test-ModuleManifest .\projet\mcp\modules\MCPManager\MCPManager.psd1
   ```

2. **Réimportez le module :**
   ```powershell
   Import-Module .\projet\mcp\modules\MCPManager -Force
   ```

3. **Vérifiez les erreurs de syntaxe :**
   ```powershell
   # Vérifiez la syntaxe du module
   $errors = $null
   $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content .\projet\mcp\modules\MCPManager\MCPManager.psm1 -Raw), [ref]$errors)
   $errors
   ```

4. **Exécutez les tests du module :**
   ```powershell
   .\projet\mcp\tests\unit\Test-MCPManager.ps1
   ```

## Problèmes de sauvegarde et restauration

### Échec des sauvegardes

**Symptômes :**
- Les sauvegardes échouent
- Erreurs lors de la création des fichiers ZIP

**Solutions :**

1. **Vérifiez les permissions :**
   ```powershell
   # Exécutez PowerShell en tant qu'administrateur
   Start-Process powershell -Verb RunAs
   ```

2. **Vérifiez l'espace disque :**
   ```powershell
   Get-PSDrive C | Select-Object Used, Free
   ```

3. **Essayez une sauvegarde sans compression :**
   ```powershell
   .\projet\mcp\scripts\maintenance\backup-mcp-config.ps1 -Force
   ```

### Échec des restaurations

**Symptômes :**
- Les restaurations échouent
- Erreurs lors de la copie des fichiers

**Solutions :**

1. **Vérifiez l'intégrité de la sauvegarde :**
   ```powershell
   # Pour les sauvegardes ZIP
   Test-Path .\projet\mcp\versioning\backups\<date>-<version>.zip
   
   # Pour les sauvegardes en répertoire
   Get-ChildItem .\projet\mcp\versioning\backups\<date>-<version>\
   ```

2. **Arrêtez tous les serveurs avant la restauration :**
   ```powershell
   Stop-MCPServer -Force
   ```

3. **Essayez une restauration manuelle :**
   ```powershell
   # Extrayez la sauvegarde ZIP
   Expand-Archive .\projet\mcp\versioning\backups\<date>-<version>.zip -DestinationPath .\temp\
   
   # Copiez les fichiers manuellement
   Copy-Item .\temp\config\* .\projet\mcp\config\ -Recurse -Force
   ```

## Journalisation et diagnostic

### Activer la journalisation détaillée

Pour activer une journalisation plus détaillée :

```powershell
# Modifiez la configuration globale
$config = Get-Content .\projet\mcp\config\mcp-config.json -Raw | ConvertFrom-Json
$config.global.logLevel = "debug"
$config | ConvertTo-Json -Depth 10 | Set-Content .\projet\mcp\config\mcp-config.json

# Redémarrez les serveurs
Restart-MCPServer -Force
```

### Analyser les journaux

Pour analyser les journaux :

```powershell
# Afficher les dernières entrées du journal
Get-Content .\projet\mcp\monitoring\logs\mcp.log -Tail 100

# Rechercher des erreurs spécifiques
Select-String -Path .\projet\mcp\monitoring\logs\mcp.log -Pattern "ERROR"

# Exporter les journaux pour analyse
Copy-Item .\projet\mcp\monitoring\logs\mcp.log .\mcp-logs-$(Get-Date -Format 'yyyyMMdd').log
```

### Générer un rapport de diagnostic complet

Pour générer un rapport de diagnostic complet :

```powershell
.\projet\mcp\monitoring\scripts\generate-health-report.ps1 -OutputFormat HTML -IncludeTests
```

## Réinitialisation complète

Si tous les autres dépannages échouent, vous pouvez effectuer une réinitialisation complète :

1. **Sauvegardez d'abord vos données importantes :**
   ```powershell
   .\projet\mcp\scripts\maintenance\backup-mcp-config.ps1 -CreateZip -IncludeData
   ```

2. **Arrêtez tous les serveurs :**
   ```powershell
   Stop-MCPServer -Force
   ```

3. **Désinstallez MCP :**
   ```powershell
   .\projet\mcp\scripts\maintenance\uninstall-mcp.ps1
   ```

4. **Réinstallez MCP :**
   ```powershell
   .\projet\mcp\scripts\setup\setup-mcp.ps1 -Force
   ```

5. **Restaurez vos données si nécessaire :**
   ```powershell
   # Restaurez uniquement les données, pas la configuration
   # Extrayez la sauvegarde ZIP
   Expand-Archive .\projet\mcp\versioning\backups\<date>-<version>.zip -DestinationPath .\temp\
   
   # Copiez uniquement les données
   Copy-Item .\temp\data\* .\projet\mcp\data\ -Recurse -Force
   ```

## Contacter le support

Si vous ne parvenez pas à résoudre le problème, contactez l'équipe de support :

- **Email :** support@email-sender-1.com
- **GitHub :** Ouvrez une issue sur le dépôt GitHub
- **Documentation :** Consultez la documentation complète dans `projet/mcp/docs/`
