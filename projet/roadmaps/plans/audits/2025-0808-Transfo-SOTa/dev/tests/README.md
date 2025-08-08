# Tests unitaires et d’intégration

Ce dossier regroupe les exemples de tests unitaires et d’intégration pour chaque composant du projet.

## Exemple de test unitaire (Go)

```go
package main

import "testing"

func TestAddition(t *testing.T) {
    result := 2 + 2
    if result != 4 {
        t.Errorf("Addition incorrecte, attendu 4, obtenu %d", result)
    }
}
```

## Exemple de test d’intégration (bash)

```bash
#!/bin/bash
# Test d’intégration du pipeline d’automatisation

./example_script.sh
if [ -f rapport_avancement.txt ]; then
    echo "Test OK : rapport généré"
else
    echo "Test KO : rapport absent"
    exit 1
fi
```

## Liens croisés

- [Scripts d’automatisation](../scripts/example_script.sh)
- [Rapport d’avancement](../reporting/rapport_avancement.md)
- [Exceptions](../exceptions/exemple_exception.md)

## Convention

- Tous les tests doivent être documentés et liés aux artefacts SOTA et aux tickets PlanDev Engineer.
