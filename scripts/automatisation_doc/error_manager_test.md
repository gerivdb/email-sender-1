# Tests unitaires Roo — ErrorManager

## Objectif

Garantir la robustesse, la conformité Roo et la traçabilité de l’ErrorManager : validation des entrées, gestion centralisée, hooks/plugins, journalisation structurée, conformité YAML, couverture des cas limites et d’échec.

---

## Structure des tests

- **Fichier cible** : [`error_manager.go`](scripts/automatisation_doc/error_manager.go)
- **Schéma de validation** : [`error_manager_schema.yaml`](scripts/automatisation_doc/error_manager_schema.yaml)
- **Spécification technique** : [`error_manager_spec.md`](scripts/automatisation_doc/error_manager_spec.md)

---

## Checklist Roo des cas à couvrir

- [ ] Validation des entrées (`ProcessError`, `CatalogError`, `ValidateErrorEntry`)
- [ ] Gestion centralisée des erreurs Go et structurées
- [ ] Journalisation structurée et traçabilité Roo
- [ ] Déclenchement des hooks/plugins (mocks)
- [ ] Gestion des cas limites (erreur inconnue, format invalide, plugin défaillant)
- [ ] Conformité YAML Roo (validation croisée avec le schéma)
- [ ] Couverture des scénarios d’échec et rollback
- [ ] Tests de performance (latence, volumétrie)
- [ ] Couverture des logs d’audit et reporting
- [ ] Intégration CI/CD (badge, pipeline)
- [ ] Documentation croisée et liens Roo

---

## Exemples de scénarios de test

### 1. Validation d’une erreur structurée conforme

- **Entrée** : `ErrorEntry` valide (conforme au schéma YAML)
- **Attendu** : Acceptation, journalisation, traçabilité Roo, aucun rejet

### 2. Rejet d’une erreur non conforme au schéma

- **Entrée** : `ErrorEntry` avec champ manquant ou type invalide
- **Attendu** : Rejet, log d’erreur, retour explicite

### 3. Déclenchement d’un plugin de hook sur erreur critique

- **Entrée** : Erreur critique, plugin mocké
- **Attendu** : Hook appelé, log du déclenchement, traçabilité

### 4. Gestion d’un rollback sur erreur de traitement

- **Entrée** : Erreur lors de la journalisation
- **Attendu** : Rollback, log d’audit, état restauré

### 5. Test de volumétrie et performance

- **Entrée** : 10 000 erreurs structurées en rafale
- **Attendu** : Pas de fuite mémoire, latence maîtrisée, logs complets

---

## Commandes d’exécution recommandées

```bash
# Lancer les tests unitaires Go (mock inclus)
go test -v -cover ./scripts/automatisation_doc/error_manager_test.go

# Valider la conformité YAML Roo
go run ./tools/scripts/spec_test_cases/spec_test_cases.go --schema=scripts/automatisation_doc/error_manager_schema.yaml --target=scripts/automatisation_doc/error_manager_test.go

# Vérifier la couverture et la traçabilité
go tool cover -html=coverage.out
```

---

## Critères de validation Roo

- 100 % de couverture sur les fonctions critiques
- Tous les cas limites et d’échec couverts
- Conformité stricte au schéma YAML Roo
- Logs d’audit et reporting générés
- Intégration CI/CD validée
- Documentation croisée à jour

---

## Rollback/versionning

- Sauvegarde automatique des logs de test (`error_manager_test.log.bak`)
- Commit Git avant modification majeure
- Procédures de restauration documentées dans [`error_manager_rollback.md`](scripts/automatisation_doc/error_manager_rollback.md)

---

## Questions ouvertes & axes d’amélioration

- Faut-il ajouter des tests de fuzzing ou d’injection d’erreurs LLM ?
- Les plugins de hook doivent-ils être testés en isolation ou en intégration ?
- Quels seuils de performance sont acceptables pour la volumétrie ?

---

## Auto-critique & raffinement

- Limite : Les tests de plugins dépendent de la qualité des mocks.
- Suggestion : Ajouter des cas d’intégration avec d’autres managers Roo.
- Feedback : Intégrer un rapport automatisé dans la CI/CD pour chaque exécution de test.

---

*Référence Roo-Code : [plandev-engineer-reference.md](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md), [AGENTS.md](AGENTS.md), [README.md](README.md)*