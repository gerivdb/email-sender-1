# 🧰 Rapport : Méthodes de Validation et Correction de Code Go

Ce rapport détaille les outils et commandes indispensables pour valider et corriger du code Go **avant compilation**. Objectif : améliorer la qualité du code, éviter les erreurs de build, et fluidifier l'intégration continue, notamment avec **GitHub Copilot** et **Visual Studio Code**.

---

# Pour garantir l'application continue de ces méthodes :
#
# 1. Ce guide est référencé dans le README du projet.
# 2. Un workflow GitHub Actions (voir .github/workflows/go-quality.yml) applique ces méthodes à chaque push/PR.
# 3. Le Makefile et la configuration VS Code sont alignés sur ces standards.
#
# Toute contribution doit respecter ce guide et passer les vérifications automatiques.

---

## 1. Analyse Statique avec `go vet`

- **Description** : Détecte les erreurs potentielles (conversion suspecte, argument inexploité, etc.).
- **Commande** :
  ```sh
  go vet ./...
````

* **Utilité** : Identifie les bugs potentiels sans compiler.
* **Intégration VS Code / Copilot** :

  ```json
  "go.vetOnSave": "package"
  ```

---

## 2. Linting avec `golangci-lint`

* **Description** : Méta-linter regroupant plusieurs outils : `go vet`, `staticcheck`, `gosec`, etc.
* **Installation** :

  ```sh
  go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
  ```
* **Commandes** :

  ```sh
  golangci-lint run
  golangci-lint run --fix  # Correction automatique
  ```
* **Utilité** : Linting complet + auto-corrections.
* **Intégration** :

  ```json
  "go.lintTool": "golangci-lint",
  "go.lintOnSave": "package"
  ```

---

## 3. Formatage avec `go fmt`

* **Description** : Formate le code Go selon les conventions officielles.
* **Commande** :

  ```sh
  go fmt ./...
  ```
* **Utilité** : Cohérence de style.
* **Copilot** :

  ```json
  "go.formatTool": "go fmt"
  ```

---

## 4. Gestion des Imports avec `goimports`

* **Description** : Gère automatiquement les imports inutiles ou manquants.
* **Installation** :

  ```sh
  go install golang.org/x/tools/cmd/goimports@latest
  ```
* **Commande** :

  ```sh
  goimports -w .
  ```
* **Copilot** :

  ```json
  "go.formatTool": "goimports"
  ```

---

## 5. Modules avec `go mod`

* **Commandes** :

  ```sh
  go mod tidy      # Nettoie
  go mod verify    # Vérifie l’intégrité
  ```
* **Utilité** : Corrige les erreurs liées aux dépendances.

---

## 6. Tests Unitaires (Dry Run)

* **Commande** :

  ```sh
  go test -run xxx ./...
  ```
* **Utilité** : Vérifie syntaxe et imports sans exécuter de tests.

---

## 7. Analyse Avancée avec `staticcheck`

* **Installation** :

  ```sh
  go install honnef.co/go/tools/cmd/staticcheck@latest
  ```
* **Commande** :

  ```sh
  staticcheck ./...
  ```
* **Utilité** : Plus précis que `go vet` sur les bugs avancés.

---

## 8. Compilation Simulée avec `go build`

* **Commandes** :

  ```sh
  go build -o /dev/null
  go build -n
  ```
* **Utilité** : Vérifie la build sans créer de binaire.

---

## 9. Sécurité avec `gosec`

* **Installation** :

  ```sh
  go install github.com/securego/gosec/v2/cmd/gosec@latest
  ```
* **Commande** :

  ```sh
  gosec ./...
  ```

---

## 10. Formatage Strict avec `gofumpt`

* **Installation** :

  ```sh
  go install mvdan.cc/gofumpt@latest
  ```
* **Commande** :

  ```sh
  gofumpt -w .
  ```

---

## 11. Automatisation avec Makefile

```Makefile
.PHONY: check
check:
    go fmt ./...
    goimports -w .
    go mod tidy
    go vet ./...
    golangci-lint run
    go build -o /dev/null
```

---

## ⚙️ Configuration VS Code pour GitHub Copilot

```json
{
  "go.formatTool": "goimports",
  "go.lintTool": "golangci-lint",
  "go.lintOnSave": "package",
  "go.vetOnSave": "package",
  "go.useLanguageServer": true,
  "[go]": {
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.organizeImports": true
    }
  }
}
```

---

## 🧠 Notes pour GitHub Copilot

* Accepte les suggestions pour corriger les erreurs `golangci-lint` / `staticcheck`.
* Utilise des tâches VS Code pour automatiser les vérifications.
* Intègre ces outils dans GitHub Actions pour CI/CD robuste.
