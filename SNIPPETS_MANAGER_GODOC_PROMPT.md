# Prompt pour documentation GoDoc automatique des managers

Pour chaque manager Go de votre projet, ajoutez un bloc GoDoc structuré au-dessus de la déclaration du type (struct ou interface) :

---

**Procédure**

1. Pour chaque manager de la liste, localisez la déclaration dans le code source.
2. Ajoutez le bloc GoDoc structuré juste avant la déclaration.
3. Adaptez chaque section selon le rôle réel du manager (lisez le code si besoin).
4. Répétez pour tous les managers de la liste.

---

**Modèle de bloc GoDoc à insérer**

```go
// NomManager [struct|interface] — [1 phrase sur le rôle principal].
//
// Rôle :
//   - [Description synthétique du rôle, ex : Orchestrateur central, gestion des erreurs, etc.]
//
// Interfaces principales :
//   - [Liste des interfaces Go implémentées ou exposées, ou "voir méthodes ci-dessous"]
//
// Utilisation :
//   - [Exemples d’utilisation ou contexte d’appel]
//
// Entrée/Sortie :
//   - [Types de données manipulés, ex : Documents, statuts, logs, etc.]
//
// Exemple :
//   [Exemple d’utilisation si pertinent]
//
// Voir aussi : [autres managers ou composants liés]
```

- Si le manager est une struct, commencez par : `// NomManager struct ...`
- Si c’est une interface, commencez par : `// NomManager interface ...`
- Rédigez le commentaire en français, synthétique, et adaptez chaque section selon le rôle réel du manager (en lisant le code si besoin).
- Si le manager expose des méthodes publiques, listez-les brièvement dans "Interfaces principales" ou "voir méthodes ci-dessous".
- Si le code source n’a pas de doc, créez-la à partir du nom, du contexte, et des signatures de méthodes.
- Placez le bloc GoDoc juste avant la déclaration du type concerné.

---

**Exemple pour DocManager**

```go
// DocManager struct — Orchestrateur central de la gestion documentaire hybride.
//
// Rôle :
//   - Coordination, création, cohérence documentaire, point d’entrée unique.
//
// Interfaces principales :
//   - DocumentPersistence, DocumentCaching, DocumentVectorization, etc.
//
// Utilisation :
//   - Toutes les opérations documentaires passent par DocManager.
//   - Extension dynamique via plugins.
//
// Entrée/Sortie :
//   - Documents structurés, résultats d’opérations, logs.
//
// Exemple :
//   dm := NewDocManager(config)
//   err := dm.Store(doc)
//
// Voir aussi : PathTracker, BranchSynchronizer, ConflictResolver
type DocManager struct {
    ...
}
```

# Prompt pour documentation GoDoc automatique des managers

Pour chaque manager Go de votre projet, ajoutez un bloc GoDoc structuré au-dessus de la déclaration du type (struct ou interface) :

---

**Procédure**

1. Pour chaque manager de la liste, localisez la déclaration dans le code source.
2. Ajoutez le bloc GoDoc structuré juste avant la déclaration.
3. Adaptez chaque section selon le rôle réel du manager (lisez le code si besoin).
4. Répétez pour tous les managers de la liste.

---

**Modèle de bloc GoDoc à insérer**

```go
// NomManager [struct|interface] — [1 phrase sur le rôle principal].
//
// Rôle :
//   - [Description synthétique du rôle, ex : Orchestrateur central, gestion des erreurs, etc.]
//
// Interfaces principales :
//   - [Liste des interfaces Go implémentées ou exposées, ou "voir méthodes ci-dessous"]
//
// Utilisation :
//   - [Exemples d’utilisation ou contexte d’appel]
//
// Entrée/Sortie :
//   - [Types de données manipulés, ex : Documents, statuts, logs, etc.]
//
// Exemple :
//   [Exemple d’utilisation si pertinent]
//
// Voir aussi : [autres managers ou composants liés]
```

- Si le manager est une struct, commencez par : `// NomManager struct ...`
- Si c’est une interface, commencez par : `// NomManager interface ...`
- Rédigez le commentaire en français, synthétique, et adaptez chaque section selon le rôle réel du manager (en lisant le code si besoin).
- Si le manager expose des méthodes publiques, listez-les brièvement dans "Interfaces principales" ou "voir méthodes ci-dessous".
- Si le code source n’a pas de doc, créez-la à partir du nom, du contexte, et des signatures de méthodes.
- Placez le bloc GoDoc juste avant la déclaration du type concerné.

---

**Exemple pour DocManager**

```go
// DocManager struct — Orchestrateur central de la gestion documentaire hybride.
//
// Rôle :
//   - Coordination, création, cohérence documentaire, point d’entrée unique.
//
// Interfaces principales :
//   - DocumentPersistence, DocumentCaching, DocumentVectorization, etc.
//
// Utilisation :
//   - Toutes les opérations documentaires passent par DocManager.
//   - Extension dynamique via plugins.
//
// Entrée/Sortie :
//   - Documents structurés, résultats d’opérations, logs.
//
// Exemple :
//   dm := NewDocManager(config)
//   err := dm.Store(doc)
//
// Voir aussi : PathTracker, BranchSynchronizer, ConflictResolver
type DocManager struct {
    ...
}
```
