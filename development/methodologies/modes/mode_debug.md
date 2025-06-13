# Mode DEBUG

## Description

Le mode DEBUG est un mode opérationnel qui aide à identifier, analyser et résoudre les problèmes dans le code et les processus, en facilitant la correction rapide des bugs et l’optimisation des performances.

## Objectifs

- Détecter et corriger les bugs et problèmes de performance.
- Faciliter l’analyse des erreurs et l’inspection des variables.
- Générer des rapports de débogage exploitables.

## Commandes principales

- debug run : Lance le débogage d’un script ou d’une tâche.
- debug perf : Analyse les performances d’un composant.
- debug report : Génère un rapport détaillé de débogage.

## Fonctionnement

- Analyse les erreurs et trace les exécutions.
- Permet l’inspection des variables et l’analyse de performance.
- Génère des rapports détaillés pour chaque session de débogage.
- Propose des suggestions de correction.

## Fonctionnalités avancées

- Analyse de stack trace (extraction, visualisation, résolution de chemins)
- Inspection détaillée des variables et objets complexes
- Traçage d’exécution (flux, points de trace, mesure de temps)
- Simulation de contexte (environnements virtuels, entrées/sorties, erreurs, charge)

### Paramètres principaux

| Paramètre | Description |
|-----------|-------------|
| FilePath | Chemin vers le fichier de roadmap à traiter |
| TaskIdentifier | Identifiant de la tâche à traiter |
| ErrorLog | Chemin vers le fichier de log d’erreurs à analyser |
| ScriptPath | Chemin vers le script ou module à déboguer |
| OutputPath | Chemin de sortie des fichiers générés |
| GeneratePatch | Générer un patch correctif |
| IncludeStackTrace | Inclure les traces de pile dans l’analyse |
| MaxStackTraceDepth | Profondeur maximale des traces de pile |
| AnalyzePerformance | Analyser les performances |
| SuggestFixes | Générer des suggestions de correction |
| SimulateContext | Simuler le contexte d’exécution |

## Bonnes pratiques

- Utiliser le mode DEBUG dès qu’un problème est détecté.
- Commencer par le niveau de débogage le plus bas et augmenter si nécessaire.
- Documenter les problèmes et solutions trouvés.
- Ajouter des tests pour éviter la régression.

## Intégration avec les autres modes

Le mode DEBUG s’intègre naturellement avec :
- **TEST** : Pour déboguer les tests qui échouent ([voir mode_test.md](mode_test.md))
- **OPTI** : Pour optimiser après correction ([voir mode_opti.md](mode_opti.md))
- **DEV-R** : Pour revenir au développement après correction ([voir mode_dev_r.md](mode_dev_r.md))
- **REVIEW** : Pour soumettre les corrections à une revue qualité ([voir mode_review.md](mode_review.md))

Exemple de workflow typique : DEV-R → TEST → DEBUG → OPTI → REVIEW

## Exemples d’utilisation

```powershell
# Déboguer un script spécifique

Invoke-AugmentMode -Mode "DEBUG" -FilePath "projet/roadmap.md" -TaskIdentifier "1.2.3" -Verbose

# Analyser les performances

Invoke-AugmentMode -Mode "DEBUG" -FilePath "projet/roadmap.md" -PerformanceAnalysis
```plaintext
### Exemples avancés

```powershell
# Analyser un fichier de log d’erreurs

Invoke-AugmentMode -Mode "DEBUG" -FilePath "roadmap.md" -ErrorLog "error.log" -ScriptPath "scripts" -OutputPath "output"

# Générer un patch correctif sans inclure les traces de pile

Invoke-AugmentMode -Mode "DEBUG" -FilePath "roadmap.md" -ErrorLog "error.log" -ScriptPath "scripts" -GeneratePatch $true -IncludeStackTrace $false
```plaintext
## Snippet VS Code (optionnel)

```json
{
  "Mode DEBUG": {
    "prefix": "debugmode",
    "body": [
      "# Mode DEBUG",

      "",
      "## Description",

      "Le mode DEBUG est un mode opérationnel qui aide à identifier et résoudre les problèmes dans le code et les processus.",
      "",
      "## Fonctionnement",

      "- Analyse les erreurs et trace les exécutions",
      "- Permet l’inspection des variables et l’analyse de performance",
      "- Génère des rapports détaillés de débogage"
    ],
    "description": "Insère le template du mode DEBUG pour la gestion du débogage."
  }
}
```plaintext
## Documentation associée et approfondissements

Pour une compréhension avancée de la gestion des erreurs et des exceptions, voir :
- [Propriétés communes de System.Exception](../exception_properties_documentation.md)
- [Structure de la taxonomie des exceptions PowerShell](../exception_taxonomy_structure.md)
- [Exceptions du namespace System](../system_exceptions_documentation.md)
- [Exceptions du namespace System.IO](../system_io_exceptions_documentation.md)
- [Les 16 bases de la programmation](../programmation_16_bases.md) (document de référence supérieur)

