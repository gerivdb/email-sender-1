# LOCKS.md — Convention de verrouillage/notification diff Edit

- Lorsqu’un fichier critique est édité via diff Edit, notifier l’équipe (Slack, mail, bot, ou PR comment).
- Ajouter une entrée dans ce fichier pour signaler le verrouillage temporaire :

| Fichier concerné         | Utilisateur | Date/Heure début | Date/Heure fin (prévue) | Commentaire |
|-------------------------|-------------|------------------|------------------------|-------------|
| exemple.md              | alice       | 2025-06-23 10:00 | 2025-06-23 12:00       | Patch bloc X|

- Nettoyer les entrées obsolètes après merge ou abandon.
- Utiliser ce fichier comme référence pour éviter les conflits simultanés.
