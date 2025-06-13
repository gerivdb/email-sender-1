# Plan d'amélioration des modes opérationnels v2.0

*Version 2025-05-25 - Progression globale : 35%*

Ce plan définit l'implémentation et l'amélioration des modes opérationnels pour le projet EMAIL_SENDER_1, avec une approche modulaire et des commandes standardisées.

## 1. Commandes universelles (applicables à tous les modes)

| Commande | Description | Exemple |
|----------|-------------|---------|
| `RUN` | Exécute le mode sur la cible spécifiée | `RUN GRAN roadmap.md` |
| `CHECK` | Vérifie l'état d'avancement | `CHECK TEST` |
| `DEBUG` | Débogue le mode ou la cible | `DEBUG OPTI` |
| `TEST` | Exécute les tests du mode | `TEST DEV-R` |
| `HELP` | Affiche l'aide du mode | `HELP ARCHI` |
| `COMBO` | Exécute une séquence de modes | `COMBO DEV-R,TEST,DEBUG` |
| `SAVE` | Sauvegarde l'état actuel | `SAVE` |
| `LOAD` | Charge un état sauvegardé | `LOAD checkpoint1` |
| `ABORT` | Annule l'opération en cours | `ABORT` |
| `LOG` | Affiche ou configure les logs | `LOG LEVEL=DEBUG` |

## 2. Modes opérationnels principaux

### 2.1 Modes d'analyse et planification

#### GRAN - Granularisation des tâches

- **Objectif**: Décomposer les tâches complexes en sous-tâches gérables
- **Commandes spécifiques**:
  - `GRAN DEPTH=2` - Définit la profondeur de granularisation
  - `GRAN AUTO` - Granularisation automatique basée sur la complexité
  - `GRAN MERGE` - Fusionne des tâches granularisées
  - `GRAN REORDER` - Réorganise les tâches granularisées
  - `GRAN EXPORT` - Exporte la structure granularisée

#### ARCHI - Architecture et conception

- **Objectif**: Concevoir et modéliser l'architecture du système
- **Commandes spécifiques**:
  - `ARCHI DIAGRAM` - Génère un diagramme d'architecture
  - `ARCHI DEPS` - Analyse les dépendances
  - `ARCHI PATTERN=MVC` - Applique un pattern architectural
  - `ARCHI VALIDATE` - Valide l'architecture
  - `ARCHI REFACTOR` - Propose des refactorisations architecturales

#### PREDIC - Analyse prédictive

- **Objectif**: Anticiper les performances et anomalies
- **Commandes spécifiques**:
  - `PREDIC PERF` - Prédit les performances
  - `PREDIC RISK` - Identifie les risques potentiels
  - `PREDIC TREND` - Analyse les tendances
  - `PREDIC SIMULATE` - Simule des scénarios
  - `PREDIC ALERT` - Configure des alertes prédictives

### 2.2 Modes de développement et qualité

#### DEV-R - Développement séquentiel

- **Objectif**: Implémenter les tâches de manière séquentielle
- **Commandes spécifiques**:
  - `DEV-R NEXT` - Passe à la tâche suivante
  - `DEV-R IMPL` - Implémente la tâche courante
  - `DEV-R SKIP` - Ignore la tâche courante
  - `DEV-R BACK` - Revient à la tâche précédente
  - `DEV-R STATUS` - Affiche l'état d'avancement

#### TEST - Tests automatisés

- **Objectif**: Vérifier l'implémentation avec des tests
- **Commandes spécifiques**:
  - `TEST UNIT` - Exécute les tests unitaires
  - `TEST INTEG` - Exécute les tests d'intégration
  - `TEST COV` - Analyse la couverture de code
  - `TEST GEN` - Génère des tests automatiquement
  - `TEST FIX` - Corrige les tests qui échouent

#### DEBUG - Résolution de bugs

- **Objectif**: Identifier et corriger les problèmes
- **Commandes spécifiques**:
  - `DEBUG TRACE` - Active le traçage détaillé
  - `DEBUG BREAK` - Définit un point d'arrêt
  - `DEBUG STEP` - Exécute pas à pas
  - `DEBUG VAR` - Inspecte les variables
  - `DEBUG FIX` - Applique une correction

#### REVIEW - Vérification de qualité

