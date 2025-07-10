## 🧪 Roadmap granularisée – Renforcement des tests et validation avancée

### 1. Tests de robustesse et de non-régression
- [ ] Ajouter des tests de non-régression pour chaque fonctionnalité critique.
- [ ] Vérifier que toute modification future ne casse pas le comportement existant (tests de régression automatisés).

### 2. Tests de performance
- [ ] Écrire des benchmarks Go (`*_test.go` avec `testing.B`) pour mesurer les temps de réponse des fonctions clés.
- [ ] Automatiser l’exécution de ces benchmarks dans la CI/CD.
- [ ] Générer un rapport de performance à chaque build.

### 3. Tests de charge et de scalabilité
- [ ] Simuler des appels massifs ou concurrents sur les modules critiques (ex : gestionnaire de dépendances, orchestration CLI).
- [ ] Utiliser des outils comme `go test -bench`, k6 ou vegeta pour tester la scalabilité.
- [ ] Archiver les rapports de charge dans la CI/CD.

### 4. Tests de sécurité
- [ ] Ajouter des tests pour vérifier la gestion des entrées malicieuses, l’injection, la robustesse face aux attaques courantes.
- [ ] Vérifier la gestion des droits, des accès et des erreurs.
- [ ] Automatiser des scans de sécurité dans la CI/CD (ex : gosec).

### 5. Tests de mutation
- [ ] Utiliser un outil de mutation testing (ex : GoMutesting) pour s’assurer que les tests détectent bien les bugs introduits volontairement.
- [ ] Générer un rapport de mutation à chaque release majeure.

### 6. Tests de compatibilité
- [ ] Tester le projet sur plusieurs versions de Go (matrix dans GitHub Actions).
- [ ] Vérifier la compatibilité avec différents OS (Linux, Windows, Mac).
- [ ] Archiver les logs de compatibilité.

### 7. Tests d’intégration bout-en-bout
- [ ] Simuler des scénarios utilisateurs réels (ex : création, modification, suppression de plans via la CLI).
- [ ] Vérifier l’intégration entre tous les modules restaurés.
- [ ] Générer un rapport d’intégration à chaque build.

### 8. Tests de couverture avancée
- [ ] Générer des rapports de couverture ligne, branche, fonction.
- [ ] Fixer des seuils minimaux dans la CI/CD (ex : 90% global, 80% par fichier).
- [ ] Ajouter un badge de couverture dans le README.

### 9. Tests de documentation
- [ ] Vérifier que chaque module/fonction exportée a un commentaire/docstring.
- [ ] Ajouter des tests de lint/documentation dans la CI/CD.
- [ ] Générer un rapport de documentation.

### 10. Tests de rollback/versionnement
- [ ] Simuler des rollbacks (retour arrière sur une version précédente) et vérifier la robustesse du projet.
- [ ] Automatiser la sauvegarde/restauration dans la CI/CD.

---

**Chaque tâche est actionnable, automatisable, traçable et alignée sur les standards avancés.**  
Utilise cette checklist pour piloter le renforcement des tests et garantir la robustesse du projet v101.

*Ajouté automatiquement le 2025-07-10*
---

### 📦 Script de correction automatique des noms de package Go

Pour garantir la cohérence des noms de package dans le dossier `development/managers/dependencymanager`, un script Go a été ajouté. Ce script parcourt tous les fichiers `.go` du dossier cible et corrige automatiquement le nom du package si besoin.

**Script utilisé :**

```go
// tools/scripts/fix_package_name.go
package main

import (
	"bufio"
	"bytes"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	fixPackageNameMain()
}

func fixPackageNameMain() {
	root := "development/managers/dependencymanager"
	targetPkg := "dependencymanager"
	count := 0

	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if strings.HasSuffix(path, ".go") {
			if err := processGoFile(path, targetPkg, &count); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		log.Fatalf("Erreur lors du parcours des fichiers : %v", err)
	}
	log.Printf("Correction terminée. %d fichiers modifiés.", count)
}

func processGoFile(path, targetPkg string, count *int) error {
	input, err := ioutil.ReadFile(path)
	if err != nil {
		return fmt.Errorf("lecture du fichier %s échouée : %w", path, err)
	}

	scanner := bufio.NewScanner(bytes.NewReader(input))
	var output bytes.Buffer
	changed := false
	lineNum := 0

	for scanner.Scan() {
		line := scanner.Text()
		if lineNum == 0 && strings.HasPrefix(line, "package ") && !strings.HasPrefix(line, "package "+targetPkg) {
			output.WriteString("package " + targetPkg + "\n")
			changed = true
		} else {
			output.WriteString(line + "\n")
		}
		lineNum++
	}
	if err := scanner.Err(); err != nil {
		return fmt.Errorf("erreur lors du scan du fichier %s : %w", path, err)
	}

	if changed {
		// Permissions 0644 : lecture/écriture pour le propriétaire, lecture pour les autres
		if err := ioutil.WriteFile(path, output.Bytes(), 0644); err != nil {
			return fmt.Errorf("écriture du fichier %s échouée : %w", path, err)
		}
		*count++
		log.Printf("Fichier corrigé : %s", path)
	}
	return nil
}
```

**Utilisation :**

```sh
go run tools/scripts/fix_package_name.go
```

Ce script peut être intégré dans la CI/CD pour garantir la cohérence des packages Go.  
Pense à ajouter un test unitaire pour la fonction `processGoFile` si besoin.

---