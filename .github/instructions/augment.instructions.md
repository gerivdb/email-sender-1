# Instructions Copilot – Intégration Augment

Ce fichier centralise les instructions pour l’intégration avec l’extension Augment VS Code.

- Utilisation des guides dans [docs/guides/augment/](../../docs/guides/augment/)
- Bonnes pratiques d’intégration (voir [integration_guide.md](../../docs/guides/augment/integration_guide.md))
- Exemples de prompts efficaces ([prompts-efficaces.md](../../docs/guides/augment/prompts-efficaces.md), [PROMPT_REFERENCE.md](../../docs/guides/augment/PROMPT_REFERENCE.md))

### Extrait du guide d’intégration
> « Augment Code est un assistant IA basé sur Claude 3.7 Sonnet d'Anthropic, qui offre des capacités avancées pour assister les développeurs dans leurs tâches de programmation. »

Pour la configuration, voir le script `development/scripts/maintenance/augment/configure-augment-mcp.ps1`.

## 🎯 Objectif
Intégrer efficacement avec l'extension Augment Code pour VS Code selon les guides dans `docs/guides/augment/`.

## 🔧 Initialisation d'Augment
```powershell
# Importer le module PowerShell
Import-Module "development\scripts\maintenance\augment\AugmentIntegration.psm1"

# Initialiser l'intégration
Initialize-AugmentIntegration -StartServers

# Vérifier le statut
Test-AugmentConnection
```

## 📋 Exécution des Modes via Augment
```powershell
# Exécuter un mode spécifique
Invoke-AugmentMode -Mode "GRAN" -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3"

# Mettre à jour les Memories
Update-AugmentMemoriesForMode -Mode "CHECK" -Results $lastResults

# Analyser les performances
Analyze-AugmentPerformance -Mode "DEV-R" -SessionId $currentSession
```

## 📝 Structure des Prompts pour Augment
Utiliser systématiquement cette structure :

```markdown
[CONTEXTE]
Description du contexte actuel du projet, références aux fichiers pertinents.

[OBJECTIF] 
Objectif précis de la demande, mode opérationnel souhaité.

[CONTRAINTES]
- Respecter les standards dans `docs/guides/standards/`
- Utiliser les modes définis dans `projet/guides/methodologies/`
- Sauvegarder l'état après chaque action

[DEMANDE]
Action spécifique à réaliser avec paramètres détaillés.
```

## 🔄 Workflow Augment Standard

### 1. Préparation
```powershell
# Segmenter les inputs volumineux si nécessaire
$segments = Split-AugmentInput -InputText $largePrompt -MaxTokens 4000

# Préparer le contexte
Set-AugmentContext -ProjectPath "." -Standards "docs/guides/standards/"
```

### 2. Exécution
```powershell
# Exécuter avec monitoring
$result = Invoke-AugmentPrompt -Prompt $structuredPrompt -Mode $selectedMode

# Surveiller la progression
Watch-AugmentProgress -SessionId $result.SessionId
```

### 3. Post-traitement
```powershell
# Analyser les résultats
$analysis = Analyze-AugmentOutput -Result $result

# Mettre à jour la roadmap si applicable
Update-RoadmapFromAugment -Analysis $analysis -RoadmapPath "docs/roadmap/"
```

## 📊 Gestion des Memories Augment
```powershell
# Ajouter une memory spécifique au projet
Add-AugmentMemory -Type "ProjectStandard" -Content "docs/guides/standards/" -Priority "High"

# Mettre à jour les memories des modes
Update-ModeMemories -ModeName "GRAN" -LastResults $granResults

# Nettoyer les memories obsolètes
Clean-AugmentMemories -OlderThan (Get-Date).AddDays(-7)
```

## 🎯 Prompts Prédéfinis pour Augment

### Prompt Analyse de Code
```markdown
[CONTEXTE] Analyse du code dans le projet EMAIL_SENDER_1 selon les standards définis.
[OBJECTIF] Identifier les améliorations possibles et vérifier la conformité.
[CONTRAINTES] Respecter docs/guides/standards/, proposer des corrections spécifiques.
[DEMANDE] Analyser le fichier [CHEMIN] et proposer des améliorations détaillées.
```

### Prompt Génération de Tests
```markdown
[CONTEXTE] Génération de tests pour le projet selon les méthodologies établies.
[OBJECTIF] Créer des tests complets couvrant tous les cas d'usage.
[CONTRAINTES] Suivre les patterns dans docs/guides/standards/, utiliser les frameworks recommandés.
[DEMANDE] Générer des tests pour [MODULE/FONCTION] avec couverture >= 90%.
```

### Prompt Refactoring
```markdown
[CONTEXTE] Refactoring de code existant en respectant l'architecture du projet.
[OBJECTIF] Améliorer la maintenabilité sans changer le comportement.
[CONTRAINTES] Préserver l'API existante, suivre les conventions de nommage, tester chaque étape.
[DEMANDE] Refactoriser [COMPOSANT] en appliquant les patterns recommandés.
```

## 📁 Références aux Guides Augment
- **Guide principal** : `docs/guides/augment/advanced_usage.md`
- **Configuration** : `docs/guides/augment/configuration.md`
- **Exemples** : `docs/guides/augment/examples/`
- **Scripts d'intégration** : `development/scripts/maintenance/augment/`

## 🚨 Gestion d'Erreurs Augment
```powershell
# Gestion des timeouts
if ($result.Status -eq "Timeout") {
    Retry-AugmentOperation -SessionId $result.SessionId -MaxRetries 3
}

# Gestion des erreurs de connexion
if (-not (Test-AugmentConnection)) {
    Restart-AugmentService
    Start-Sleep -Seconds 5
    Initialize-AugmentIntegration -StartServers
}
```

---
*Instructions spécialisées pour l'intégration avec Augment Code*