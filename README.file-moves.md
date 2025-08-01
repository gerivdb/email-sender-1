# README – Configuration des déplacements multifichiers documentaire

**Version :** 1.0.0  
**Date :** 2025-08-01  
**Auteur :** Roo

---

## 📄 Format et structure

La configuration s’appuie sur deux fichiers :
- [`file-moves.schema.yaml`](file-moves.schema.yaml) : schéma YAML commenté, exhaustif, pour validation et documentation.
- [`file-moves.yaml`](file-moves.yaml) : exemple de configuration conforme, prêt à l’emploi.

Chaque opération de déplacement est décrite par :
- `id` : identifiant unique de l’opération
- `source` : chemin du fichier source
- `cible` : chemin de destination
- `type` : move, copy ou symlink
- `tags` : liste de tags libres
- `dependances` : liste d’IDs d’opérations à exécuter avant
- `priorite` : ordre d’exécution (plus bas = plus prioritaire)
- `rollback` : bloc de gestion du retour arrière (enabled, strategy)
- `dry-run` : simulation sans effet réel
- `validation` : bloc de vérification post-opération (enabled, checks)
- `hooks` : scripts ou commandes à exécuter avant/après

Voir le schéma pour la documentation détaillée de chaque champ.

---

## 🔄 Logique de composition et import

- Les déplacements sont listés dans l’ordre souhaité, mais la résolution des dépendances (`dependances`) permet d’orchestrer des workflows complexes.
- Les priorités (`priorite`) permettent d’affiner l’ordre d’exécution.
- Les hooks permettent d’intégrer des scripts personnalisés à chaque étape.
- Le mode `dry-run` permet de tester la configuration sans modifier les fichiers.

---

## ✅ Validation attendue

- La conformité au schéma [`file-moves.schema.yaml`](file-moves.schema.yaml) est obligatoire : chaque champ doit être présent et correctement typé.
- La structure est compatible avec le SmartVariableSuggestionManager pour l’analyse, la suggestion et la validation automatique des variables/documentation.
- Les validations post-opération (`validation.checks`) peuvent inclure : existence, checksum, permissions, etc.

---

## 🧩 Intégration et extension

- Ce format est conçu pour être importé par tout outil documentaire Roo ou pipeline CI/CD.
- Il peut être étendu ou adapté selon les besoins : ajoutez de nouveaux champs dans le schéma si nécessaire, en respectant la documentation inline.

---

## 📚 Références

- [file-moves.schema.yaml](file-moves.schema.yaml)
- [file-moves.yaml](file-moves.yaml)
- [AGENTS.md](AGENTS.md) : pour l’intégration avec SmartVariableSuggestionManager

## Structure cible des tests d’intégration (phase 6 Roo Code)

- `tests/integration/move-files.integration.ps1` : tests d’intégration PowerShell
- `tests/integration/move-files.integration.js` : tests d’intégration Node.js
- `tests/integration/move-files.integration.sh` : tests d’intégration Bash
- `tests/integration/move-files_integration.py` : tests d’intégration Python
- `tests/integration/README.integration.md` : documentation des scénarios d’intégration

### Scénarios à couvrir (exemples Roo Code) :
- Exécution croisée sur plusieurs plateformes (Windows, Linux, Mac)
- Vérification de la cohérence des déplacements multi-fichiers
- Gestion des erreurs croisées (fichiers verrouillés, droits insuffisants)
- Simulation de conflits et rollback
- Validation de la traçabilité documentaire (logs, reporting)
- Nettoyage automatique après test

> Cette structure est conforme au template Roo Code [`plandev-engineer`](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md) et doit être synchronisée avec la todo-list.
