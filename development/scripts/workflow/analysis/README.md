# Module d'analyse des workflows n8n

Ce module fournit des fonctionnalités pour analyser les workflows n8n, détecter les activités, extraire les transitions et analyser les conditions.

## Fonctionnalités

Le module implémente les fonctionnalités suivantes :

1. **Détection des activités de workflow** : Identifie tous les nœuds du workflow et les catégorise par type et fonction.
2. **Extraction des transitions de workflow** : Identifie toutes les connexions entre les nœuds et les chemins de transition.
3. **Analyse des conditions de workflow** : Identifie et analyse les nœuds conditionnels (IF, Switch) et leurs expressions de condition.
4. **Détection des blocs try/catch/finally** : Identifie et analyse les blocs try/catch/finally dans le code des nœuds de fonction.

## Structure des fichiers

- `WorkflowAnalyzer.psm1` : Module principal contenant les fonctions d'analyse.
- `Analyze-N8nWorkflow.ps1` : Script principal pour analyser les workflows n8n.
- `Demo-WorkflowAnalysis.ps1` : Script de démonstration montrant l'utilisation du module.
- `Test-WorkflowAnalyzer.ps1` : Script de test pour vérifier le bon fonctionnement du module.
- `README.md` : Documentation du module.

## Installation

1. Copiez les fichiers dans un dossier de votre choix.
2. Importez le module dans votre script PowerShell :

```powershell
Import-Module -Path "chemin\vers\WorkflowAnalyzer.psm1" -Force
```

## Utilisation

### Analyser un workflow n8n

```powershell
# Analyser un workflow n8n
.\Analyze-N8nWorkflow.ps1 -WorkflowPath "chemin\vers\workflow.json" -OutputFolder "chemin\vers\rapports"
```

### Détecter les activités de workflow

```powershell
# Charger le workflow
$workflow = Get-N8nWorkflow -WorkflowPath "chemin\vers\workflow.json"

# Détecter les activités
$activities = Get-N8nWorkflowActivities -Workflow $workflow -IncludeDetails
```

### Extraire les transitions de workflow

```powershell
# Charger le workflow
$workflow = Get-N8nWorkflow -WorkflowPath "chemin\vers\workflow.json"

# Extraire les transitions
$transitions = Get-N8nWorkflowTransitions -Workflow $workflow
```

### Analyser les conditions de workflow

```powershell
# Charger le workflow
$workflow = Get-N8nWorkflow -WorkflowPath "chemin\vers\workflow.json"

# Analyser les conditions
$conditions = Get-N8nWorkflowConditions -Workflow $workflow -IncludeTransitions
```

### Détecter les blocs try/catch/finally

```powershell
# Charger le workflow
$workflow = Get-N8nWorkflow -WorkflowPath "chemin\vers\workflow.json"

# Détecter les blocs try/catch/finally
$tryCatchBlocks = Get-N8nWorkflowTryCatchBlocks -Workflow $workflow
```

### Générer un rapport d'analyse

```powershell
# Générer un rapport d'analyse
$report = Get-N8nWorkflowAnalysisReport -WorkflowPath "chemin\vers\workflow.json" -OutputPath "chemin\vers\rapport.md" -Format "Markdown"
```

## Formats de sortie

Le module prend en charge plusieurs formats de sortie :

- **Markdown** : Format par défaut, idéal pour la documentation.
- **JSON** : Format structuré, idéal pour l'intégration avec d'autres outils.
- **HTML** : Format visuel, idéal pour la consultation dans un navigateur.
- **Text** : Format texte simple, idéal pour la console.

## Exemples

### Exemple 1 : Analyser un workflow et générer un rapport Markdown

```powershell
.\Analyze-N8nWorkflow.ps1 -WorkflowPath "chemin\vers\workflow.json" -OutputFolder "chemin\vers\rapports" -Format "Markdown"
```

### Exemple 2 : Analyser uniquement les activités et les transitions

```powershell
.\Analyze-N8nWorkflow.ps1 -WorkflowPath "chemin\vers\workflow.json" -ActivitiesOnly -TransitionsOnly -Format "JSON"
```

### Exemple 3 : Utiliser le script de démonstration

```powershell
.\Demo-WorkflowAnalysis.ps1 -WorkflowPath "chemin\vers\workflow.json" -OutputFolder "chemin\vers\rapports"
```

## Tests

Pour tester le module, exécutez le script de test :

```powershell
.\Test-WorkflowAnalyzer.ps1 -WorkflowPath "chemin\vers\workflow.json" -OutputFolder "chemin\vers\tests"
```

## Fonctions du module

### Get-N8nWorkflow

Charge un workflow n8n depuis un fichier JSON.

```powershell
Get-N8nWorkflow -WorkflowPath "chemin\vers\workflow.json"
```

### Get-N8nWorkflowActivities

Détecte les activités d'un workflow n8n.

```powershell
Get-N8nWorkflowActivities -Workflow $workflow -IncludeDetails
```

### Get-N8nWorkflowTransitions

Extrait les transitions d'un workflow n8n.

```powershell
Get-N8nWorkflowTransitions -Workflow $workflow -IncludeNodeDetails
```

### Get-N8nWorkflowConditions

Analyse les conditions d'un workflow n8n.

```powershell
Get-N8nWorkflowConditions -Workflow $workflow -IncludeTransitions
```

### Get-N8nWorkflowAnalysisReport

Génère un rapport d'analyse d'un workflow n8n.

```powershell
Get-N8nWorkflowAnalysisReport -WorkflowPath "chemin\vers\workflow.json" -OutputPath "chemin\vers\rapport.md" -Format "Markdown"
```

### Get-N8nWorkflowTryCatchBlocks

Détecte et analyse les blocs try/catch/finally dans les nœuds de fonction d'un workflow n8n.

```powershell
Get-N8nWorkflowTryCatchBlocks -Workflow $workflow
```

## Catégories de nœuds

Le module catégorise les nœuds en plusieurs catégories :

- **Trigger** : Nœuds de déclenchement (Start, ManualTrigger, Schedule, Webhook, Cron).
- **Flow Control** : Nœuds de contrôle de flux (If, Switch, Merge, SplitInBatches, Wait).
- **Data Operation** : Nœuds de manipulation de données (Set, Function, FunctionItem, Code).
- **API** : Nœuds d'API (HttpRequest, Webhook).
- **Communication** : Nœuds de communication (EmailSend, Slack, Telegram).
- **Integration** : Nœuds d'intégration (GoogleSheets, Notion, Airtable).
- **Documentation** : Nœuds de documentation (StickyNote).
- **Other** : Autres types de nœuds.
