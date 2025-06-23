# RollbackManager

- **Rôle :** Gestion des rollbacks et restaurations documentaires.
- **Interfaces :**
  - `RollbackLast() error`
- **Utilisation :** Permet d’annuler la dernière résolution de conflit enregistrée dans l’historique (ConflictHistory). Utilisé pour restaurer un état antérieur en cas d’erreur ou de besoin de révision.
- **Entrée/Sortie :**
  - Entrée : aucune (opère sur l’historique interne)
  - Sortie : erreur éventuelle si le rollback échoue.

---

[Retour à l’index des managers](INDEX.md) | [Vue d’ensemble de l’architecture](../ARCHITECTURE/ecosystem-overview.md)
