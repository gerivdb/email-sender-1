#!/bin/sh
# Hook Git pre-commit : vérifie l’unicité du bloc SEARCH diff Edit avant commit
# Usage : placer ce fichier dans .git/hooks/pre-commit (rendre exécutable)
# Personnaliser <fichier> et <bloc-diff> selon le contexte du commit
go run tools/diff_edit/go/diffedit.go --file <fichier> --patch <bloc-diff> --dry-run
