# Mode DEBUG

## Description

Le mode DEBUG est un mode opérationnel conçu pour faciliter la détection, l'analyse et la correction des bugs dans le code. Il fournit des outils avancés pour analyser les erreurs, inspecter les variables, tracer l'exécution du code et simuler différents contextes d'exécution.

## Objectifs

- Détecter et analyser les erreurs dans le code
- Fournir des informations détaillées sur les stack traces
- Faciliter la compréhension des causes racines des bugs
- Suggérer des corrections pour les erreurs détectées
- Générer des cas de test pour valider les corrections

## Fonctionnalités

### Analyse d'erreurs

Le mode DEBUG offre plusieurs fonctionnalités pour analyser les erreurs :

1. **Analyse de stack trace** : Parse et analyse les stack traces PowerShell pour extraire les informations pertinentes.
2. **Extraction d'informations de ligne et fichier** : Identifie les fichiers et les lignes où les erreurs se produisent.
3. **Résolution des chemins de fichiers** : Résout les chemins relatifs ou incomplets dans les stack traces.
4. **Analyse de la séquence d'appels** : Visualise la séquence d'appels qui a conduit à l'erreur.
5. **Visualisation hiérarchique** : Génère une représentation visuelle de la stack trace pour faciliter la compréhension.

### Inspection de variables

Le mode DEBUG permet d'inspecter les variables de différentes manières :

1. **Inspection détaillée** : Affiche les propriétés et les valeurs des variables.
2. **Analyse de structure d'objets** : Explore la structure des objets complexes.
3. **Comparaison d'états** : Compare les états des variables avant et après une opération.
4. **Visualisation d'objets complexes** : Représente graphiquement les objets complexes.
5. **Détection de modifications** : Identifie les changements dans les variables au cours de l'exécution.

### Traçage d'exécution

Le mode DEBUG offre des fonctionnalités pour tracer l'exécution du code :

1. **Traçage de flux d'exécution** : Suit le chemin d'exécution du code.
2. **Points de trace configurables** : Permet de définir des points de trace dans le code.
3. **Mesure de temps d'exécution** : Mesure le temps d'exécution des différentes parties du code.
4. **Visualisation du flux d'exécution** : Représente graphiquement le flux d'exécution.
5. **Filtrage de trace** : Filtre les traces pour se concentrer sur les informations pertinentes.

### Simulation de contexte

Le mode DEBUG permet de simuler différents contextes d'exécution :

1. **Environnements virtuels** : Simule différents environnements d'exécution.
2. **Simulation d'entrées/sorties** : Simule les entrées utilisateur et les sorties console.
3. **Simulation d'erreurs** : Injecte des erreurs contrôlées pour tester la robustesse du code.
4. **Simulation de charge** : Simule des conditions de charge et de stress.
5. **Reproduction de bugs** : Facilite la reproduction des bugs pour les analyser.

## Utilisation

### Syntaxe

```powershell
.\debug-mode.ps1 -FilePath <string> [-TaskIdentifier <string>] -ErrorLog <string> -ScriptPath <string> [-OutputPath <string>] [-GeneratePatch <bool>] [-IncludeStackTrace <bool>] [-MaxStackTraceDepth <int>] [-AnalyzePerformance <bool>] [-SuggestFixes <bool>] [-SimulateContext <bool>]
```

### Paramètres

| Paramètre | Description | Obligatoire | Valeur par défaut |
|-----------|-------------|-------------|-------------------|
| FilePath | Chemin vers le fichier de roadmap à traiter. | Oui | - |
| TaskIdentifier | Identifiant de la tâche à traiter. | Non | - |
| ErrorLog | Chemin vers le fichier de log d'erreurs à analyser. | Oui | - |
| ScriptPath | Chemin vers le script ou le module à déboguer. | Oui | - |
| OutputPath | Chemin où seront générés les fichiers de sortie. | Non | Répertoire courant |
| GeneratePatch | Indique si un patch correctif doit être généré. | Non | $true |
| IncludeStackTrace | Indique si les traces de pile doivent être incluses dans l'analyse. | Non | $true |
| MaxStackTraceDepth | Profondeur maximale des traces de pile à analyser. | Non | 10 |
| AnalyzePerformance | Indique si les performances doivent être analysées. | Non | $false |
| SuggestFixes | Indique si des suggestions de correction doivent être générées. | Non | $true |
| SimulateContext | Indique si le contexte d'exécution doit être simulé. | Non | $false |

