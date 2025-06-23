# ErrorManager

- **Rôle :** Centralise la gestion, la validation et la journalisation structurée des erreurs dans le système de gestion des dépendances et autres modules.
- **Interfaces :**
  - `ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error`
  - `CatalogError(entry ErrorEntry) error`
  - `ValidateErrorEntry(entry ErrorEntry) error`
- **Utilisation :** Injecté dans GoModManager, ConfigManager, etc. pour uniformiser le traitement des erreurs et assurer la traçabilité.
- **Entrée/Sortie :**
  - Entrées : erreurs Go, entrées structurées (ErrorEntry), contexte d’exécution.
  - Sorties : erreurs Go standard (validation, journalisation, etc.).

---

[Retour à l’index des managers](INDEX.md) | [Vue d’ensemble de l’architecture](../ARCHITECTURE/ecosystem-overview.md)