- **Objectif**: Vérifier la qualité du code
- **Commandes spécifiques**:
  - `REVIEW STYLE` - Vérifie le style de code
  - `REVIEW SOLID` - Vérifie les principes SOLID
  - `REVIEW COMPLEX` - Analyse la complexité
  - `REVIEW DUPL` - Détecte les duplications
  - `REVIEW SEC` - Analyse les vulnérabilités

### 2.3 Modes d'optimisation et spécialisés

#### OPTI - Optimisation des performances

- **Objectif**: Améliorer les performances du système
- **Commandes spécifiques**:
  - `OPTI CPU` - Optimise l'utilisation CPU
  - `OPTI MEM` - Optimise l'utilisation mémoire
  - `OPTI IO` - Optimise les opérations d'E/S
  - `OPTI ALGO` - Optimise les algorithmes
  - `OPTI PARALLEL` - Parallélise les opérations

#### C-BREAK - Résolution de dépendances circulaires

- **Objectif**: Détecter et corriger les cycles de dépendances
- **Commandes spécifiques**:
  - `C-BREAK DETECT` - Détecte les dépendances circulaires
  - `C-BREAK VISUAL` - Visualise les cycles
  - `C-BREAK SOLVE` - Propose des solutions
  - `C-BREAK REFACTOR` - Refactorise pour éliminer les cycles
  - `C-BREAK MONITOR` - Surveille l'apparition de nouveaux cycles

#### GIT - Gestion de version

- **Objectif**: Automatiser les opérations Git
- **Commandes spécifiques**:
  - `GIT COMMIT` - Crée un commit thématique
  - `GIT PUSH` - Pousse les changements
  - `GIT SYNC` - Synchronise avec le dépôt distant
  - `GIT BRANCH` - Gère les branches
  - `GIT REVERT` - Annule des changements

## 3. Flux de travail recommandés

### 3.1 Flux de développement standard

```plaintext
GRAN → DEV-R → TEST → DEBUG → REVIEW → GIT
```plaintext
### 3.2 Flux d'optimisation

```plaintext
PREDIC → OPTI → TEST → DEBUG → REVIEW → GIT
```plaintext
### 3.3 Flux de refactorisation

```plaintext
ARCHI → C-BREAK → DEV-R → TEST → DEBUG → GIT
```plaintext
## 4. Intégration avec les outils externes

### 4.1 Intégration n8n

- Workflows automatisés pour chaque mode
- Déclencheurs basés sur les événements Git
- Actions personnalisées pour chaque commande

### 4.2 Intégration VS Code

- Extension avec palette de commandes
- Visualisation des résultats dans l'éditeur
- Raccourcis clavier pour les commandes fréquentes

### 4.3 Intégration Augment

- Modes spécialisés pour l'IA
- Commandes vocales pour les opérations courantes
- Analyse contextuelle pour les suggestions

## 5. Implémentation technique

### 5.1 Structure des scripts PowerShell

```powershell
# Structure commune à tous les modes

param (
    [Parameter(Mandatory=$true)]
    [string]$Command,

    [Parameter(Mandatory=$false)]
    [string]$Target,

    [Parameter(Mandatory=$false)]
    [hashtable]$Options = @{}
)

# Chargement du module commun

Import-Module ModesCommon

# Traitement de la commande

switch ($Command) {
    "RUN"    { Invoke-ModeRun -Target $Target -Options $Options }
    "CHECK"  { Get-ModeStatus -Target $Target -Options $Options }
    "DEBUG"  { Start-ModeDebug -Target $Target -Options $Options }
    "TEST"   { Invoke-ModeTest -Target $Target -Options $Options }
    "HELP"   { Get-ModeHelp -Target $Target -Options $Options }
    default  { Write-Error "Commande non reconnue: $Command" }
}
```plaintext
### 5.2 Module commun ModesCommon

- Fonctions partagées entre tous les modes
- Gestion de la configuration
- Journalisation standardisée
- Gestion des erreurs unifiée
- Mécanismes de communication inter-modes

### 5.3 Stockage d'état

- Format JSON pour la persistance
- Structure hiérarchique par mode et cible
- Versionnement des états
- Mécanismes de restauration
- Synchronisation entre sessions

### 5.4 Génération avec Hygen

- Templates pour tous les composants des modes
- Génération automatisée des scripts, tests et documentation
- Hooks personnalisés pour l'intégration avec l'environnement
- Prompts interactifs pour la configuration
- Injection de dépendances automatique

## 6. Plan d'implémentation

### 6.1 Phase 1: Fondations (2 semaines)

