# Guide utilisateur – Migration Roadmap Markdown → Qdrant

## Prérequis

- Go 1.22+
- Accès au dossier `projet/roadmaps/plans/consolidated/`
- Qdrant opérationnel (optionnel pour la synchronisation finale)

## Étapes

1. **Inventaire**
   - Vérifiez le fichier `inventory-report.md` pour la liste des plans à migrer.

2. **Analyse d’écart**
   - Consultez `gap-analysis-report.md` pour les différences structurelles.

3. **Migration**
   - Exécutez le runner :
     ```
     go run cmd/auto-roadmap-runner/main.go
     ```
   - Le fichier `roadmaps.json` sera généré.

4. **Tests**
   - Lancez les tests unitaires :
     ```
     go test ./cmd/auto-roadmap-runner/...
     ```

5. **CI/CD**
   - Les tests et la couverture sont automatisés via GitHub Actions.

## Rollback

- Les fichiers `.bak` sont générés automatiquement avant chaque étape critique.
- Utilisez git pour restaurer une version antérieure si besoin.

## Synchronisation Qdrant

- Pour synchroniser avec Qdrant, adaptez le script Go pour insérer les données dans la base vectorielle.
