# Plan de migration v77 – Gateway Manager (consolidé)

---

## PHASE 8 – Correction des erreurs Go critiques (lots 1 à 18)

- [x] 8.1 à 8.14
- [x] 8.15.1 Corriger les erreurs d’imports de dépendances et modules manquants
- [x] 8.15.2 Corriger les erreurs de types ou symboles non déclarés
- [x] 8.15.3 Corriger les erreurs de structure et de déclaration
- [x] 8.16.1 Corriger les erreurs d’imports de dépendances et modules manquants
- [x] 8.16.2 Corriger les erreurs de types ou symboles non déclarés
- [x] 8.16.3 Corriger les erreurs de structure et de déclaration
- [x] 8.17.1 Corriger les erreurs d’imports de dépendances et modules manquants
- [x] 8.17.2 Corriger les erreurs de types ou symboles non déclarés
- [x] 8.17.3 Corriger les erreurs de structure et de déclaration
- [ ] 8.18.1 Corriger les erreurs de directives et de syntaxe Go
- [ ] 8.18.2 Corriger les erreurs de syntaxe YAML (Helm, GitHub Actions, etc.)
- [ ] 8.18.3 Corriger les erreurs de linting et de style Go

---

## Rapport d’erreurs résiduelles (à date)

### Erreurs Go (go.mod, go.work, imports, typage)
- unknown directive: m (go.mod)
- cannot load module . listed in go.work file: errors parsing go.mod
- local replacement are not allowed (go.mod)
- undefined: ... (types, symboles, fonctions)
- main redeclared in this block, ... redeclared in this block
- imported and not used: ..., declared and not used: ...
- invalid import path (invalid character U+003A ':')
- missing ',' in composite literal

### Erreurs YAML (Helm, GitHub Actions, etc.)
- Unexpected scalar at node end
- Block collections are not allowed within flow collections
- Missing , or : between flow map items
- A block sequence may not be used as an implicit map key
- Implicit keys need to be on a single line
- Implicit map keys need to be followed by map values
- All mapping items must start at the same column
- Incorrect type. Expected "string | array".
- Context access might be invalid: ...

### Erreurs de linting Go/YAML/CI/CD
- use of fmt.Printf/Println forbidden by pattern
- missing whitespace above this line
- avoid inline error handling using if err := ...; err != nil

---

## Planification de la correction automatisée/manuelle des 73 erreurs restantes

1. **Lister et localiser chaque erreur dans le code source**
   - Utiliser les diagnostics IDE et les rapports d’audit pour générer un tableau de suivi.
2. **Prioriser les corrections par criticité et impact**
   - Corriger d’abord les erreurs bloquantes (go.mod, YAML Helm, CI/CD).
3. **Automatiser la correction si possible**
   - Scripts de lint, fix, validation YAML, go mod tidy, etc.
   - Exécution : `go mod tidy`, `yamllint`, `golangci-lint run`, etc.
4. **Procéder à la correction manuelle si nécessaire**
   - Pour les cas non automatisables (syntaxe complexe, refactoring).
5. **Valider chaque correction par commit atomique et CI/CD**
   - Vérifier la disparition de l’erreur dans l’IDE et les pipelines.
6. **Mettre à jour ce rapport et cocher les cases au fur et à mesure**
   - Historiser les corrections et les commits associés.

---

> **Suivi : 73 erreurs restantes à corriger (Go/YAML/CI/CD).  
> Objectif : zéro erreur signalée par l’IDE et conformité totale du projet.**
