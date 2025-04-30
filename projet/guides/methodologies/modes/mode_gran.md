# Mode GRAN

## Description
Le mode GRAN (Granularisation) est un mode opérationnel qui décompose les tâches complexes en sous-tâches plus petites et plus faciles à gérer. Il peut adapter le niveau de granularité en fonction de la complexité de la tâche et du domaine technique concerné.

## Objectif
L'objectif principal du mode GRAN est de faciliter la gestion de tâches complexes en les décomposant en unités de travail plus petites, plus précises et plus faciles à estimer. La granularisation variable permet d'éviter de devoir granulariser plusieurs fois la même tâche.

## Fonctionnalités
- Décomposition des tâches complexes en sous-tâches
- Ajout automatique de sous-tâches à partir de modèles
- Adaptation du nombre de sous-tâches selon la complexité
- Détection automatique de la complexité des tâches
- Détection automatique du domaine technique des tâches
- Utilisation de modèles spécifiques aux domaines techniques
- Mise à jour de la roadmap avec les nouvelles sous-tâches

## Utilisation

```powershell
# Granulariser une tâche spécifique (détection automatique de la complexité et du domaine)
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"

# Granulariser une tâche avec un niveau de complexité spécifique
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -ComplexityLevel "Complex"

# Granulariser une tâche avec un domaine spécifique
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -Domain "Frontend"

# Granulariser une tâche avec plusieurs domaines (combinaison de modèles)
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -Domain "Frontend,Backend"

# Granulariser une tâche avec un modèle de sous-tâches personnalisé
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -SubTasksFile "templates\subtasks.txt"

# Granulariser une tâche avec des estimations de temps
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -AddTimeEstimation

# Granulariser une tâche avec des estimations de temps et un domaine spécifique
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -AddTimeEstimation -Domain "Backend"

# Granulariser une tâche en utilisant l'IA pour générer des sous-tâches
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -UseAI

# Utiliser le mode-manager pour exécuter le mode GRAN
.\development\scripts\mode-manager\mode-manager.ps1 -Mode GRAN -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"
```

## Niveaux de complexité
Le mode GRAN prend en charge trois niveaux de complexité, chacun avec un modèle de sous-tâches adapté :

### Simple (3 sous-tâches)
```
Analyser les besoins
Implémenter la solution
Tester la fonctionnalité
```

### Medium (5 sous-tâches)
```
Analyser les besoins
Concevoir l'architecture
Implémenter le code
Tester la fonctionnalité
Documenter l'implémentation
```

### Complex (10 sous-tâches)
```
Analyser les besoins détaillés
Identifier les risques potentiels
Concevoir l'architecture globale
Concevoir les composants spécifiques
Implémenter les interfaces
Implémenter la logique métier
Implémenter les tests unitaires
Exécuter les tests d'intégration
Optimiser les performances
Documenter l'implémentation
```

## Domaines techniques
Le mode GRAN prend en charge des modèles spécifiques à différents domaines techniques :

### Frontend (9 sous-tâches)
```
Analyser les besoins d'interface utilisateur
Créer les maquettes et wireframes
Implémenter la structure HTML
Développer les styles CSS
Implémenter les interactions JavaScript
Optimiser pour différents appareils (responsive)
Tester sur différents navigateurs
Optimiser les performances frontend
Documenter les composants UI
```

### Backend (10 sous-tâches)
```
Analyser les besoins d'API
Concevoir le modèle de données
Implémenter les modèles et migrations
Développer les contrôleurs et services
Implémenter les routes et endpoints
Ajouter la validation et gestion d'erreurs
Implémenter l'authentification et autorisation
Optimiser les requêtes de base de données
Tester les endpoints API
Documenter l'API
```

### Database (9 sous-tâches)
```
Analyser les besoins de stockage
Concevoir le schéma de base de données
Définir les relations entre tables
Implémenter les contraintes et index
Créer les procédures stockées et triggers
Optimiser les requêtes et performances
Implémenter la stratégie de sauvegarde
Tester les performances sous charge
Documenter le schéma et les procédures
```

### Testing (9 sous-tâches)
```
Analyser les exigences de test
Définir les cas de test
Implémenter les tests unitaires
Développer les tests d'intégration
Créer les tests de bout en bout
Mettre en place les tests de performance
Automatiser l'exécution des tests
Analyser la couverture de code
Documenter les procédures de test
```

### DevOps (9 sous-tâches)
```
Analyser les besoins d'infrastructure
Configurer l'environnement de développement
Mettre en place l'intégration continue
Configurer le déploiement continu
Implémenter la surveillance et les alertes
Configurer les sauvegardes automatiques
Optimiser les performances du système
Mettre en place la gestion des logs
Documenter les procédures d'exploitation
```

### Security (9 sous-tâches)
```
Analyser les exigences de sécurité
Identifier les vulnérabilités potentielles
Concevoir l'architecture de sécurité
Implémenter les mécanismes d'authentification
Mettre en place le chiffrement des données
Développer les contrôles d'accès
Effectuer des tests de pénétration
Mettre en place la surveillance de sécurité
Documenter les politiques et procédures de sécurité
```

