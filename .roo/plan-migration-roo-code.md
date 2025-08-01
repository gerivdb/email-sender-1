# Plan de migration Roo Code (.roo/)

## Objectif
Centraliser tous les artefacts Roo Code (scripts, configs, tests, docs techniques) dans `.roo/` selon une structure thématique, en excluant les artefacts métiers.

---

## Étapes séquencées

1. **Inventaire initial**
   - Lister le contenu de `.roo/` et `scripts/`
   - Identifier les fichiers Roo Code à migrer (hors métiers)

2. **Classement thématique**
   - Scripts → `.roo/scripts/`
   - Configs → `.roo/config/`
   - Tests → `.roo/tests/`
   - Docs techniques Roo → `.roo/docs/`

3. **Plan de migration**
   | Fichier/Dossier source                | Nouveau chemin cible                |
   |---------------------------------------|-------------------------------------|
   | scripts/recensement.go                | .roo/scripts/recensement.go         |
   | scripts/recensement/main.go           | .roo/scripts/recensement/main.go    |
   | scripts/dev-check.go                  | .roo/scripts/dev-check.go           |
   | scripts/rollback.sh                   | .roo/scripts/rollback.sh            |
   | .roomodes                             | .roo/config/.roomodes               |
   | recensement.yaml                      | .roo/config/recensement.yaml        |
   | test-ecriture.md                      | .roo/tests/test-ecriture.md         |

   > **Exclus** : besoins.yaml, rapport-ecart.md, plan-recensement-developpement.md, etc.

4. **Migration effective**
   - Déplacer chaque fichier/dossier selon le tableau ci-dessus
   - Ajouter un en-tête de traçabilité dans chaque fichier déplacé

5. **Mise à jour des références**
   - Adapter les chemins dans la documentation et les scripts si nécessaire

6. **Traçabilité et documentation**
   - Documenter chaque déplacement dans ce fichier
   - Résumer les changements et les nouveaux chemins

---

## Historique des migrations

- [ ] scripts/recensement.go → .roo/scripts/recensement.go
- [ ] scripts/recensement/main.go → .roo/scripts/recensement/main.go
- [ ] scripts/dev-check.go → .roo/scripts/dev-check.go
- [ ] scripts/rollback.sh → .roo/scripts/rollback.sh
- [ ] .roomodes → .roo/config/.roomodes
- [ ] recensement.yaml → .roo/config/recensement.yaml
- [ ] test-ecriture.md → .roo/tests/test-ecriture.md

---

## Points de vigilance

- Ne pas déplacer les fichiers métiers
- Vérifier la cohérence documentaire après migration
- Mettre à jour la todo list à chaque étape

---

## Références

- [AGENTS.md](../AGENTS.md)
- [rules.md](.roo/rules/rules.md)
- [workflows-matrix.md](.roo/rules/workflows-matrix.md)