### Exemples

#### Analyser un fichier de log d'erreurs

```powershell
.\debug-mode.ps1 -FilePath "roadmap.md" -ErrorLog "error.log" -ScriptPath "scripts" -OutputPath "output"
```

#### Analyser une tâche spécifique avec analyse de performance

```powershell
.\debug-mode.ps1 -FilePath "roadmap.md" -TaskIdentifier "1.2.3" -ErrorLog "error.log" -ScriptPath "scripts" -AnalyzePerformance $true
```

#### Générer un patch correctif sans inclure les traces de pile

```powershell
.\debug-mode.ps1 -FilePath "roadmap.md" -ErrorLog "error.log" -ScriptPath "scripts" -GeneratePatch $true -IncludeStackTrace $false
```

#### Simuler un contexte d'exécution

```powershell
.\debug-mode.ps1 -FilePath "roadmap.md" -ErrorLog "error.log" -ScriptPath "scripts" -SimulateContext $true
```

## Sorties

Le mode DEBUG génère plusieurs fichiers de sortie :

1. **debug_report.md** : Rapport détaillé des erreurs détectées et des suggestions de correction.
2. **fix_patch.ps1** : Script de correctif pour résoudre les erreurs détectées.
3. **test_cases.json** : Cas de test pour valider les corrections.

## Intégration avec d'autres modes

Le mode DEBUG peut être utilisé en combinaison avec d'autres modes :

- **Mode TEST** : Pour valider les corrections avec des tests automatisés.
- **Mode REVIEW** : Pour vérifier la qualité du code corrigé.
- **Mode C-BREAK** : Pour détecter et résoudre les dépendances circulaires qui peuvent causer des bugs.

## Fonctions d'analyse de stack trace

Le mode DEBUG inclut plusieurs fonctions pour analyser les stack traces :

### Get-StackTraceInfo

Parse une stack trace PowerShell et extrait les informations pertinentes.

```powershell
$error[0] | Get-StackTraceInfo
```

### Get-StackTraceLineInfo

Extrait les informations de ligne et de fichier à partir d'une stack trace.

```powershell
$error[0] | Get-StackTraceLineInfo -ContextLines 3
```

### Resolve-StackTracePaths

Résout les chemins de fichiers dans une stack trace.

```powershell
$error[0] | Resolve-StackTracePaths -BasePath "C:\Projects\MyProject"
```

### Get-StackTraceCallSequence

Analyse la séquence d'appels dans une stack trace.

```powershell
$error[0] | Get-StackTraceCallSequence
```

### Show-StackTraceHierarchy

Génère une visualisation hiérarchique d'une stack trace.

```powershell
$error[0] | Show-StackTraceHierarchy -Format HTML -IncludeLineContent $true
```

## Bonnes pratiques

1. **Utiliser des fichiers de log détaillés** : Plus les logs sont détaillés, plus l'analyse sera précise.
2. **Inclure les stack traces** : Les stack traces fournissent des informations précieuses pour l'analyse des erreurs.
3. **Analyser les performances** : L'analyse des performances peut révéler des problèmes qui ne sont pas évidents dans les logs d'erreurs.
4. **Valider les corrections** : Toujours valider les corrections avec des tests automatisés.
5. **Documenter les bugs** : Documenter les bugs et leurs solutions pour faciliter la résolution de problèmes similaires à l'avenir.

## Limitations

- L'analyse des stack traces est limitée aux stack traces PowerShell.
- La simulation de contexte peut ne pas reproduire exactement les conditions réelles.
- Les suggestions de correction sont basées sur des patterns connus et peuvent ne pas être adaptées à tous les cas.
- L'analyse des performances est limitée aux métriques de base et peut ne pas détecter tous les problèmes de performance.

## Conclusion

Le mode DEBUG est un outil puissant pour détecter, analyser et corriger les bugs dans le code. En utilisant ses fonctionnalités avancées, vous pouvez gagner du temps et améliorer la qualité de votre code.