### AI-ML (10 sous-tâches)
```
Analyser les besoins en intelligence artificielle
Collecter et préparer les données d'entraînement
Concevoir le modèle d'apprentissage
Développer les algorithmes d'IA/ML
Entraîner le modèle avec les données
Évaluer les performances du modèle
Optimiser les hyperparamètres
Déployer le modèle en production
Mettre en place le monitoring du modèle
Documenter l'architecture et les résultats
```

### Documentation (9 sous-tâches)
```
Analyser les besoins en documentation
Définir la structure et le format des documents
Rédiger la documentation technique
Créer les guides d'utilisation
Développer les exemples et tutoriels
Intégrer les captures d'écran et diagrammes
Mettre en place un système de versionnage
Réviser et valider le contenu
Publier la documentation
```

## Combinaison de modèles
Le mode GRAN permet de combiner plusieurs modèles de domaines pour les tâches qui touchent à plusieurs domaines techniques. Par exemple, pour une tâche qui concerne à la fois le frontend et le backend, vous pouvez spécifier plusieurs domaines séparés par des virgules :

```powershell
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -Domain "Frontend,Backend"
```

Le script combinera intelligemment les modèles des deux domaines pour créer un ensemble de sous-tâches qui couvre les aspects des deux domaines.

## Estimations de temps
Le mode GRAN peut ajouter des estimations de temps aux sous-tâches générées. Ces estimations sont calculées en fonction de la complexité de la tâche, du domaine technique et du type de sous-tâche (analyse, conception, implémentation, test, documentation).

Pour activer les estimations de temps, utilisez le paramètre `-AddTimeEstimation` :

```powershell
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -AddTimeEstimation
```

Les estimations de temps sont affichées entre crochets à la fin de chaque sous-tâche, par exemple :

```
- [ ] **1.2.3.1** Analyser les besoins [⏱️ 2 h]
- [ ] **1.2.3.2** Concevoir l'architecture [⏱️ 3 h]
- [ ] **1.2.3.3** Implémenter le code [⏱️ 4 h]
```

## Génération de sous-tâches par IA
Le mode GRAN peut utiliser l'intelligence artificielle pour générer des sous-tâches adaptées au contexte de la tâche principale. Cette fonctionnalité utilise OpenRouter pour accéder à différents modèles d'IA.

### Configuration de l'API OpenRouter

Avant d'utiliser la fonctionnalité d'IA, vous devez configurer votre clé API OpenRouter. Vous pouvez le faire de plusieurs façons :

1. **Utiliser le script d'initialisation** :

```powershell
.\development\scripts\maintenance\init-openrouter.ps1 -ApiKey "votre-clé-api" -Model "qwen/qwen3-32b:free"
```

2. **Passer la clé API directement au script** :

```powershell
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -UseAI -ApiKey "votre-clé-api"
```

3. **Définir la variable d'environnement** :

```powershell
[Environment]::SetEnvironmentVariable("OPENROUTER_API_KEY", "votre-clé-api", "Process")
```

### Utilisation de l'IA pour générer des sous-tâches

Pour activer la génération de sous-tâches par IA, utilisez le paramètre `-UseAI` :

```powershell
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -UseAI
```

L'IA analysera le contenu de la tâche principale et générera des sous-tâches spécifiques au contexte, en tenant compte de la complexité et du domaine technique détectés.

### Choix du modèle d'IA

Vous pouvez spécifier le modèle d'IA à utiliser avec le paramètre `-Model` :

```powershell
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -UseAI -Model "qwen/qwen3-32b:free"
```

Les modèles disponibles incluent :
- `qwen/qwen3-32b:free` (par défaut)
- `openai/gpt-3.5-turbo`
- `anthropic/claude-3-haiku`
- `google/gemini-pro`
- `mistral/mistral-medium`

### Mode simulation

Pour tester la fonctionnalité sans utiliser l'API (et donc sans consommer de crédits), vous pouvez utiliser le mode simulation :

```powershell
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -UseAI -SimulateAI
```

Ce mode génère des sous-tâches prédéfinies en fonction du domaine et de la complexité, sans appeler l'API.

## Intégration avec d'autres modes
Le mode GRAN peut être utilisé en combinaison avec d'autres modes :
- **DEV-R** : Pour décomposer les tâches avant de commencer le développement
- **ARCHI** : Pour décomposer les tâches d'architecture en composants plus petits
- **CHECK** : Pour vérifier l'état d'avancement des sous-tâches

## Implémentation
Le mode GRAN est implémenté dans le script gran-mode.ps1 qui se trouve dans le dossier development\scripts\maintenance\modes\.

## Exemple de granularisation
Avant :
`
- [ ] **1.3** Implémenter la fonctionnalité C
`

Après :
`
- [ ] **1.3** Implémenter la fonctionnalité C
  - [ ] **1.3.1** Analyser les besoins
  - [ ] **1.3.2** Concevoir l'architecture
  - [ ] **1.3.3** Implémenter le code
  - [ ] **1.3.4** Tester la fonctionnalité
  - [ ] **1.3.5** Documenter l'implémentation
`

## Bonnes pratiques
- Décomposer les tâches en sous-tâches qui prennent moins d'une journée à réaliser
- Utiliser des modèles de sous-tâches pour assurer la cohérence
- Estimer la complexité de chaque sous-tâche
- Mettre à jour la roadmap après la granularisation
- Granulariser les tâches juste avant de commencer à les travailler
