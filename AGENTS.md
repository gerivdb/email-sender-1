# AGENTS.md

## Purpose

Ce fichier documente les agents et managers principaux de l’architecture documentaire hybride du projet. Il décrit leurs rôles, interfaces, conventions d’utilisation et points d’extension. Jules et les collaborateurs s’appuient sur ce fichier pour comprendre et exploiter efficacement l’écosystème documentaire.

---

## Agents & Managers Principaux

### DocManager

- **Rôle :** Orchestrateur central de la gestion documentaire (création, coordination, cohérence).
- **Interfaces :**
  - `Store(*Document) error`, `Retrieve(string) (*Document, error)`
  - `RegisterPlugin(PluginInterface) error`
- **Utilisation :** Toutes les opérations documentaires passent par DocManager. Extension possible via plugins.
- **Entrée/Sortie :** Documents structurés, résultats d’opérations, logs.

### PathTracker

- **Rôle :** Suivi intelligent des chemins de fichiers et gestion des déplacements.
- **Interfaces :**
  - `TrackFileMove(oldPath, newPath string) error`
  - `CalculateContentHash(filePath string) (string, error)`
  - `UpdateAllReferences(oldPath, newPath string) error`
- **Utilisation :** Appelé lors de tout déplacement ou renommage de fichier documentaire.
- **Entrée/Sortie :** Chemins, rapports d’intégrité, suggestions de correction.

### BranchSynchronizer

- **Rôle :** Synchronisation documentaire multi-branches (Git).
- **Interfaces :**
  - `SyncAcrossBranches(ctx context.Context) error`
  - `GetBranchStatus(branch string) BranchDocStatus`
  - `MergeDocumentation(fromBranch, toBranch string) error`
- **Utilisation :** Pour maintenir la cohérence documentaire entre branches.
- **Entrée/Sortie :** Statuts de branches, rapports de divergence, logs de fusion.

### ConflictResolver

- **Rôle :** Résolution automatique et intelligente des conflits documentaires.
- **Interfaces :**
  - `ResolveConflict(conflict *DocumentConflict) (*Document, error)`
  - `RegisterStrategy(conflictType ConflictType, strategy ResolutionStrategy)`
- **Utilisation :** Appelé lors de conflits détectés par BranchSynchronizer ou DocManager.
- **Entrée/Sortie :** Documents résolus, logs de résolution, stratégies appliquées.

---

## Points d’extension & Plugins

- **PluginInterface :** Permet d’ajouter dynamiquement de nouveaux managers, stratégies de cache, vectorisation, etc.
- **CacheStrategy, VectorizationStrategy :** Systèmes ouverts pour personnaliser la gestion du cache et la vectorisation documentaire.

---

## Conventions générales

- **Entrée :** Documents, chemins, branches, requêtes API, plugins.
- **Sortie :** Documents, statuts, rapports, logs, suggestions.
- **Maintenance :** Mettre à jour ce fichier à chaque ajout ou modification d’agent, manager ou plugin.

---

_Tip : Un AGENTS.md à jour permet à Jules et à l’équipe de générer des plans et des complétions plus pertinents._
