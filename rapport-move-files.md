# Rapport d’exécution – Déplacement documentaire multifichier Roo Code

- **Date d’exécution** : 2025-08-01
- **Auteur** : Roo Engine
- **Configuration utilisée** : [`file-moves.yaml`](file-moves.yaml)

## ✅ Résumé global

- Nombre d’opérations : 2
- Succès : 2
- Échecs : 0
- Dry-run : 1

## 📋 Détail des opérations

| ID               | Source                        | Cible                         | Type   | Statut   | Validation | Rollback | Logs                |
|------------------|------------------------------|-------------------------------|--------|----------|------------|----------|---------------------|
| move-doc-001     | docs/old/guide.md            | docs/new/guide.md             | move   | OK       | OK         | OK       | voir logs détaillés |
| copy-script-002  | scripts/legacy/cleanup.sh    | scripts/backup/cleanup.sh     | copy   | DRY-RUN  | OK         | N/A      | voir logs détaillés |

## 📝 Logs détaillés

- [ ] Inclure ici les extraits de logs, erreurs, outputs de hooks, etc.

## 🔄 Rollback

- [ ] Préciser les opérations ayant déclenché un rollback et leur résultat.

## 🔗 Liens utiles

- [Configuration](file-moves.yaml)
- [Schéma](file-moves.schema.yaml)
- [Hooks](file-moves.hooks.md)
- [Checklist](CHECKLIST.file-moves.md)