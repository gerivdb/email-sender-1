# Mode C-BREAK (Détection et Résolution des Dépendances Circulaires)

## Description
Le mode C-BREAK (Cycle Breaker) est un mode opérationnel conçu pour détecter, analyser et corriger les dépendances circulaires dans un projet (code, workflows, données). Les cycles de dépendances nuisent à la maintenabilité, la performance et la testabilité du projet.

## Objectifs
- Détecter automatiquement les dépendances circulaires dans le code et les workflows
- Analyser la gravité et l'impact des cycles détectés
- Proposer et appliquer des stratégies de résolution adaptées
- Générer des rapports et visualisations des dépendances
- Valider que les corrections n'introduisent pas de régressions

## Commandes principales
- `c-break.ps1 -Path <projet>` : Analyse un projet et détecte les cycles
- `c-break.ps1 -Path <projet> -FixCycles` : Corrige automatiquement les cycles détectés
- `c-break.ps1 -Path <projet> -OutputPath <rapport>` : Génère un rapport détaillé
- `c-break.ps1 -Path <projet> -Algorithm <DFS|TARJAN|JOHNSON>` : Choix de l'algorithme de détection

## Fonctionnement
- Analyse les dépendances (import, require, using, etc.) pour plusieurs langages (PowerShell, Python, JS/TS, C#, Java)
- Détecte les cycles via DFS, Tarjan ou Johnson
- Propose des stratégies de résolution : extraction d'interface, inversion de dépendance, médiateur, refactorisation
- Génère des graphes (DOT, Mermaid, PlantUML, JSON) et rapports HTML/JSON
- Peut corriger automatiquement certains cycles selon la stratégie choisie

## Bonnes pratiques
- Exécuter C-BREAK régulièrement pendant le développement
- Intégrer C-BREAK dans les hooks pre-commit
- Analyser en priorité les fichiers modifiés ou les sous-répertoires critiques
- Examiner manuellement les corrections proposées avant application
- Documenter les choix d'architecture pour éviter la réintroduction de cycles

## Intégration avec les autres modes
- **ARCHI** : Pour concevoir une architecture sans dépendances circulaires
- **REVIEW** : Pour vérifier l'absence de cycles lors des revues de code
- **OPTI** : Pour optimiser le code en éliminant les cycles
- **CHECK** : Vérifie l'absence de cycles avant de valider une tâche
- **DEBUG** : Utilise C-BREAK pour diagnostiquer les problèmes liés aux dépendances
- **DEV-R** : Applique C-BREAK avant de livrer une fonctionnalité

## Exemples d’utilisation
```powershell
# Détecter les cycles dans un projet
.\development\tools\scripts\c-break.ps1 -Path "D:\MonProjet" -Verbose

# Corriger automatiquement les cycles
.\development\tools\scripts\c-break.ps1 -Path "D:\MonProjet" -FixCycles -FixStrategy INVERSION

# Générer un rapport détaillé
.\development\tools\scripts\c-break.ps1 -Path "D:\MonProjet" -OutputPath "D:\Rapports\cycles.json" -Algorithm TARJAN
```

## Snippet VS Code (optionnel)
```json
{
  "Mode C-BREAK": {
    "prefix": "mode-cbreak",
    "body": [
      "# Mode C-BREAK (Détection et Résolution des Dépendances Circulaires)",
      "## Description",
      "Le mode C-BREAK (Cycle Breaker) est un mode opérationnel conçu pour détecter, analyser et corriger les dépendances circulaires dans un projet (code, workflows, données). Les cycles de dépendances nuisent à la maintenabilité, la performance et la testabilité du projet.",
      "## Objectifs",
      "- Détecter automatiquement les dépendances circulaires dans le code et les workflows",
      "- Analyser la gravité et l'impact des cycles détectés",
      "- Proposer et appliquer des stratégies de résolution adaptées",
      "- Générer des rapports et visualisations des dépendances",
      "- Valider que les corrections n'introduisent pas de régressions",
      "## Commandes principales",
      "- c-break.ps1 -Path <projet> : Analyse un projet et détecte les cycles",
      "- c-break.ps1 -Path <projet> -FixCycles : Corrige automatiquement les cycles détectés",
      "- c-break.ps1 -Path <projet> -OutputPath <rapport> : Génère un rapport détaillé",
      "- c-break.ps1 -Path <projet> -Algorithm <DFS|TARJAN|JOHNSON> : Choix de l'algorithme de détection",
      "## Fonctionnement",
      "- Analyse les dépendances (import, require, using, etc.) pour plusieurs langages (PowerShell, Python, JS/TS, C#, Java)",
      "- Détecte les cycles via DFS, Tarjan ou Johnson",
      "- Propose des stratégies de résolution : extraction d'interface, inversion de dépendance, médiateur, refactorisation",
      "- Génère des graphes (DOT, Mermaid, PlantUML, JSON) et rapports HTML/JSON",
      "- Peut corriger automatiquement certains cycles selon la stratégie choisie",
      "## Bonnes pratiques",
      "- Exécuter C-BREAK régulièrement pendant le développement",
      "- Intégrer C-BREAK dans les hooks pre-commit",
      "- Analyser en priorité les fichiers modifiés ou les sous-répertoires critiques",
      "- Examiner manuellement les corrections proposées avant application",
      "- Documenter les choix d'architecture pour éviter la réintroduction de cycles",
      "## Intégration avec les autres modes",
      "- ARCHI : Pour concevoir une architecture sans dépendances circulaires",
      "- REVIEW : Pour vérifier l'absence de cycles lors des revues de code",
      "- OPTI : Pour optimiser le code en éliminant les cycles",
      "- CHECK : Vérifie l'absence de cycles avant de valider une tâche",
      "- DEBUG : Utilise C-BREAK pour diagnostiquer les problèmes liés aux dépendances",
      "- DEV-R : Applique C-BREAK avant de livrer une fonctionnalité",
      "## Exemples d’utilisation",
      "```powershell",
      "# Détecter les cycles dans un projet",
      ".\\development\\tools\\scripts\\c-break.ps1 -Path \"D:\\MonProjet\" -Verbose",
      "# Corriger automatiquement les cycles",
      ".\\development\\tools\\scripts\\c-break.ps1 -Path \"D:\\MonProjet\" -FixCycles -FixStrategy INVERSION",
      "# Générer un rapport détaillé",
      ".\\development\\tools\\scripts\\c-break.ps1 -Path \"D:\\MonProjet\" -OutputPath \"D:\\Rapports\\cycles.json\" -Algorithm TARJAN",
      "```"
    ],
    "description": "Insère le template du mode C-BREAK."
  }
}
```
