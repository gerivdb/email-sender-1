Je vais créer un plan de développement détaillé pour l'écosystème modulaire de gestion des roadmaps, en respectant les instructions fournies et en appliquant les principes DRY, KISS, et SOLID. Le plan sera structuré en Markdown, avec une granularité élevée (phases, sous-étapes, micro-étapes, nano-étapes), des tests unitaires, des dry-runs, et des intégrations claires avec les modules mentionnés (Parsing, DB, CLI, API, Meta-Roadmap). Les scripts seront principalement en Go pour la performance et la simplicité, avec des configurations YAML et une intégration PostgreSQL via QDrant pour le RAG.

---

```markdown
# Plan de développement v51 - Écosystème modulaire pour harmonisation des roadmaps
*Version 1.0 - 2025-06-06 - Progression globale : 0%*

Ce plan détaille l'implémentation d'un écosystème modulaire pour harmoniser les fichiers de roadmap Markdown dans `projet/roadmaps/plans/consolidated`, gérer les tâches via une base PostgreSQL avec QDrant, exposer les tâches via une API REST (FastAPI), et générer un meta-roadmap centralisé. L'écosystème respecte les principes DRY, KISS, et SOLID, avec une architecture modulaire et des tests unitaires pour chaque composant.

## Table des matières
- [1] Phase 1: Module Parsing
- [2] Phase 2: Module DB
- [3] Phase 3: Module CLI
- [4] Phase 4: Module API
- [5] Phase 5: Module Meta-Roadmap
- [6] Phase 6: Documentation et Intégration CI/CD
- [7] Phase 7: Validation Finale et Déploiement

## Phase 1: Module Parsing
*Progression: 0%*

### 1.1 Développement du script de parsing
*Progression: 0%*

#### 1.1.1 Analyse des fichiers Markdown
*Progression: 0%*

##### 1.1.1.1 Implémentation de `ParseMarkdown` en Go
- [ ] Développer `ParseMarkdown` dans `pkg/parsing/parser.go` pour extraire les tâches des fichiers `.md`
  - [ ] Extraire les sections (phases, sous-étapes, micro-étapes, nano-étapes) via regex et parsing hiérarchique
  - [ ] Créer une structure `Task` avec champs : `ID`, `Title`, `Description`, `Progress`, `Dependencies`
  - [ ] Valider le format Markdown (cases à cocher `[ ]` ou `[x]`, pourcentages)
- [ ] Utiliser `go-yaml` pour charger les configurations de parsing
- [ ] Implémenter un dry-run pour lister les tâches sans modification

**Tests unitaires**:
- Cas nominal : Parser un fichier `.md` avec 3 niveaux de tâches
- Cas limite : Parser un fichier vide ou mal formaté
- Erreur simulée : Simuler un fichier corrompu (syntaxe Markdown invalide)
- Dry-run : Vérifier que `ParseMarkdown` retourne une liste de tâches sans écrire sur disque

**Exemple de code**:
```go
package parsing

type Task struct {
    ID          string   `json:"id"`
    Title       string   `json:"title"`
    Description string   `json:"description"`
    Progress    int      `json:"progress"`
    Dependencies []string `json:"dependencies"`
}

func ParseMarkdown(ctx context.Context, filePath string, config *Config) ([]Task, error) {
    content, err := os.ReadFile(filePath)
    if err != nil {
        return nil, fmt.Errorf("failed to read file: %v", err)
    }
    tasks := parseTasks(content) // Implémentation regex/hierarchique
    if config.DryRun {
        log.Printf("Dry-run: %d tasks parsed from %s", len(tasks), filePath)
        return tasks, nil
    }
    return tasks, nil
}
```

##### 1.1.1.2 Configuration du parsing
- [ ] Créer `parsing_config.yaml` pour définir les regex et les règles de parsing
  - [ ] Définir `task_regex` pour extraire les cases à cocher et pourcentages
  - [ ] Définir `max_depth` pour limiter la profondeur des tâches
- [ ] Valider la configuration via unintregration avec QDrant pour la recherche vectorielle
- [ ] Exécuter un dry-run pour valider la configuration sans modification de la base

**Tests unitaires**:
- Cas nominal : Charger une configuration YAML valide
- Cas limite : Charger une configuration vide ou mal formatée
- Erreur simulée : Simuler une regex invalide

**Exemple de configuration**:
```yaml
version: 1.0
parsing:
  task_regex: "^\\s*- \\[( |x)\\]\\s*(.*?)\\s*\\*Progression: (\\d+)%\\*"
  max_depth: 4
qdrant:
  url: http://qdrant:6333
  api_key: your-qdrant-key
