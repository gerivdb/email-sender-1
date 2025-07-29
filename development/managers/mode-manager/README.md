# mode-manager

Ce rÃ©pertoire contient les fichiers du gestionnaire mode-manager.

## Structure

- config : Fichiers de configuration spÃ©cifiques au gestionnaire
- scripts : Scripts PowerShell du gestionnaire
- modules : Modules PowerShell du gestionnaire
- 	ests : Tests unitaires et d'intÃ©gration du gestionnaire

## Configuration

Les fichiers de configuration du gestionnaire sont centralisÃ©s dans le rÃ©pertoire projet/config/managers/mode-manager.
## Tests & CI/CD

### Lancer les tests localement

Pour exécuter les tests unitaires Go du mode-manager, placez-vous dans ce répertoire puis lancez :

```bash
go test -v ./...
```

Les résultats détaillés s’affichent dans le terminal.  
Pour générer un rapport de couverture :

```bash
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

### Archivage des résultats

Les résultats de tests importants sont archivés dans [`test-output/ARCHIVAGE_TESTS.txt`](test-output/ARCHIVAGE_TESTS.txt).  
Ce fichier contient l’historique des exécutions, logs et éventuels rapports de couverture ou d’erreurs.

### Intégration dans le pipeline CI/CD

Les tests sont intégrés dans le pipeline CI/CD via un job dédié.  
Exemple d’intégration avec GitHub Actions :

```yaml
name: Go CI

on:
  push:
    paths:
      - 'development/managers/mode-manager/**'
      - '.github/workflows/go.yml'
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - name: Run tests
        run: go test -v ./...
      - name: Archive test output
        if: always()
        run: |
          mkdir -p test-output
          go test -v ./... > test-output/ARCHIVAGE_TESTS.txt
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: mode-manager-test-output
          path: test-output/ARCHIVAGE_TESTS.txt
```

### Badge de statut des tests

Ajoutez ce badge en haut du README pour visualiser le statut CI :

```markdown
[![Tests Go](https://github.com/<votre-org>/<votre-repo>/actions/workflows/go.yml/badge.svg)](https://github.com/<votre-org>/<votre-repo>/actions/workflows/go.yml)
```
Remplacez `<votre-org>` et `<votre-repo>` par les valeurs adaptées à votre dépôt GitHub.
