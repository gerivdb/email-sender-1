# Rapport d’écart sur les références croisées Roo-Code

- **Date** : 2025-07-30 15:25 (Europe/Paris)
- **Branche** : dev

## Synthèse

La majorité des fichiers de règles ne contient pas de section standardisée "Références croisées" en fin de fichier.  
Seuls `tools-registry.md` (section explicite) et `rules.md` (références documentaires) comportent des liens croisés, mais pas sous la forme attendue.

## Détail par fichier

| Fichier                   | Section "Références croisées" présente | Commentaire |
|---------------------------|----------------------------------------|-------------|
| README.md                 | Non                                    | Aucun lien croisé explicite |
| rules-agents.md           | Non                                    | Pas de section dédiée |
| rules-code.md             | Non                                    | Pas de section dédiée |
| rules-debug.md            | Non                                    | Pas de section dédiée |
| rules-documentation.md    | Non                                    | Pas de section dédiée |
| rules-maintenance.md      | Non                                    | Pas de section dédiée |
| rules-migration.md        | Non                                    | Pas de section dédiée |
| rules-orchestration.md    | Non                                    | Pas de section dédiée |
| rules-plugins.md          | Non                                    | Pas de section dédiée |
| rules-security.md         | Non                                    | Pas de section dédiée |
| rules.md                  | Partielle                              | Références documentaires, non standardisées |
| tools-registry.md         | Oui                                    | Section "Références croisées" explicite |
| workflows-matrix.md       | Non                                    | Pas de section dédiée |

## Recommandations

- Ajouter une section "Références croisées" standardisée en fin de chaque fichier de règles.
- Utiliser le format :

  ```markdown
  ## Références croisées

  - [Nom du fichier lié](chemin/vers/fichier.md) : Description ou usage
  ```

- Synchroniser dynamiquement cette section lors des scans et audits.
- Documenter la procédure dans le README central.

## Traçabilité

- Rapport archivé dans `.roo/tools/crossrefs-gap-report.md`
- Historique des audits à conserver pour suivi des évolutions.
