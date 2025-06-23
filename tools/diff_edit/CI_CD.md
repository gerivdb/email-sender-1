# Intégration CI/CD diff Edit (Go natif)

## Pipeline CI (exemple YAML pour GitHub Actions)

```yaml
name: DiffEdit Patch Validation
on:
  pull_request:
    paths:
      - '**.md'
      - '**.go'
      - 'tools/diff_edit/**'

jobs:
  validate-diffedit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - name: Valider patch diff Edit (dry-run)
        run: |
          go run tools/diff_edit/go/diffedit.go --file <fichier> --patch <bloc-diff> --dry-run
      - name: Automatiser rollback en cas d’échec
        if: failure()
        run: |
          go run tools/diff_edit/go/undo.go --file <fichier>
```

## Explications

- Le script diff Edit Go est intégré à la pipeline CI pour valider automatiquement les patchs.
- Une étape dry-run est exécutée avant merge pour vérifier le diff.
- En cas d’échec, le rollback est automatisé via le script Go `undo.go`.
- Adaptable à GitLab CI, Jenkins, etc.

## Artefacts fournis

- Exemple de pipeline CI/CD (ci-dessus)
- Scripts Go natifs (`diffedit.go`, `undo.go`)
- Documentation dans le README
