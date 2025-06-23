# MigrationManager

- **Rôle :** Gère l’import/export et la migration de données (jobs, configs, tenants, etc.) entre versions ou environnements.
- **Interfaces :**
  - `ExportData(ctx context.Context, name string, data interface{}) (string, error)`
  - `ImportData(ctx context.Context, filename string, target interface{}) error`
  - `ListExports() ([]string, error)`
- **Utilisation :** Sauvegarde/export de données structurées, import/restauration, gestion des migrations lors des évolutions de schéma ou de version.
- **Entrée/Sortie :**
  - Entrées : contextes d’exécution, noms/logiques d’export, données à migrer, fichiers d’export.
  - Sorties : chemins de fichiers exportés, erreurs, logs, données importées.

---

[Retour à l’index des managers](INDEX.md) | [Vue d’ensemble de l’architecture](../ARCHITECTURE/ecosystem-overview.md)
