# Checklist actionnable — Migration/rangement documentaire Roo-Code

## Préparation
- [ ] Sauvegarder l’état actuel du dossier `.github/docs/vsix/roo-code` (backup rapide)
- [ ] Informer les contributeurs du chantier de rangement

## Création de la structure cible
- [ ] Créer les sous-dossiers : `guides/`, `tools/`, `actions/`, `config/`, `prompts/` si absents
- [ ] Créer ou mettre à jour `README.md` et `CHANGELOG.md` à la racine
- [ ] Créer ou mettre à jour `tools-registry.md` à la racine

## Rangement thématique des fichiers
- [ ] Lister tous les fichiers et sous-dossiers existants
- [ ] Identifier la typologie de chaque fichier (guide, outil, config, prompt…)
- [ ] Déplacer chaque fichier dans le sous-dossier approprié :
  - Guides → `guides/`
  - Fiches outils/actions → `tools/`
  - Prompts et modèles d’action → `actions/` ou `prompts/`
  - Configurations → `config/`
- [ ] Mettre à jour les liens internes et index dans `README.md`

## Documentation croisée et registre
- [ ] Ajouter un lien vers `tools-registry.md` dans chaque fiche outil/action
- [ ] Mettre à jour le registre central à chaque ajout/modification

## Validation collaborative
- [ ] Relire la structure avec les parties prenantes
- [ ] Recueillir les retours et ajuster si besoin

## Finalisation et suivi
- [ ] Exporter la structure validée dans la roadmap documentaire
- [ ] Documenter toute exception ou adaptation dans le `CHANGELOG.md`
- [ ] Synchroniser la structure avec les autres référentiels Roo (AGENTS.md, workflows-matrix.md…)

---
Checklist à cocher étape par étape pour garantir un rangement documentaire conforme aux standards Roo-Code.