- [x] Analyse des modes existants
- [x] Conception de l'architecture commune
- [ ] Configuration de Hygen et création des templates de base
  - [ ] Installation et configuration de Hygen
  - [ ] Création des templates pour les modes opérationnels
  - [ ] Développement des helpers et hooks personnalisés
  - [ ] Tests de génération automatisée
  - [ ] Documentation des templates
- [ ] Implémentation du module ModesCommon
- [ ] Standardisation des interfaces de commande
- [ ] Tests unitaires des composants fondamentaux

### 6.2 Phase 2: Modes principaux (3 semaines)

- [x] Implémentation des modes GRAN et CHECK
- [x] Implémentation des modes ARCHI et DEBUG
- [ ] Implémentation des modes DEV-R et TEST
- [ ] Implémentation des modes REVIEW et OPTI
- [ ] Tests d'intégration entre modes

### 6.3 Phase 3: Modes spécialisés (2 semaines)

- [ ] Implémentation des modes C-BREAK et PREDIC
- [ ] Implémentation des modes GIT et UI
- [ ] Implémentation des modes DB et SECURE
- [ ] Implémentation du mode META (orchestrateur)
- [ ] Tests système complets

### 6.4 Phase 4: Intégrations (1 semaine)

- [ ] Intégration avec n8n
- [ ] Intégration avec VS Code
- [ ] Intégration avec Augment
- [ ] Documentation complète
- [ ] Formation des utilisateurs

## 7. Commandes combinées et raccourcis

### 7.1 Commandes Git fréquentes

| Commande | Description | Équivalent |
|----------|-------------|------------|
| `GIT ACP` | Add, commit, push | `git add . && git commit -m "msg" && git push --no-verify` |
| `GIT SYNC` | Synchronise avec le dépôt distant | `git pull && git push --no-verify` |
| `GIT UNDO` | Annule le dernier commit | `git reset --soft HEAD~1` |
| `GIT CHECK` | Vérifie l'état du dépôt | `git status && git log --oneline -n 3` |
| `GIT CLEAN` | Nettoie les fichiers non suivis | `git clean -fd` |

### 7.2 Commandes de test et débogage

| Commande | Description | Action |
|----------|-------------|--------|
| `TEST ALL` | Exécute tous les tests | Lance la suite complète de tests |
| `TEST FAST` | Exécute les tests rapides | Lance uniquement les tests unitaires |
| `DEBUG LAST` | Débogue le dernier test échoué | Relance en mode debug le dernier test échoué |
| `DEBUG COV` | Analyse la couverture manquante | Identifie le code non couvert par les tests |
| `DEBUG MOCK` | Améliore les mocks | Génère ou améliore les mocks pour les tests |

### 7.3 Workflows complets

| Commande | Description | Séquence |
|----------|-------------|----------|
| `FLOW DEV` | Cycle de développement complet | `GRAN → DEV-R → TEST → DEBUG → GIT ACP` |
| `FLOW FIX` | Cycle de correction de bug | `DEBUG → TEST → REVIEW → GIT ACP` |
| `FLOW REFACTOR` | Cycle de refactorisation | `ARCHI → C-BREAK → OPTI → TEST → GIT ACP` |
| `FLOW RELEASE` | Préparation de release | `TEST ALL → REVIEW → PREDIC → GIT TAG` |
| `FLOW HOTFIX` | Correction d'urgence | `DEBUG → TEST FAST → GIT ACP → GIT SYNC` |

## 8. Bonnes pratiques

### 8.1 Principes généraux

- Utiliser des commandes courtes et explicites
- Privilégier les combinaisons de modes pour les tâches complexes
- Sauvegarder l'état régulièrement avec `SAVE`
- Documenter les workflows personnalisés
- Automatiser les séquences répétitives

### 8.2 Conventions de nommage

- Commandes en MAJUSCULES
- Options en CamelCase
- Cibles en minuscules avec chemins relatifs
- Points de sauvegarde avec préfixe de date (YYYYMMDD_)
- Messages de commit avec préfixe de mode ([DEV], [FIX], etc.)

### 8.3 Gestion des erreurs

- Utiliser `DEBUG` immédiatement après un échec
- Conserver les logs avec `LOG SAVE=filename`
- Restaurer à un point connu avec `LOAD` en cas de problème
- Utiliser `ABORT` pour interrompre proprement une opération
- Consulter `HELP` pour les options de dépannage spécifiques
