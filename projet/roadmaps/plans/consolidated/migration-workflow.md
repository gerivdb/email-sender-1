# Documentation technique – Workflow de migration Markdown → Qdrant

## Étapes du workflow

1. **Recensement des fichiers Markdown**
   - Script d’inventaire : génère la liste des fichiers à migrer.
   - Format : Markdown, JSON

2. **Analyse d’écart**
   - Script d’analyse : compare la structure Markdown au schéma Qdrant.
   - Livrable : rapport d’écart

3. **Mapping des champs**
   - Spécification du mapping Markdown → Qdrant.
   - Documentation du mapping

4. **Migration des données**
   - Script Go : lit chaque fichier Markdown, extrait les champs, génère les embeddings, et insère dans Qdrant.
   - Commande : `go run migrate.go`
   - Format : Go, JSON

5. **Tests et validation**
   - Script de test : vérifie l’intégrité des données migrées.
   - Commande : `go test`
   - Badge de couverture >90%

6. **Rollback**
   - Sauvegarde automatique avant migration.
   - Fichiers `.bak` générés pour chaque étape critique.

## Validation

- Tests unitaires automatisés
- Revue technique croisée
- Reporting CI/CD

## Rollback

- Versionning git
- Sauvegarde des inventaires, rapports et scripts