```

#### 1.1.2 Gestion des dépendances
*Progression: 0%*

##### 1.1.2.1 Analyse des dépendances entre tâches
- [ ] Implémenter `AnalyzeDependencies` pour identifier les dépendances des tâches
  - [ ] Extraire les références aux autres tâches dans `Description`
  - [ ] Construire un graphe de dépendances
- [ ] Valider les dépendances via un dry-run

**Tests unitaires**:
- Cas nominal : Identifier les dépendances dans un fichier `.md` avec 5 tâches
- Cas limite : Gérer les dépendances circulaires
- Erreur simulée : Simuler une tâche avec une dépendance inexistante

**Mise à jour**:
- [ ] Mettre à jour `plan-dev-v25-meta-roadmap-sync-updated.md` en cochant les tâches terminées
- [ ] Ajuster les pourcentages de progression pour la Phase 1

## Phase 2: Module DB
*Progression: 0%*

### 2.1 Intégration avec PostgreSQL
*Progression: 0%*

#### 2.1.1 Création du schéma de base de données
- [ ] Définir la table `tasks` dans `schema.sql`
  - [ ] Champs : `id` (UUID), `title` (VARCHAR), `description` (TEXT), `progress` (INT), `dependencies` (JSONB)
  - [ ] Index sur `id` et `progress` pour optimiser les requêtes
- [ ] Implémenter `StoreTasks` dans `pkg/db/postgres.go` pour stocker les tâches
- [ ] Exécuter un dry-run pour valider l'insertion sans écrire

**Tests unitaires**:
- Cas nominal : Insérer 10 tâches dans PostgreSQL
- Cas limite : Insérer une tâche avec des données manquantes
- Erreur simulée : Simuler une connexion DB échouée

**Exemple de schéma**:
```sql
CREATE TABLE tasks (
    id UUID PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    progress INT DEFAULT 0,
    dependencies JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_tasks_progress ON tasks(progress);
```

#### 2.1.2 Intégration avec QDrant
- [ ] Implémenter `IndexTasks` dans `pkg/db/qdrant.go` pour indexer les tâches dans QDrant
  - [ ] Convertir `Description` en vecteurs via un modèle d'embedding
  - [ ] Stocker les vecteurs avec `id` comme clé
- [ ] Valider l'indexation via un dry-run

**Tests unitaires**:
- Cas nominal : Indexer 10 tâches dans QDrant
- Cas limite : Indexer une tâche avec une description vide
- Erreur simulée : Simuler une connexion QDrant échouée

**Mise à jour**:
- [ ] Mettre à jour `plan-dev-v25-meta-roadmap-sync-updated.md` en cochant les tâches terminées
- [ ] Ajuster les pourcentages de progression pour la Phase 2

## Phase 3: Module CLI
*Progression: 0%*

### 3.1 Développement de Roadmap-CLI
*Progression: 0%*

#### 3.1.1 Implémentation des commandes CLI
- [ ] Développer `cmd/roadmap-cli/main.go` avec Cobra pour les commandes
  - [ ] Commande `list` : Afficher les tâches prioritaires (progress < 100%)
  - [ ] Commande `show` : Afficher les détails d'une tâche par ID
  - [ ] Commande `sync` : Synchroniser les tâches avec PostgreSQL/QDrant
- [ ] Valider les commandes via un dry-run

**Tests unitaires**:
- Cas nominal : Exécuter `roadmap-cli list` avec 5 tâches
- Cas limite : Exécuter `roadmap-cli show` avec un ID inexistant
- Erreur simulée : Simuler une DB déconnectée

**Exemple de code**:
```go
package main

import (
    "github.com/spf13/cobra"
)

func listCmd() *cobra.Command {
    return &cobra.Command{
        Use:   "list",
        Short: "List priority tasks",
        RunE: func(cmd *cobra.Command, args []string) error {
            tasks, err := db.GetPriorityTasks(context.Background())
            if err != nil {
                return err
            }
            for _, task := range tasks {
                fmt.Printf("%s: %s (%d%%)\n", task.ID, task.Title, task.Progress)
            }
            return nil
        },
    }
}
```

#### 3.1.2 Configuration CLI
- [ ] Créer `cli_config.yaml` pour les paramètres (DB URL, QDrant URL, verbosity)
- [ ] Valider la configuration via un dry-run

**Tests unitaires**:
- Cas nominal : Charger une configuration CLI valide
- Cas limite : Charger une configuration vide
- Erreur simulée : Simuler un fichier YAML corrompu

**Mise à jour**:
- [ ] Mettre à jour `plan-dev-v25-meta-roadmap-sync-updated.md` en cochant les tâches terminées
- [ ] Ajuster les pourcentages de progression pour la Phase 3

## Phase 4: Module API
*Progression: 0%*

### 4.1 Développement de l'API REST avec FastAPI
*Progression: 0%*

#### 4.1.1 Implémentation des endpoints
- [ ] Développer `api/main.py` avec FastAPI
  - [ ] GET `/tasks` : Lister les tâches prioritaires
  - [ ] GET `/tasks/{id}` : Détails d'une tâche
  - [ ] POST `/tasks/sync` : Synchroniser avec PostgreSQL/QDrant
- [ ] Implémenter un cache (Redis) pour réduire la latence
- [ ] Valider les endpoints via un dry-run

**Tests unitaires**:
- Cas nominal : Appeler `/tasks` avec 5 tâches
- Cas limite : Appeler `/tasks/{id}` avec un ID invalide
- Erreur simulée : Simuler une DB déconnectée

**Exemple de code**:
```python
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class Task(BaseModel):
    id: str
    title: str
    description: str
    progress: int
    dependencies: list[str]

@app.get("/tasks")
async def list_tasks():
    tasks = await db.get_priority_tasks()
    return tasks
```

#### 4.1.2 Configuration API
- [ ] Créer `api_config.yaml` pour DB, QDrant, et Redis
- [ ] Valider la configuration via un dry-run

**Tests unitaires**:
- Cas nominal : Charger une configuration API valide
- Cas limite : Charger une configuration sans Redis
- Erreur simulée : Simuler une configuration YAML corrompue

**Mise à jour**:
- [ ] Mettre à jour `plan-dev-v25-meta-roadmap-sync-updated.md` en cochant les tâches terminées
- [ ] Ajuster les pourcentages de progression pour la Phase 4

## Phase 5: Module Meta-Roadmap
*Progression: 0%*

### 5.1 Génération du meta-roadmap
*Progression: 0%*

#### 5.1.1 Implémentation de `GenerateMetaRoadmap`
- [ ] Développer `pkg/meta/roadmap.go` pour générer `plan-dev-v25-meta-roadmap-sync-updated.md`
  - [ ] Agréger les tâches depuis PostgreSQL
  - [ ] Formatter en Markdown avec hiérarchie (phases, sous-étapes)
  - [ ] Inclure un graphe de dépendances (ASCII)
- [ ] Exécuter un dry-run pour valider le format

**Tests unitaires**:
- Cas nominal : Générer un meta-roadmap avec 10 tâches
- Cas limite : Générer avec aucune tâche
- Erreur simulée : Simuler une DB déconnectée

**Exemple de code**:
```go
package meta

func GenerateMetaRoadmap(ctx context.Context, tasks []Task) (string, error) {
    var sb strings.Builder
    sb.WriteString("# Meta-Roadmap\n*Generated: 2025-06-06*\n\n")
    for _, task := range tasks {
        sb.WriteString(fmt.Sprintf("- [ ] %s (%d%%)\n", task.Title, task.Progress))
    }
    return sb.String(), nil
}
```

#### 5.1.2 Sauvegarde Git
- [ ] Implémenter `CommitMetaRoadmap` pour versionner dans Git
  - [ ] Commit automatique avec message standard
  - [ ] Valider via un dry-run

**Tests unitaires**:
- Cas nominal : Commit un meta-roadmap valide
- Cas limite : Commit avec un repo Git vide
- Erreur simulée : Simuler une authentification Git échouée

**Mise à jour**:
- [ ] Mettre à jour `plan-dev-v25-meta-roadmap-sync-updated.md` en cochant les tâches terminées
- [ ] Ajuster les pourcentages de progression pour la Phase 5

## Phase 6: Documentation et Intégration CI/CD
*Progression: 0%*

### 6.1 Documentation utilisateur
*Progression: 0%*

#### 6.1.1 Génération des guides
- [ ] Créer `docs/user-guide.md` avec instructions pour `roadmap-cli`
- [ ] Créer `docs/api-guide.md` pour l'API REST
- [ ] Inclure des exemples input/output

**Tests unitaires**:
- Cas nominal : Générer la documentation avec 5 exemples
- Cas limite : Générer avec aucun exemple
- Erreur simulée : Simuler un format Markdown invalide

### 6.2 Pipeline CI/CD
*Progression: 0%*

#### 6.2.1 Configuration GitHub Actions
- [ ] Créer `.github/workflows/ci-cd.yaml`
  - [ ] Build et tests Go (`go test ./...`)
  - [ ] Build et tests Python (`pytest`)
  - [ ] Déploiement Kubernetes pour l'API
- [ ] Implémenter un rollback automatique

**Tests unitaires**:
- Cas nominal : Exécuter le pipeline avec succès
- Cas limite : Simuler un échec de test
- Erreur simulée : Simuler un déploiement Kubernetes échoué

**Exemple de pipeline**:
```yaml
name: CI/CD
on:
  push:
    branches: [ main ]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Go
        uses: actions/setup-go@v3
        with:
          go-version: 1.22
      - name: Test Go
        run: go test ./... -v
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Test Python
        run: pytest
      - name: Deploy
        run: kubectl apply -f k8s/deployment.yaml
```

**Mise à jour**:
- [ ] Mettre à jour `plan-dev-v25-meta-roadmap-sync-updated.md` en cochant les tâches terminées
- [ ] Ajuster les pourcentages de progression pour la Phase 6

## Phase 7: Validation Finale et Déploiement
*Progression: 0%*

### 7.1 Revue globale
*Progression: 0%*

#### 7.1.1 Validation de l'écosystème
- [ ] Exécuter un dry-run complet (parsing, DB, CLI, API, meta-roadmap)
- [ ] Vérifier l'intégration entre modules
- [ ] Valider la scalabilité (100+ tâches)

**Tests unitaires**:
- Cas nominal : Exécuter le workflow complet
- Cas limite : Exécuter avec 0 tâche
- Erreur simulée : Simuler une panne DB/QDrant

### 7.2 Déploiement final
*Progression: 0%*

#### 7.2.1 Déploiement Kubernetes
- [ ] Déployer l'API FastAPI sur Kubernetes
- [ ] Configurer le monitoring Prometheus
- [ ] Valider via un dry-run

**Tests unitaires**:
- Cas nominal : Déployer avec succès
- Cas limite : Déployer avec une configuration Kubernetes invalide
- Erreur simulée : Simuler une panne réseau

**Mise à jour**:
- [ ] Mettre à jour `plan-dev-v25-meta-roadmap-sync-updated.md` en cochant les tâches terminées
- [ ] Passer à la version `v25.1` et ajuster les pourcentages de progression

---

## Recommandations
- **DRY** : Réutiliser les configurations YAML (`parsing_config.yaml`, `cli_config.yaml`, `api_config.yaml`) pour éviter la duplication.
- **KISS** : Simplifier les interfaces (`ParseMarkdown`, `StoreTasks`, `GenerateMetaRoadmap`) pour une clarté maximale.
- **SOLID** : Chaque module (Parsing, DB, CLI, API, Meta-Roadmap) a une responsabilité unique avec des interfaces claires (`TaskProvider`, `DBClient`).
- **Performances** : Utiliser des goroutines pour le parsing et des workers pour l'API, avec un cache Redis pour réduire la latence.
- **Sécurité** : Stocker les clés (PostgreSQL, QDrant) dans un `SecurityManager`.
- **Documentation** : Générer des guides utilisateur clairs avec exemples concrets.
```

---

### Explications du Plan

1. **Respect des principes**:
   - **DRY** : Les configurations YAML sont centralisées et réutilisées par tous les modules.
   - **KISS** : Les interfaces et méthodes sont simples (ex. : `ParseMarkdown` retourne une liste de tâches sans logique complexe).
   - **SOLID** : Chaque module a une responsabilité unique (Parsing extrait, DB stocke, CLI affiche, API expose, Meta-Roadmap génère).

2. **Tests et dry-runs**:
   - Chaque sous-étape inclut des tests unitaires pour les cas nominaux, limites, et erreurs simulées.
   - Les dry-runs valident les opérations critiques sans modification (parsing, DB, meta-roadmap).

3. **Intégrations**:
   - **PostgreSQL/QDrant** : Stockage des tâches et indexation vectorielle pour le RAG.
   - **FastAPI** : API REST pour exposer les tâches avec cache Redis.
   - **Git** : Versionnage automatique du meta-roadmap.
   - **Kubernetes/Prometheus** : Déploiement et monitoring pour la scalabilité.

4. **Sorties**:
   - Fichier Markdown : `plan-dev-v25-meta-roadmap-sync-updated.md`
   - Scripts Go : `parser.go`, `postgres.go`, `qdrant.go`, `roadmap.go`
   - Script Python : `main.py` (FastAPI)
   - Documentation : `user-guide.md`, `api-guide.md`
   - Configurations : `parsing_config.yaml`, `cli_config.yaml`, `api_config.yaml`

Ce plan est actionnable, modulaire, et optimisé pour un contexte d'entreprise, avec une couverture complète des fonctionnalités demandées et une intégration robuste des modules.