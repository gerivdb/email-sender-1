# Pièges et limites connus (diff Edit Go natif)

- Bloc SEARCH non unique dans le fichier : le script Go refuse d’appliquer le patch si le bloc SEARCH apparaît plusieurs fois (sécurité).
- Encodage : bien vérifier l’UTF-8 sans BOM, attention aux fins de ligne CRLF/LF (le script préserve le format d’origine mais ne convertit pas).
- Fichiers binaires ou très volumineux : non supportés, le script Go doit refuser ou prévenir l’utilisateur.
- Conflits d’équipe : plusieurs diff Edit appliqués en parallèle sur le même fichier peuvent générer des conflits, à gérer via Git/VS Code.
- Plugins VS Code ou auto-formatters : peuvent modifier le contenu entre la génération et l’application du patch, toujours valider le diff avant commit.

## Recommandations
- Toujours valider l’unicité du bloc SEARCH avant application.
- Vérifier l’encodage et la taille du fichier.
- Utiliser Git pour gérer les conflits et l’historique.
- Documenter chaque patch appliqué (log, commit, backup).
