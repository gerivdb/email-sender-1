# Guide d’utilisation rapide – refs_sync.go

## Commandes principales

- **Scan des fichiers à synchroniser**
  ```
  go run refs_sync.go --scan
  ```
  Affiche la liste des fichiers Markdown détectés dans `.roo/rules/`.

- **Injection de la section "Références croisées"**
  ```
  go run refs_sync.go --inject
  ```
  Ajoute ou met à jour la section "Références croisées" en fin de chaque fichier.

- **Vérification des verrous/droits**
  ```
  go run refs_sync.go --check-locks
  ```
  Liste les fichiers verrouillés ou non modifiables.

- **Mode dry-run (simulation sans écriture)**
  ```
  go run refs_sync.go --dry-run
  ```
  Affiche la simulation d’injection pour chaque fichier sans modification réelle.

## Fichiers de configuration

- `.roo/tools/refs_sync.config.yaml` : inclusion/exclusion, format, personnalisation

## Tests

- Lancer tous les tests unitaires :
  ```
  go test .roo/tools/refs_sync_test.go
  ```

## CI/CD

- Intégrer les commandes dans le pipeline pour automatiser le scan, l’injection et la vérification.

## Sécurité & rollback

- Un backup `.bak` est créé avant chaque modification.
- Les fichiers verrouillés sont signalés.

## Documentation

- Voir `.roo/tools/spec-crossrefs.md` pour le format attendu de la section "Références croisées".
