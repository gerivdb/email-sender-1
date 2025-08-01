Voici un rapport ultra détaillé sur la gestion, la structure, la configuration et la logique des "modes" (persona modes) dans le dépôt Roo-Code (https://github.com/RooCodeInc/Roo-Code) :

---

# 1. Structure Générale et Localisation des Modes

## a) Fichiers et dossiers principaux

- **src/core/config/CustomModesManager.ts**
  - Gère la logique centrale des modes personnalisés (lecture, écriture, fusion, suppression, cache, import/export).
- **src/shared/modes.ts**
  - Fournit des fonctions utilitaires pour manipuler et fusionner les modes (par défaut + custom).
- **packages/types/src/mode.ts**
  - Définit les modes par défaut (DEFAULT_MODES) du système.
- **Fichier .roomodes**
  - Fichier YAML à la racine d’un projet, contenant les modes personnalisés propres au workspace.
- **Fichier YAML de config utilisateur (global)**
  - Stocké dans un dossier de paramètres utilisateur, géré via `getCustomModesFilePath()`.

---

# 2. Définition des Modes

## a) Modes par défaut

- **Définis dans :** `packages/types/src/mode.ts`
- **Format :** Tableau d’objets ModeConfig, par exemple :

```typescript
{
  slug: "architect",
  name: "🏗️ Architect",
  roleDefinition: "You are Roo, an experienced technical leader...",
  whenToUse: "Use this mode when you need to plan, design...",
  description: "Plan and design before implementation",
  groups: [...]
  customInstructions: ...
}
```
- **Exportés via :** `DEFAULT_MODES` et réutilisés dans `src/shared/modes.ts`.

## b) Modes personnalisés (Custom Modes)

- **Stockage global :** Fichier YAML dans un dossier settings utilisateur (accès via `getCustomModesFilePath()`).
- **Stockage projet :** Fichier `.roomodes` à la racine du workspace (accès via `getWorkspaceRoomodes()`).
- **Format YAML typique :**
```yaml
customModes:
  - slug: "my-mode"
    name: "My Mode"
    roleDefinition: "..."
    whenToUse: "..."
    description: "..."
    customInstructions: "..."
```

---

# 3. Chargement, Fusion et Priorités

## a) Chargement

- **Méthode centrale :** `getCustomModes()` (dans `CustomModesManager.ts`)
  - Récupère modes globaux et modes projet.
  - Utilise un cache pour limiter les accès disque.

## b) Fusion et priorités

- **Fonction :** `mergeCustomModes(projectModes, globalModes)`
  - Les modes du projet (.roomodes) ont la priorité sur les modes globaux.
  - Si un slug est présent dans les deux, seul celui du projet est gardé.

- **Ordre de fusion :**
  1. Modes projet (source: "project")
  2. Modes globaux (source: "global" et non dupliqués)

---

# 4. Manipulation et Gestion des Modes

## a) Ajout / Modification

- **Ajout / modification d’un mode :** `updateCustomMode(slug, config)`
  - Valide le mode selon le schéma `modeConfigSchema`.
  - Écrit le mode dans le bon fichier (global ou .roomodes selon le scope).

## b) Suppression

- **Suppression :** `deleteCustomMode(slug)`
  - Retire le mode du fichier concerné (global ou projet).
  - Supprime également le dossier de règles associé (`.roo/rules-{slug}`).

## c) Reset

- **Réinitialisation des modes custom :** `resetCustomModes()`
  - Vide le fichier global de modes personnalisés.

## d) Import / Export

- **Export :** `exportModeWithRules(slug, customPrompts)`
  - Exporte le mode et ses fichiers de règles associés au format YAML.
- **Import :** `importModeWithRules(yamlContent, source)`
  - Importe un mode (et ses règles) depuis un YAML, à l’échelle globale ou projet.

---

# 5. Fichiers et Schéma de Configuration

## a) Fichier `.roomodes` (projet)

- **Contenu :** Liste YAML d’objets mode sous la clé `customModes`.
- **Exemple :**
```yaml
customModes:
  - slug: "reviewer"
    name: "Code Reviewer"
    roleDefinition: "..."
    whenToUse: "..."
    description: "..."
```

## b) Fichier global (utilisateur)

- **Structure identique à `.roomodes`**
- **Accès via :** `getCustomModesFilePath()`
- **Création automatique si inexistant.**

---

# 6. Logique et Fonctions Clés (Code)

- **CustomModesManager** :
  - Regroupe toutes les opérations de gestion des modes (CRUD, cache, watchers sur fichiers de config).
- **getAllModesWithPrompts(context)** :
  - Retourne la liste fusionnée des modes avec leurs prompts (instructions) personnalisés.
- **getModeBySlug(slug, customModes?)** :
  - Recherche un mode par son slug, priorise les modes personnalisés.
- **isCustomMode(slug, customModes?)** :
  - Indique si un mode est custom ou un override.

---

# 7. Extension et Override

- **Les modes personnalisés peuvent overrider les modes par défaut** si le slug est identique.
- **Le système permet d’avoir des modes différents selon le projet ou l’utilisateur.**

---

# 8. Surveillance et Synchronisation

- **Watchers sur les fichiers de modes** :
  - Si un fichier de config (`.roomodes` ou global) change, les modes sont rechargés dynamiquement via FileSystemWatcher (VSCode API).

---

# 9. Sécurité et Validation

- **Validation stricte (zod)** :
  - Toute modification passe par une validation de schéma (format et types requis).
- **Protection contre path traversal** lors de l’import de règles associées à un mode.

---

# 10. Manipulation Avancée & Import/Export

- **Export YAML** d’un mode avec ses règles associé pour partage/import dans un autre environnement/projet.
- **Import YAML** avec fusion intelligente, validation, et nettoyage/écrasement des anciennes règles si besoin.

---

# 11. Utilisation dans la logique de prompts

- **src/core/prompts/sections/modes.ts** :
  - Génère la section descriptive des modes disponibles pour affichage ou documentation interne.

---

# 12. Résumé structurel (diagramme simplifié)

```mermaid
graph TD
  subgraph Utilisateur
    A[Config globale utilisateur]<-->B(CustomModesManager)
    C[Fichier .roomodes projet]<-->B
    D[Fichiers de règles .roo/rules-{slug}]<-->B
    E[modes par défaut]<-->B
  end
  B--->F[Liste fusionnée des modes]
  F--->G[Utilisation dans prompts, UI, etc.]
```

---

# 13. Points Importants

- **Personnalisation multi-niveaux :** utilisateur ET projet.
- **Priorité claire :** projet > global > défaut.
- **Export/import pour portabilité des modes.**
- **Validation stricte, manipulation sécurisée des fichiers.**
- **Fusion automatique des modes, cache pour performance.**

---

**En synthèse :**  
Les "modes" dans Roo-Code sont un système flexible, extensible et sécurisé de personas AI, stockés en YAML soit globalement soit par projet, synchronisés et fusionnés à la volée, avec des outils puissants pour leur gestion, partage et override. Toute la logique centrale se trouve dans le fichier `src/core/config/CustomModesManager.ts` et s’interface avec les définitions par défaut de `packages/types/src/mode.ts`.